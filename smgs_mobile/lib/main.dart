import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'screens/auth/auth_screen.dart';
import 'services/app_services.dart';
import 'services/app_preferences.dart';
import 'services/token_manager.dart';
import 'services/backend_auth_service.dart';
import 'widgets/heritage_decoration.dart';
import 'widgets/automatic_location_host.dart';
import 'widgets/exploration_map_button.dart';
import 'models/experience.dart';

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo lưu trữ cấu hình người dùng & ngôn ngữ
  await AppPreferences.instance.init();

  // Khởi tạo lưu trữ phiên Token JWT
  await TokenManager.init();

  // Khởi tạo dịch vụ Authentication kết nối trực tiếp Backend
  AppServices.auth = BackendAuthService();

  // Keep web controls available to assistive technology for the app lifetime.
  SemanticsBinding.instance.ensureSemantics();
  runApp(const SMGSApp());
}

class SMGSApp extends StatefulWidget {
  const SMGSApp({super.key});
  @override
  State<SMGSApp> createState() => _SMGSAppState();
}

class _SMGSAppState extends State<SMGSApp> {
  final _explorationNavigation = ExplorationNavigator();
  String? _owner;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppPreferences.instance,
    builder: (context, _) => MaterialApp(
      navigatorObservers: [_explorationNavigation],
      title: AppLocalizations.current.appTitle,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      locale: Locale(AppPreferences.instance.language),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      theme: AppTheme.lightTheme,
      builder: (context, child) => ListenableBuilder(
        listenable: AppServices.auth,
        builder: (context, _) {
          final user = AppServices.auth.user;
          final owner = user?.role == UserRole.visitor ? user?.email : null;
          if (owner != _owner) {
            _owner = owner;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _owner == owner) {
                MuseumExploration.instance.restore(owner);
              }
            });
          }
          final rawMediaQuery = MediaQuery.of(context);
          final isDesktopWide = rawMediaQuery.size.width > 600;
          final effectiveWidth = isDesktopWide
              ? 600.0
              : rawMediaQuery.size.width;
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

          Widget mobileShell = Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              if (owner != null)
                Positioned.fill(
                  child: ExplorationMapButton(
                    navigation: _explorationNavigation,
                  ),
                ),
            ],
          );

          if (isDesktopWide) {
            mobileShell = ColoredBox(
              color: const Color(
                0xFFEDE7DC,
              ), // heritage paper desk tone outside mobile frame
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
    ),
  );
}
