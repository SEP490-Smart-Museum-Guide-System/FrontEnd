import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smgs_mobile/services/backend_auth_service.dart';
import 'package:smgs_mobile/services/token_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'real Flutter service registers, rejects duplicates/wrong password and logs in through HTTP API',
    () async {
      SharedPreferences.setMockInitialValues({});
      await TokenManager.init();
      final service = BackendAuthService();
      addTearDown(service.dispose);
      final email =
          'flutter-auth-${DateTime.now().microsecondsSinceEpoch}@auth-test.invalid';
      await HttpOverrides.runWithHttpOverrides(() async {
        await service.register('Khách thử nghiệm', email, ' TestPass1 ');
        expect(service.user?.email, email);
        expect(TokenManager.hasToken, isTrue);
        await service.logout();
        await expectLater(
          service.register('Khách thử nghiệm', email, ' TestPass1 '),
          throwsException,
        );
        expect(service.user, isNull);
        await expectLater(service.login(email, 'wrong-pass'), throwsException);
        expect(TokenManager.hasToken, isFalse);
        await service.login(email, ' TestPass1 ');
        expect(service.user?.name, 'Khách thử nghiệm');
        await TokenManager.init();
        expect(TokenManager.hasToken, isTrue);
        await service.logout();
      }, LiveNetwork());
    },
    skip: !const bool.fromEnvironment('RUN_LIVE_AUTH'),
  );
}

class LiveNetwork extends HttpOverrides {}
