import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

/// GymAI design system theme — dark-first, gold primary.
abstract final class GymTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GymTypography.fontFamily,
    scaffoldBackgroundColor: GymColors.background,
    colorScheme: const ColorScheme.dark(
      primary: GymColors.primary,
      onPrimary: GymColors.onPrimary,
      secondary: GymColors.primaryDark,
      surface: GymColors.surface,
      error: GymColors.danger,
    ),
    textTheme: GymTypography.textTheme,
    dividerColor: GymColors.divider,
    cardColor: GymColors.card,
    cardTheme: const CardThemeData(
      color: GymColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: GymRadius.radiusXl,
        side: BorderSide(color: GymColors.borderSubtle),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GymColors.primary,
        foregroundColor: GymColors.onPrimary,
        textStyle: GymTypography.button,
        shape: const RoundedRectangleBorder(borderRadius: GymRadius.radiusLg),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GymColors.primary,
        side: const BorderSide(color: GymColors.primary),
        textStyle: GymTypography.button.copyWith(color: GymColors.primary),
        shape: const RoundedRectangleBorder(borderRadius: GymRadius.radiusLg),
      ),
    ),
    iconTheme: const IconThemeData(color: GymColors.primary),
    extensions: const <ThemeExtension<dynamic>>[GymThemeExtension.dark],
  );

  static GymThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<GymThemeExtension>() ??
        GymThemeExtension.dark;
  }
}

/// Theme extension for design-system tokens accessible from widgets.
class GymThemeExtension extends ThemeExtension<GymThemeExtension> {
  const GymThemeExtension({
    required this.background,
    required this.surface,
    required this.card,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  static const GymThemeExtension dark = GymThemeExtension(
    background: GymColors.background,
    surface: GymColors.surface,
    card: GymColors.card,
    primary: GymColors.primary,
    textPrimary: GymColors.textPrimary,
    textSecondary: GymColors.textSecondary,
    success: GymColors.success,
    warning: GymColors.warning,
    danger: GymColors.danger,
    info: GymColors.info,
  );

  final Color background;
  final Color surface;
  final Color card;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  @override
  GymThemeExtension copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? primary,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return GymThemeExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  GymThemeExtension lerp(ThemeExtension<GymThemeExtension>? other, double t) {
    if (other is! GymThemeExtension) return this;
    return GymThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
