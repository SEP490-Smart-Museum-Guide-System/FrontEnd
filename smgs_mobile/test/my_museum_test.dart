import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smgs_mobile/models/auth_session.dart';
import 'package:smgs_mobile/services/token_manager.dart';
import 'package:smgs_mobile/screens/profile/my_museum_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TokenManager.saveSession(
      AuthSession.fromJson({
        'accessToken': 'collection-token',
        'email': 'visitor@test.invalid',
        'fullName': 'Visitor',
        'roles': ['Visitor'],
        'accessTokenExpiration': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      }),
    );
  });
  tearDown(TokenManager.clearSession);

  testWidgets('empty collection and signed-out state', (tester) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: MyMuseumScreen()));
        await tester.pumpAndSettle();
        expect(
          find.text('Chưa có hiện vật nào trong bộ sưu tập'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
      () => MockClient(
        (request) async => http.Response(
          jsonEncode({
            'data': {
              'items': [],
              'totalCollected': 0,
              'totalCount': 0,
              'totalPages': 0,
              'museums': [],
            },
          }),
          200,
        ),
      ),
    );
    await TokenManager.clearSession();
    await tester.pumpWidget(
      const MaterialApp(home: MyMuseumScreen(key: ValueKey('guest'))),
    );
    expect(find.text('Vui lòng đăng nhập để xem bộ sưu tập.'), findsOneWidget);
  });

  testWidgets(
    'shelves paginate, filter and preserve unavailable discoveries on narrow screens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final requests = <Uri>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(const MaterialApp(home: MyMuseumScreen()));
          await tester.pumpAndSettle();
          expect(find.text('Kệ 1 / 2'), findsOneWidget);
          expect(find.text('Hiện vật hiện không khả dụng'), findsOneWidget);
          await tester.drag(find.byType(PageView), const Offset(-300, 0));
          await tester.pumpAndSettle();
          expect(find.text('Kệ 2 / 2'), findsOneWidget);
          expect(
            tester
                .widget<IconButton>(
                  find.widgetWithIcon(IconButton, Icons.chevron_right),
                )
                .onPressed,
            isNull,
          );
          await tester.tap(find.byTooltip('Kệ trước'));
          await tester.pumpAndSettle();
          expect(find.text('Kệ 1 / 2'), findsOneWidget);
          expect(
            tester
                .widget<IconButton>(
                  find.widgetWithIcon(IconButton, Icons.chevron_left),
                )
                .onPressed,
            isNull,
          );
          expect(requests.any((u) => u.queryParameters['page'] == '2'), isTrue);
          await tester.tap(find.byType(DropdownButtonFormField<int>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Bảo tàng A').last);
          await tester.pumpAndSettle();
          expect(find.text('Kệ 1 / 1'), findsOneWidget);
          expect(requests.last.queryParameters['museumId'], '7');
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          requests.add(request.url);
          expect(request.headers['Authorization'], 'Bearer collection-token');
          return http.Response(
            jsonEncode({
              'data': {
                'items': [
                  {
                    'artifactId': 1,
                    'name':
                        'Hiện vật tên dài để kiểm tra bố cục trên điện thoại',
                    'museumId': 7,
                    'museumName': 'Bảo tàng A',
                    'available': false,
                    'imageUrl': null,
                  },
                ],
                'totalCollected': 5,
                'totalCount': 5,
                'totalPages':
                    request.url.queryParameters.containsKey('museumId') ? 1 : 2,
                'museums': [
                  {'id': 7, 'name': 'Bảo tàng A'},
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
    },
  );
}
