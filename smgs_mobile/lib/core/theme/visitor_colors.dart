import 'package:flutter/material.dart';

export 'visitor_tokens.dart';

/// Palette for the Flutter Visitor application — Soft Geometry Heritage System
abstract final class VisitorColors {
  // Page background: pure 100% white across all Visitor screens
  static const pageBackground = Color(0xFFFFFFFF);
  static const background = Color(0xFFFFFFFF);

  // Surfaces: Warm natural tones to separate cards & info containers from white background
  static const surface1 = Color(0xFFFAF7F2); // Primary surface: cards, list items, info panels
  static const surface2 = Color(0xFFF2EBE1); // Secondary surface: unselected chips, inputs, tracks
  static const surfaceBrand = Color(0xFFF5E9E6); // Light burgundy surface for badge/icon highlights
  static const surfaceGold = Color(0xFFF4EAD8); // Light gold surface for heritage badges

  // Semantic Aliases
  static const surface = surface1;
  static const card = surface1;
  static const secondaryBackground = surface2;
  static const brandSoft = surfaceBrand;

  // Heritage Brand Accents
  static const burgundy = Color(0xFF6B2E2E);
  static const gold = Color(0xFFB38B59);

  // Typography & Borders
  static const text = Color(0xFF2B2220);
  static const secondaryText = Color(0xFF6E625C);
  static const border = Color(0xFFEBE3D8);
  static const borderSubtle = Color(0xFFEBE3D8);
}
