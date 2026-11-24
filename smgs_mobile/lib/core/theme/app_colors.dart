import 'package:flutter/material.dart';

import 'visitor_colors.dart';

class AppColors {
  AppColors._();

  static const Color scaffoldBackground = VisitorColors.pageBackground; // 100% white
  static const Color antiqueIvory = VisitorColors.surface1; // #FAF7F2
  static const Color deepBurgundy = VisitorColors.burgundy; // #6B2E2E
  static const Color darkBrown = VisitorColors.text; // #2B2220
  static const Color mutedGold = VisitorColors.gold; // #B38B59

  // Convenient Aliases for Heritage Design System
  static const Color imperialGold = mutedGold;
  static const Color charcoal = darkBrown;
  static const Color charcoalBrown = darkBrown;
  static const Color parchmentBorder = border;
  static const Color softSand = VisitorColors.surface2; // #F2EBE1
  static const Color secondaryBackground = VisitorColors.secondaryBackground;

  static const Color surface = antiqueIvory;
  static const Color surface1 = VisitorColors.surface1;
  static const Color surface2 = VisitorColors.surface2;
  static const Color onSurface = darkBrown;
  static const Color card = VisitorColors.card; // #FAF7F2
  static const Color border = VisitorColors.border; // #EBE3D8
  static const Color primaryText = darkBrown;
  static const Color secondaryText = VisitorColors.secondaryText;
  static const Color lightText = Colors.white;
}
