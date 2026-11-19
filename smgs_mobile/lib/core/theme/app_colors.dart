import 'package:flutter/material.dart';

import 'visitor_colors.dart';

class AppColors {
  AppColors._();

  static const Color antiqueIvory = VisitorColors.background;
  static const Color deepBurgundy = VisitorColors.burgundy;
  static const Color darkBrown = VisitorColors.text;
  static const Color mutedGold = VisitorColors.gold;

  // Convenient Aliases for Heritage Design System
  static const Color imperialGold = mutedGold;
  static const Color charcoalBrown = darkBrown;
  static const Color parchmentBorder = border;
  static const Color softSand = VisitorColors.secondaryBackground;

  static const Color surface = antiqueIvory;
  static const Color onSurface = darkBrown;
  static const Color card = VisitorColors.card;
  static const Color border = VisitorColors.border;
  static const Color scaffoldBackground = antiqueIvory;
  static const Color primaryText = darkBrown;
  static const Color secondaryText = VisitorColors.secondaryText;
  static const Color lightText = VisitorColors.background;
}
