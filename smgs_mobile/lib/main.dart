import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'screens/auth/auth_screen.dart';
import 'services/app_preferences.dart';
import 'widgets/heritage_decoration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      listenable: AppPreferences.instance,
      builder: (context, _) => MediaQuery(
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
        child: ColoredBox(
          color: AppColors.darkBrown,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: ClipRect(
                child: HeritagePaper(child: child ?? const SizedBox.shrink()),
              ),
            ),
          ),
        ),
      ),
    ),
    home: const AuthGate(),
  );
}
