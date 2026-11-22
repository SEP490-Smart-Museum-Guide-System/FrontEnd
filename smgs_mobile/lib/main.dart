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
import 'widgets/exploration_map_button.dart';
import 'models/experience.dart';

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

class SMGSApp extends StatefulWidget {
  const SMGSApp({super.key});
  @override
  State<SMGSApp> createState() => _SMGSAppState();
}

class _SMGSAppState extends State<SMGSApp> {
  final _explorationNavigation = ExplorationNavigator();
  String? _owner;

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorObservers: [_explorationNavigation],
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
        final user = AppServices.auth.user;
        final owner = user?.role == UserRole.visitor ? user?.email : null;
        if (owner != _owner) {
          _owner = owner;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _owner == owner)
              MuseumExploration.instance.restore(owner);
          });
        }
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
          child: AutomaticLocationHost(
            messengerKey: _messengerKey,
            child: Stack(
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
            ),
          ),
        );
      },
    ),
    home: const HeritagePaper(child: AuthGate()),
  );
}
