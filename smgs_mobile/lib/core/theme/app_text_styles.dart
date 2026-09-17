import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();
  static const serifFamily = 'NotoSerif';
  static const sansFamily = 'NotoSans';
  static const display = TextStyle(
    fontFamily: serifFamily,
    fontSize: 30,
    fontWeight: FontWeight.w500,
    color: AppColors.darkBrown,
    height: 1.3,
    letterSpacing: -0.8,
  );
  static const pageTitle = TextStyle(
    fontFamily: serifFamily,
    fontSize: 26,
    fontWeight: FontWeight.w500,
    color: AppColors.darkBrown,
    height: 1.35,
    letterSpacing: -0.5,
  );
  static const sectionTitle = TextStyle(
    fontFamily: serifFamily,
    fontSize: 21,
    fontWeight: FontWeight.w500,
    color: AppColors.darkBrown,
    height: 1.4,
  );
  static const cardTitle = TextStyle(
    fontFamily: serifFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.darkBrown,
    height: 1.4,
    letterSpacing: -0.4,
  );
  static const bodyLarge = TextStyle(
    fontFamily: sansFamily,
    fontSize: 17,
    color: AppColors.darkBrown,
    height: 1.65,
  );
  static const bodyMedium = TextStyle(
    fontFamily: sansFamily,
    fontSize: 16,
    color: AppColors.darkBrown,
    height: 1.55,
  );
  static const bodySmall = TextStyle(
    fontFamily: sansFamily,
    fontSize: 15,
    color: AppColors.secondaryText,
    height: 1.5,
  );
  static const buttonText = TextStyle(
    fontFamily: sansFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const caption = TextStyle(
    fontFamily: sansFamily,
    fontSize: 14,
    color: AppColors.secondaryText,
    height: 1.45,
  );
}
