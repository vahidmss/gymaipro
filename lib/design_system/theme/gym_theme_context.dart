import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Bridges coach feature widgets to the main [AppTheme] (light/dark aware).
extension GymThemeContext on BuildContext {
  bool get gymIsDark => Theme.of(this).brightness == Brightness.dark;

  Color get gymBackground => Colors.transparent;

  Color get gymSurface => cardColor;

  Color get gymCard => cardColor;

  Color get gymElevated =>
      gymIsDark ? GymColors.elevated : AppTheme.lightSurfaceColor;

  Color get gymTextPrimary => textColor;

  Color get gymTextSecondary => textSecondary;

  Color get gymTextTertiary => gymIsDark
      ? GymColors.textTertiary
      : textSecondary.withValues(alpha: 0.78);

  /// Brand accent. Gold only on dark; deep bronze on light so small text stays readable.
  Color get gymPrimary =>
      gymIsDark ? AppTheme.goldColor : const Color(0xFF5C4A28);

  /// Soft gold fill/border ok on light; never use this for body/caption text.
  Color get gymGold => AppTheme.goldColor;

  Color get gymBorderSubtle => separatorColor.withValues(
    alpha: gymIsDark ? 0.9 : 0.75,
  );

  Color get gymBorder => separatorColor;

  Color get gymWarningMuted =>
      gymIsDark ? GymColors.warningMuted : AppTheme.fatColor.withValues(alpha: 0.12);

  Color get gymWarning => gymIsDark ? GymColors.warning : AppTheme.fatColor;

  TextStyle gymTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
    double height = 1.5,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color ?? gymTextPrimary,
    );
  }
}
