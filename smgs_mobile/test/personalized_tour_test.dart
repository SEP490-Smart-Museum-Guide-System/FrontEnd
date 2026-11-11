import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/models/museum.dart';
import 'package:smgs_mobile/services/app_services.dart';
import 'package:smgs_mobile/services/visitor_experience_api.dart';
import 'package:smgs_mobile/screens/tours/personalized_tour_screen.dart';
import 'support/fake_services.dart';
import 'widget_test.dart' show host, screenSize, tapText;

class TestTourCatalog extends MockCatalogService {
  @override
  List<Museum> get museums => [super.museums.first.copyWith(id: '7')];
}

http.Response response(dynamic value, {int status = 200}) => http.Response(
  jsonEncode(
    status == 200 ? {'data': value} : {'message': 'Dịch vụ tạm ngừng'},
  ),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  setUp(() {
    AppServices.catalog = TestTourCatalog();
    VisitorSession.clear();
  });

  testWidgets(
    'Personalization is opt-in; preview does not save or start a visit',
    (tester) async {
      final writes = <String>[];
      await http.runWithClient(
        () async {
          await screenSize(tester, const Size(390, 844));
          await tester.pumpWidget(host(const PersonalizedTourBuilder()));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Cá nhân hóa là lựa chọn thêm.'),
            findsOneWidget,
          );
          expect(find.text('Xem tour có sẵn'), findsOneWidget);
          expect(find.text('Tham quan tự do'), findsOneWidget);
          expect(writes, isEmpty);
          await tapText(tester, 'Gợi ý theo sở thích');
          expect(writes, isEmpty);
          await tapText(tester, 'Gốm sứ');
          await tapText(tester, 'Gợi ý theo sở thích');
          expect(find.byType(PersonalizedTourDetailScreen), findsOneWidget);
          expect(writes, ['/api/personalized-tours/recommendations']);
          await tapText(tester, 'Lưu để đi sau');
          expect(writes, [
            '/api/personalized-tours/recommendations',
            '/api/personalized-tours',
          ]);
          expect(find.text('Đã lưu vào hành trình của bạn'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          final path = request.url.path;
          if (request.method == 'POST') writes.add(path);
          if (path.endsWith('/interests') || path.endsWith('/me')) {
            return response([]);
          }
          if (path.endsWith('/recommendations')) {
            final body = jsonDecode(request.body);
            expect(body['museumId'], 7);
            expect(body['interests'], ['Gốm sứ']);
          } else if (path == '/api/personalized-tours') {
            expect(jsonDecode(request.body), {
              'recommendationId': 'preview-id',
            });
          } else {
            throw StateError('Unexpected request $path');
          }
          return response({
            'id': 'preview-id',
            'museumId': 7,
            'museumName': 'Bảo tàng kiểm thử',
            'interests': ['Gốm sứ'],
            'availableMinutes': 60,
            'estimatedMinutes': 6,
            'isSaved': path == '/api/personalized-tours',
            'notice': 'Thời gian ước tính.',
            'stops': [
              {
                'artifactId': 42,
                'orderNo': 1,
                'name': 'Bình gốm',
                'galleryName': 'Phòng Gốm',
                'visitMinutes': 4,
                'walkMinutes': 2,
                'reason': 'Phù hợp sở thích: Gốm sứ.',
              },
            ],
          });
        }),
      );
    },
  );

  testWidgets(
    'Failure of saved-list API is handled before scrolling into view',
    (tester) async {
      await http.runWithClient(() async {
        await screenSize(tester, const Size(320, 680));
        await tester.pumpWidget(
          host(const PersonalizedTourBuilder(), scale: 1.2),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tapText(tester, 'Thử lại');
        expect(find.text('Chưa tải được hành trình đã lưu.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => MockClient((request) async => response(null, status: 503)));
    },
  );

  test(
    'Personal itinerary starts with its saved ID and no public tour ID',
    () async {
      await http.runWithClient(
        () async {
          await VisitorExperienceApi.startVisit(
            7,
            personalizedTourId: 'saved-id',
          );
          expect(VisitorSession.activeVisit?['id'], 23);
        },
        () => MockClient((request) async {
          expect(jsonDecode(request.body), {
            'museumId': 7,
            'tourId': null,
            'personalizedTourId': 'saved-id',
          });
          return response({'id': 23, 'personalizedTourId': 'saved-id'});
        }),
      );
    },
  );
}
