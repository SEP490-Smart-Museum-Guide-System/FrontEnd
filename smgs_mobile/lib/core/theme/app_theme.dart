import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: AppTextStyles.sansFamily,
    colorScheme: const ColorScheme.light(
      primary: AppColors.deepBurgundy,
      onPrimary: AppColors.antiqueIvory,
      secondary: AppColors.mutedGold,
      onSecondary: AppColors.darkBrown,
      surface: AppColors.antiqueIvory,
      onSurface: AppColors.darkBrown,
      outline: AppColors.border,
      error: AppColors.deepBurgundy,
    ),
    textTheme: const TextTheme(
      headlineLarge: AppTextStyles.display,
      headlineMedium: AppTextStyles.pageTitle,
      titleLarge: AppTextStyles.cardTitle,
      titleMedium: AppTextStyles.sectionTitle,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.buttonText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.antiqueIvory,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.darkBrown,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.bodyMedium,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 32,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.deepBurgundy,
      linearTrackColor: AppColors.border,
    ),
    splashFactory: InkRipple.splashFactory,
    hoverColor: AppColors.deepBurgundy.withValues(alpha: .045),
    focusColor: AppColors.mutedGold.withValues(alpha: .14),
    highlightColor: AppColors.deepBurgundy.withValues(alpha: .055),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.deepBurgundy, width: 1.5),
      ),
      hintStyle: AppTextStyles.bodySmall,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: AppTextStyles.buttonText,
        foregroundColor: AppColors.deepBurgundy,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: AppTextStyles.buttonText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 52),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: AppTextStyles.buttonText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: AppTextStyles.buttonText,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.antiqueIvory,
      selectedColor: AppColors.deepBurgundy,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      labelStyle: AppTextStyles.bodySmall,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      height: 76,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppTextStyles.caption.copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.deepBurgundy
              : AppColors.secondaryText,
        ),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(7),
      radius: const Radius.circular(8),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => AppColors.deepBurgundy.withValues(
          alpha: states.contains(WidgetState.hovered) ? .55 : .28,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkBrown,
      contentTextStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.lightText,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
