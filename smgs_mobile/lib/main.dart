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
import 'widgets/automatic_location_host.dart';

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

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
    scaffoldMessengerKey: _messengerKey,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.lightTheme,
    builder: (context, child) => ListenableBuilder(
      listenable: Listenable.merge([AppPreferences.instance, AppServices.auth]),
      builder: (context, _) {
        final rawMediaQuery = MediaQuery.of(context);
        final isDesktopWide = rawMediaQuery.size.width > 600;
        final effectiveWidth = isDesktopWide ? 600.0 : rawMediaQuery.size.width;
        final tunedMediaQuery = rawMediaQuery.copyWith(
          size: Size(effectiveWidth, rawMediaQuery.size.height),
          disableAnimations:
              rawMediaQuery.disableAnimations ||
              AppPreferences.instance.reducedMotion,
          textScaler: TextScaler.linear(
            rawMediaQuery.textScaler.scale(16) /
                16 *
                (AppPreferences.instance.largeText ? 1.15 : 1),
          ),
        );

        Widget mobileShell = child ?? const SizedBox.shrink();

        if (isDesktopWide) {
          mobileShell = ColoredBox(
            color: const Color(0xFFEDE7DC), // heritage paper desk tone outside mobile frame
            child: Center(
              child: SizedBox(
                width: 600,
                height: double.infinity,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF7F2),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: mobileShell,
                ),
              ),
            ),
          );
        }

        return MediaQuery(
          data: tunedMediaQuery,
          child: AutomaticLocationHost(
            messengerKey: _messengerKey,
            child: mobileShell,
          ),
        );
      },
    ),
    home: const HeritagePaper(child: AuthGate()),
  );
}
