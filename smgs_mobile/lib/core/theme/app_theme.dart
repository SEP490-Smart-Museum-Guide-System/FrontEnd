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
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
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
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.antiqueIvory,
      selectedColor: AppColors.deepBurgundy,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      labelStyle: AppTextStyles.bodySmall,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
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
  );
}
