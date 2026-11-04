import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/models/artifact.dart';
import 'package:smgs_mobile/models/experience.dart';
import 'package:smgs_mobile/services/app_services.dart';
import 'package:smgs_mobile/services/backend_api.dart';
import 'package:smgs_mobile/screens/profile/services_screen.dart';
import 'package:smgs_mobile/screens/profile/profile_screen.dart';
import 'package:smgs_mobile/screens/artifact/artifact_detail_screen.dart';
import 'support/fake_services.dart';
import 'widget_test.dart' show host, screenSize, tapText;

http.Response reply(dynamic data, {int status = 200}) => http.Response(
  jsonEncode(
    status == 200 ? {'data': data} : {'message': 'Máy chủ từ chối yêu cầu'},
  ),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'Catalog uses DB rows and clears stale rows on empty DB or failure',
    () async {
      final catalog = BackendCatalogService();
      var empty = false, failure = false;
      await http.runWithClient(
        () async {
          await catalog.load();
          expect(catalog.museums.single.id, '73');
          expect(catalog.artifacts.single.id, '91');
          expect(catalog.artifacts.single.imageUrl, isEmpty);
          empty = true;
          await catalog.load();
          expect(catalog.museums, isEmpty);
          expect(catalog.artifacts, isEmpty);
          empty = false;
          failure = true;
          await expectLater(catalog.load(), throwsException);
          expect(catalog.museums, isEmpty);
          expect(catalog.artifacts, isEmpty);
        },
        () => MockClient((request) async {
          if (failure) return reply(null, status: 503);
          return reply(
            empty
                ? []
                : request.url.path.endsWith('/museums')
                ? [
                    {'id': 73, 'name': 'Bảo tàng DB', 'isActive': true},
                  ]
                : [
                    {'id': 91, 'museumId': 73, 'name': 'Hiện vật DB'},
                  ],
          );
        }),
      );
    },
  );

  test('Array endpoints with 50 rows are not requested again', () async {
    var requests = 0;
    await http.runWithClient(
      () async {
        expect(
          await BackendApi.list('commerce/museums/7/products'),
          hasLength(50),
        );
        expect(requests, 1);
      },
      () => MockClient((_) async {
        requests++;
        return reply(List.generate(50, (id) => {'id': id}));
      }),
    );
  });

  testWidgets(
    'Failed payment request retries the same order without activating access',
    (tester) async {
      AppServices.auth = MockAuthService(
        initialUser: const VisitorUser(
          name: 'Khách kiểm thử',
          email: 'visitor@example.invalid',
        ),
      );
      AppServices.catalog = MockCatalogService();
      var orders = 0, payments = 0;
      await http.runWithClient(
        () async {
          await screenSize(tester, const Size(390, 844));
          await tester.pumpWidget(
            host(
              const ServiceCheckoutScreen(
                museumId: '73',
                offer: PremiumOffer(
                  id: '12',
                  name: 'Gói từ DB',
                  description: '',
                  price: 100,
                  kind: DigitalServiceKind.guide,
                ),
              ),
            ),
          );
          await tapText(tester, 'Tạo đơn và yêu cầu thanh toán');
          expect(find.textContaining('Máy chủ từ chối'), findsOneWidget);
          await tapText(tester, 'Thử lại yêu cầu thanh toán');
          expect(orders, 1);
          expect(payments, 2);
          expect(
            find.textContaining('ứng dụng chưa kích hoạt dịch vụ'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          expect(request.method, 'POST');
          if (request.url.path.endsWith('/orders')) {
            orders++;
            expect(jsonDecode(request.body)['productId'], 12);
            return reply({
              'id': 'order-server',
              'amount': 100,
              'currency': 'VND',
              'status': 'pending',
            });
          }
          expect(
            request.url.path,
            '/api/commerce/orders/order-server/payments',
          );
          payments++;
          return payments == 1
              ? reply(null, status: 500)
              : reply({'status': 'pending'});
        }),
      );
    },
  );

  testWidgets(
    'Feedback succeeds only after server confirms the real visit ID',
    (tester) async {
      var fail = true;
      final bodies = <Map<String, dynamic>>[];
      await http.runWithClient(
        () async {
          await screenSize(tester, const Size(390, 844));
          await tester.pumpWidget(
            host(
              const FeedbackScreen(
                targetType: 'visit',
                targetId: '91',
                targetName: 'Chuyến tham quan',
              ),
            ),
          );
          await tapText(tester, 'Hài lòng');
          await tapText(tester, 'Ghi nhận góp ý');
          expect(find.text('Cảm ơn bạn!'), findsNothing);
          expect(find.textContaining('Máy chủ từ chối'), findsOneWidget);
          fail = false;
          await tester.pump(const Duration(seconds: 5));
          await tapText(tester, 'Ghi nhận góp ý');
          expect(find.text('Cảm ơn bạn!'), findsOneWidget);
          expect(
            bodies.every(
              (body) => body['visitId'] == 91 && body['overallRating'] == 4,
            ),
            isTrue,
          );
        },
        () => MockClient((request) async {
          expect(request.url.path, '/api/feedbacks');
          bodies.add(jsonDecode(request.body));
          return reply({'id': 5}, status: fail ? 500 : 200);
        }),
      );
    },
  );

  testWidgets('DB artifact ID 1 never inherits the sample drum 3D model', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await screenSize(tester, const Size(390, 844));
        await tester.pumpWidget(
          host(
            ArtifactDetailScreen(
              artifact: Artifact.fromBackendJson({
                'id': 1,
                'museumId': 73,
                'name': 'Hiện vật riêng',
              }),
              museumName: 'Bảo tàng DB',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Xem mô hình 3D'), findsNothing);
        expect(find.textContaining('Trống đồng Ngọc Lũ'), findsNothing);
      },
      () => MockClient(
        (_) async =>
            reply({'title': 'Nội dung thật', 'description': 'Tư liệu từ DB'}),
      ),
    );
  });
}
