import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/services/backend_api.dart';
import 'package:smgs_mobile/services/visitor_experience_api.dart';
import 'package:smgs_mobile/screens/museum/visit_progress_screen.dart';
import 'package:smgs_mobile/screens/profile/order_detail_screen.dart';
import 'package:smgs_mobile/screens/profile/profile_screen.dart';
import 'package:smgs_mobile/screens/artifact/artifact_qr_scanner.dart';
import 'package:smgs_mobile/widgets/primary_button.dart';
import 'widget_test.dart' show host, screenSize, tapText;

http.Response reply(dynamic data, {int status = 200}) => http.Response(
  jsonEncode(
    status == 200 ? {'data': data} : {'message': 'Yêu cầu bị từ chối'},
  ),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
void main() {
  setUp(VisitorSession.clear);
  test(
    'QR retries preserve a UUID and visit scope; a different scan gets a new UUID',
    () async {
      final requests = <Map<String, dynamic>>[];
      final scan = ScanRequest(
        'https://museum.example/api/artifacts/scan/REAL-QR',
        visitId: 23,
      );
      expect(
        scan.requestId,
        matches(
          RegExp(
            r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
          ),
        ),
      );
      await http.runWithClient(
        () async {
          await expectLater(scan.record(), throwsException);
          final result = await scan.record();
          expect(result['recognitionId'], 82);
        },
        () => MockClient((request) async {
          expect(request.url.path, '/api/recognitions/qr');
          expect(request.method, 'POST');
          requests.add(Map<String, dynamic>.from(jsonDecode(request.body)));
          return reply({
            'recognitionId': 82,
            'artifactId': 11,
            'visitId': 23,
          }, status: requests.length == 1 ? 500 : 200);
        }),
      );
      expect(requests[0], requests[1]);
      expect(requests[1], {
        'qrCode': 'REAL-QR',
        'visitId': 23,
        'requestId': scan.requestId,
      });
      expect(
        ScanRequest('OTHER-QR', visitId: 24).requestId,
        isNot(scan.requestId),
      );
    },
  );
  test('Published tour starts a server visit with the real tour ID', () async {
    await http.runWithClient(
      () async {
        final visit = await VisitorExperienceApi.startVisit(7, tourId: 19);
        expect(visit['id'], 23);
        expect(VisitorSession.activeVisit?['tourId'], 19);
      },
      () => MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/visits');
        expect(jsonDecode(request.body), {'museumId': 7, 'tourId': 19});
        return reply({
          'id': 23,
          'museumId': 7,
          'tourId': 19,
          'status': 'InProgress',
        });
      }),
    );
  });
  test(
    'Array endpoints read subsequent pages without duplicating an unpaged list',
    () async {
      var requests = 0;
      await http.runWithClient(
        () async {
          expect(await BackendApi.list('quiz-attempts/me'), hasLength(51));
          expect(requests, 2);
        },
        () => MockClient((request) async {
          requests++;
          return reply(
            request.url.queryParameters['page'] == '1'
                ? List.generate(50, (id) => {'id': id})
                : [
                    {'id': 50},
                  ],
          );
        }),
      );
    },
  );
  test('Navigation sends visit, map, target and accessibility to BE', () async {
    await http.runWithClient(
      () async {
        final route = await VisitorExperienceApi.route(
          23,
          9,
          artifactId: 11,
          accessible: true,
        );
        expect(route['route']['nodeIds'], ['a', 'b']);
      },
      () => MockClient((request) async {
        expect(request.url.path, '/api/visitor-navigation/route');
        expect(request.url.queryParameters, {
          'visitId': '23',
          'mapId': '9',
          'artifactId': '11',
          'accessibleOnly': 'true',
        });
        return reply({
          'mapId': 9,
          'revision': 4,
          'route': {
            'nodeIds': ['a', 'b'],
            'cost': 20,
          },
        });
      }),
    );
  });
  testWidgets(
    'Rejected group redemption keeps the form and never claims success',
    (tester) async {
      await http.runWithClient(
        () async {
          await screenSize(tester, const Size(390, 844));
          await tester.pumpWidget(host(const RedeemPassScreen()));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField),
            List.filled(64, 'a').join(),
          );
          await tapText(tester, 'Nhận quyền truy cập');
          expect(find.byType(RedeemPassScreen), findsOneWidget);
          expect(find.textContaining('Yêu cầu bị từ chối'), findsOneWidget);
          expect(find.byType(TextFormField), findsOneWidget);
        },
        () => MockClient((request) async {
          expect(request.url.path, '/api/commerce/passes/redeem');
          expect(request.method, 'POST');
          return reply(null, status: 409);
        }),
      );
    },
  );
  testWidgets(
    'Editing existing feedback uses PUT and preserves the server visit link',
    (tester) async {
      await http.runWithClient(
        () async {
          await screenSize(tester, const Size(390, 844));
          await tester.pumpWidget(
            host(
              const FeedbackScreen(
                targetType: 'visit',
                targetId: '23',
                targetName: 'Bảo tàng',
                existingFeedback: {
                  'id': 8,
                  'overallRating': 4,
                  'comment': 'Góp ý cũ',
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Góp ý cũ'), findsOneWidget);
          await tapText(tester, 'Ghi nhận góp ý');
          expect(find.text('Cảm ơn bạn!'), findsOneWidget);
        },
        () => MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/feedbacks/8');
          expect(jsonDecode(request.body)['overallRating'], 4);
          return reply({'id': 8, 'visitId': 23});
        }),
      );
    },
  );
  testWidgets('New API screens fit a 320px viewport with enlarged text', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await screenSize(tester, const Size(320, 640));
        for (final screen in <Widget>[
          const RedeemPassScreen(),
          const VisitProgressScreen(visitId: 23),
          const OrderDetailScreen(orderId: 'order-real'),
          const ResourceAccessScreen(museumId: '7', resourceIds: [6]),
          const ArtifactQrScanner(visitId: 23),
        ]) {
          await tester.pumpWidget(host(screen, scale: 1.3));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} initial',
          );
          for (var i = 0; i < 8; i++) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -250),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${screen.runtimeType} step $i',
            );
          }
        }
      },
      () => MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/visits/23') {
          return reply({
            'id': 23,
            'museumId': 7,
            'status': 'InProgress',
            'startedAt': '2026-11-04T00:00:00Z',
          });
        }
        if (path.endsWith('/progress')) {
          return reply({
            'stops': [
              {'artifactId': 11, 'orderNo': 1, 'lastVisitedAt': null},
            ],
          });
        }
        if (path.endsWith('/orders/me')) {
          return reply([
            {
              'id': 'order-real',
              'productName': 'Gói dịch vụ từ BE',
              'amount': 12000,
              'currency': 'VND',
              'seats': 2,
              'status': 'paid',
            },
          ]);
        }
        if (path.endsWith('/invoice')) {
          return reply({
            'number': 'SMGS-REAL',
            'buyerName': 'Khách thật',
            'productName': 'Gói dịch vụ',
            'amount': 12000,
            'currency': 'VND',
            'issuedAt': '2026-11-04T00:00:00Z',
          });
        }
        if (path.endsWith('/resources')) {
          return reply([
            {'id': 6, 'name': 'Nội dung thuyết minh', 'accessLevel': 'premium'},
          ]);
        }
        if (path.endsWith('/access')) {
          return reply({'allowed': false, 'accessLevel': 'premium'});
        }
        if (path == '/api/visits/me') {
          return reply({
            'items': [
              {'id': 23, 'museumId': 7},
            ],
            'totalPages': 1,
            'totalCount': 1,
          });
        }
        return reply([]);
      }),
    );
  });
  testWidgets(
    'Scanner UI records the chosen live visit before showing scan success',
    (tester) async {
      Map<String, dynamic>? recorded;
      await http.runWithClient(
        () async {
          await screenSize(tester, const Size(390, 844));
          await tester.pumpWidget(host(const ArtifactQrScanner(visitId: 23)));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byWidgetPredicate(
              (w) =>
                  w is TextField &&
                  w.decoration?.labelText == 'Mã QR hoặc URL trên mã QR',
            ),
            'REAL-QR',
          );
          await tapText(tester, 'Xem thông tin hiện vật');
          expect(recorded?['visitId'], 23);
          expect(recorded?['qrCode'], 'REAL-QR');
          expect(find.textContaining('Đã ghi nhận lượt quét.'), findsOneWidget);
        },
        () => MockClient((request) async {
          if (request.url.path == '/api/visits/me') {
            return reply({
              'items': [
                {'id': 23, 'museumId': 7},
              ],
              'totalPages': 1,
              'totalCount': 1,
            });
          }
          if (request.url.path == '/api/recognitions/qr') {
            recorded = Map<String, dynamic>.from(jsonDecode(request.body));
            return reply({
              'recognitionId': 82,
              'artifactId': 11,
              'visitId': 23,
            });
          }
          if (request.url.path == '/api/artifacts/scan/REAL-QR') {
            return reply({
              'id': 11,
              'museumId': 7,
              'museumName': 'Bảo tàng BE',
              'name': 'Hiện vật BE',
              'contents': [],
            });
          }
          return reply(null, status: 404);
        }),
      );
    },
  );
  testWidgets('Expired feedback is shown read-only and sends no update', (
    tester,
  ) async {
    var writes = 0;
    await http.runWithClient(
      () async {
        await screenSize(tester, const Size(390, 844));
        await tester.pumpWidget(
          host(
            const FeedbackScreen(
              targetType: 'visit',
              targetId: '23',
              existingFeedback: {
                'id': 8,
                'overallRating': 4,
                'comment': 'Đã hết hạn sửa',
                'canEdit': false,
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Ghi nhận góp ý'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
        expect(button.onPressed, isNull);
        expect(writes, 0);
        expect(
          find.text('Đánh giá này đã hết thời hạn chỉnh sửa.'),
          findsOneWidget,
        );
      },
      () => MockClient((request) async {
        if (request.method != 'GET') writes++;
        return reply({});
      }),
    );
  });
}
