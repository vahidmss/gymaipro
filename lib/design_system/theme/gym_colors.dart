import 'package:flutter/material.dart';

/// GymAI color tokens. Use these instead of hardcoded colors in features.
abstract final class GymColors {
  // Brand
  static const Color primary = Color(0xFFD4AF37);
  static const Color primaryDark = Color(0xFFB8860B);
  static const Color onPrimary = Color(0xFF0A0A0A);

  // Surfaces
  static const Color background = Color(0xFF090909);
  static const Color surface = Color(0xFF151515);
  static const Color card = Color(0xFF1B1B1B);
  static const Color elevated = Color(0xFF222222);
  static const Color overlay = Color(0xFF2A2A2A);

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color successMuted = Color(0xFF1E3D2A);
  static const Color warning = Color(0xFFFFB020);
  static const Color warningMuted = Color(0xFF3D3018);
  static const Color danger = Color(0xFFFF453A);
  static const Color dangerMuted = Color(0xFF3D1E1C);
  static const Color info = Color(0xFF5AC8FA);
  static const Color infoMuted = Color(0xFF1A3340);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF737373);
  static const Color textDisabled = Color(0xFF4D4D4D);

  // Borders & dividers
  static const Color border = Color(0xFF2E2E2E);
  static const Color borderSubtle = Color(0xFF1F1F1F);
  static const Color divider = Color(0xFF262626);

  // Neutral scale
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF0F0F0);
  static const Color neutral200 = Color(0xFFD9D9D9);
  static const Color neutral300 = Color(0xFFB3B3B3);
  static const Color neutral400 = Color(0xFF8C8C8C);
  static const Color neutral500 = Color(0xFF666666);
  static const Color neutral600 = Color(0xFF4D4D4D);
  static const Color neutral700 = Color(0xFF333333);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF1A1A1A);
  static const Color neutral950 = Color(0xFF0D0D0D);

  // Glass
  static Color glassSurface({double opacity = 0.92}) =>
      card.withValues(alpha: opacity);

  static Color glassBorder({double opacity = 0.08}) =>
      textPrimary.withValues(alpha: opacity);
}
