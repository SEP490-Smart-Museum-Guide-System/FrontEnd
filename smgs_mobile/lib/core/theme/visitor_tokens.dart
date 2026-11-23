import 'package:flutter/material.dart';

/// Design tokens for Soft Geometry System in SMGS Mobile Visitor.
///
/// Radius scale strictly follows:
/// - xs: 8px (micro badges, status indicators, tiny thumbnails)
/// - sm: 12px (rectangular chips, icon containers <= 36px, filter tags)
/// - md: 16px (inputs, search bars, secondary buttons, inner images)
/// - lg: 20px (primary CTAs, standard buttons, action tiles, small cards)
/// - xl: 24px (museum cards, artifact cards, standard cards, dialogs)
/// - xxl: 32px (bottom sheet top corners, large hero cards, floating panels)
/// - full: 9999px (pill tags, round buttons, avatars, switches)
abstract final class VisitorRadius {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 9999.0;

  // BorderRadius conveniences
  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius borderFull = BorderRadius.all(Radius.circular(full));

  // Bottom sheet top-only border
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(xxl));

  /// Calculates nested inner radius: inner = max(outer - padding, 8), rounded to token.
  static double nested(double outer, double padding) {
    final diff = outer - padding;
    if (diff <= 8.0) return xs;
    if (diff <= 12.0) return sm;
    if (diff <= 16.0) return md;
    if (diff <= 20.0) return lg;
    if (diff <= 24.0) return xl;
    return xxl;
  }
}

/// Spacing grid for Soft Geometry: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48
abstract final class VisitorSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double section = 40.0;
  static const double sectionLarge = 48.0;
}
