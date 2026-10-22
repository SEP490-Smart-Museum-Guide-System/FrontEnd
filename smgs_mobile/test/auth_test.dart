import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smgs_mobile/models/auth_session.dart';
import 'package:smgs_mobile/services/backend_auth_service.dart';
import 'package:smgs_mobile/services/token_manager.dart';
import 'package:smgs_mobile/services/app_services.dart';
import 'package:smgs_mobile/screens/auth/auth_screen.dart';
import 'widget_test.dart' show host, screenSize, tapText;

Map<String, dynamic> authData({
  String role = 'Visitor',
  Duration expiresIn = const Duration(hours: 1),
}) => {
  'accessToken': 'fixture-token',
  'accessTokenExpiration': DateTime.now()
      .toUtc()
      .add(expiresIn)
      .toIso8601String(),
  'email': 'visitor@example.invalid',
  'fullName': 'Ngọc An',
  'roles': [role],
};
http.Response authResponse(Map<String, dynamic> data, [int status = 200]) =>
    http.Response(
      jsonEncode({'statusCode': status, 'data': data}),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TokenManager.init();
  });

  test(
    'register and login send matching contracts, retain spaces and persist complete sessions',
    () async {
      final service = BackendAuthService();
      addTearDown(service.dispose);
      await http.runWithClient(
        () async {
          await service.register(
            ' Ngọc An ',
            ' visitor@example.invalid ',
            ' TestPass1 ',
          );
          expect(service.user?.name, 'Ngọc An');
          expect(TokenManager.hasToken, isTrue);
          expect(
            TokenManager.authHeaders['Authorization'],
            'Bearer fixture-token',
          );
          await TokenManager.init();
          final restored = BackendAuthService();
          addTearDown(restored.dispose);
          expect(restored.user?.email, 'visitor@example.invalid');
          await restored.logout();
          expect(TokenManager.hasToken, isFalse);
          await service.login(' visitor@example.invalid ', ' TestPass1 ');
          expect(service.user, isNotNull);
          await service.logout();
          await TokenManager.init();
          expect(TokenManager.session, isNull);
        },
        () => MockClient((request) async {
          final body = jsonDecode(request.body) as Map;
          expect(body['email'], 'visitor@example.invalid');
          expect(body['password'], ' TestPass1 ');
          expect(request.headers['content-type'], contains('application/json'));
          if (request.url.path.endsWith('register')) {
            expect(body['fullName'], 'Ngọc An');
            expect(body.containsKey('roles'), isFalse);
            return authResponse(authData(), 201);
          }
          expect(request.url.path.endsWith('/auth/login'), isTrue);
          return authResponse(authData());
        }),
      );
    },
  );

  test(
    'duplicate/wrong-password/network/HTML/missing-token responses never log the user in',
    () async {
      for (final response in [
        http.Response(jsonEncode({'message': 'Email already exists.'}), 400),
        http.Response(jsonEncode({'message': 'Invalid credentials.'}), 401),
        http.Response('', 429),
        http.Response('<html>error</html>', 500),
        http.Response('{}', 200),
        authResponse({...authData(), 'accessToken': ''}, 201),
        authResponse(authData(role: 'Admin')),
        authResponse(authData(expiresIn: const Duration(seconds: -1))),
      ]) {
        final service = BackendAuthService();
        await http.runWithClient(() async {
          await expectLater(
            service.register('Ngọc An', 'visitor@example.invalid', 'TestPass1'),
            throwsException,
          );
          expect(service.user, isNull);
          expect(TokenManager.hasToken, isFalse);
        }, () => MockClient((_) async => response));
        service.dispose();
      }
      final service = BackendAuthService();
      addTearDown(service.dispose);
      await http.runWithClient(() async {
        await expectLater(
          service.login('visitor@example.invalid', 'TestPass1'),
          throwsException,
        );
        expect(service.user, isNull);
      }, () => MockClient((_) async => throw http.ClientException('Offline')));
      await expectLater(
        service.recover('visitor@example.invalid'),
        throwsException,
      );
    },
  );

  test(
    'expired, corrupt and legacy storage cannot restore a session',
    () async {
      for (final stored in [
        'broken json',
        '{}',
        jsonEncode(authData(expiresIn: const Duration(days: -1))),
      ]) {
        SharedPreferences.setMockInitialValues({'smgs_auth_session': stored});
        await TokenManager.init();
        expect(TokenManager.hasToken, isFalse);
      }
      SharedPreferences.setMockInitialValues({'smgs_auth_session': 123});
      await TokenManager.init();
      expect(TokenManager.hasToken, isFalse);
      SharedPreferences.setMockInitialValues({
        'smgs_jwt_token': 'old-mock-token',
        'smgs_user_full_name': 'Admin',
      });
      await TokenManager.init();
      expect(TokenManager.hasToken, isFalse);
      expect(
        () => AuthSession.fromJson({
          ...authData(),
          'roles': ['Unknown'],
        }),
        throwsFormatException,
      );
    },
  );

  testWidgets('session expiry returns to logged out state', (tester) async {
    final session = AuthSession.fromJson(
      authData(expiresIn: const Duration(seconds: 1)),
    );
    await TokenManager.saveSession(session);
    final service = BackendAuthService();
    addTearDown(service.dispose);
    expect(service.user, isNotNull);
    await tester.pump(const Duration(seconds: 2));
    expect(service.user, isNull);
    expect(TokenManager.hasToken, isFalse);
  });

  testWidgets(
    'register form uses backend service, validates confirmation and displays duplicate error',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      final service = BackendAuthService();
      final previous = AppServices.auth;
      AppServices.auth = service;
      addTearDown(() {
        AppServices.auth = previous;
        service.dispose();
      });
      var requests = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(host(const AuthScreen()));
          await tester.pumpAndSettle();
          await tapText(tester, 'Tạo tài khoản mới');
          Finder field(String label) => find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.labelText == label,
          );
          await tester.enterText(field('Tên của bạn'), 'Ngọc An');
          await tester.enterText(field('Email'), 'visitor@example.invalid');
          await tester.enterText(field('Mật khẩu'), 'TestPass1');
          await tester.enterText(field('Nhập lại mật khẩu'), 'wrong');
          await tapText(tester, 'Đăng ký tài khoản');
          expect(find.text('Hai mật khẩu chưa khớp.'), findsOneWidget);
          expect(requests, 0);
          await tester.enterText(field('Nhập lại mật khẩu'), 'TestPass1');
          await tapText(tester, 'Đăng ký tài khoản');
          expect(requests, 1);
          expect(find.text('Email đã được sử dụng.'), findsOneWidget);
          await tapText(tester, 'Đăng ký tài khoản');
          expect(
            find.text(
              'Phiên đăng nhập từ máy chủ không hợp lệ hoặc đã hết hạn.',
            ),
            findsOneWidget,
          );
          expect(service.user, isNull);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((_) async {
          requests++;
          if (requests > 1) {
            return authResponse({...authData(), 'accessToken': ''}, 201);
          }
          return http.Response(
            jsonEncode({'message': 'Email đã được sử dụng.'}),
            400,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
    },
  );
}
