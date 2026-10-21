import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'services/app_services.dart';
import 'services/app_preferences.dart';
import 'services/token_manager.dart';
import 'services/backend_auth_service.dart';
import 'widgets/heritage_decoration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo lưu trữ phiên Token JWT
  await TokenManager.init();

  // Khởi tạo dịch vụ Authentication kết nối trực tiếp Backend
  AppServices.auth = BackendAuthService();

  // Keep web controls available to assistive technology for the app lifetime.
  SemanticsBinding.instance.ensureSemantics();
  runApp(const SMGSApp());
}

class SMGSApp extends StatelessWidget {
  const SMGSApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SMGS • Cẩm nang bảo tàng',
    debugShowCheckedModeBanner: false,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.lightTheme,
    builder: (context, child) => ListenableBuilder(
      listenable: Listenable.merge([AppPreferences.instance, AppServices.auth]),
      builder: (context, _) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                MediaQuery.disableAnimationsOf(context) ||
                AppPreferences.instance.reducedMotion,
            textScaler: TextScaler.linear(
              MediaQuery.textScalerOf(context).scale(16) /
                  16 *
                  (AppPreferences.instance.largeText ? 1.15 : 1),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    ),
    home: const HeritagePaper(child: AuthGate()),
  );
}
