import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Bridges coach feature widgets to the main [AppTheme] (light/dark aware).
extension GymThemeContext on BuildContext {
  bool get gymIsDark => Theme.of(this).brightness == Brightness.dark;

  Color get gymBackground => backgroundColor;

  Color get gymSurface => cardColor;

  Color get gymCard => cardColor;

  Color get gymElevated => surfaceElevated;

  Color get gymTextPrimary => textColor;

  Color get gymTextSecondary => textSecondary;

  Color get gymTextTertiary => gymIsDark
      ? AppTheme.darkTextDisabled
      : textSecondary.withValues(alpha: 0.78);

  Color get gymTextDisabled => textDisabled;

  /// Brand accent. Gold on dark; near-black on light.
  Color get gymPrimary =>
      gymIsDark ? AppTheme.goldColor : AppTheme.lightTextColor;

  /// Soft gold fill/border ok on light; never use this for body/caption text.
  Color get gymGold => AppTheme.goldColor;

  Color get gymBorderSubtle =>
      separatorColor.withValues(alpha: gymIsDark ? 0.9 : 0.75);

  Color get gymBorder => separatorColor;

  Color get gymWarningMuted => gymIsDark
      ? GymColors.warningMuted
      : AppTheme.fatColor.withValues(alpha: 0.12);

  Color get gymWarning => gymIsDark ? GymColors.warning : AppTheme.fatColor;

  Color get gymSuccess => gymIsDark ? GymColors.success : AppTheme.successColor;

  Color get gymDanger => gymIsDark ? GymColors.danger : AppTheme.errorColor;

  Color get gymInfo => gymIsDark ? GymColors.info : AppTheme.carbsColor;

  Color get gymNeutralFill =>
      gymIsDark ? AppTheme.darkSurfaceElevated : AppTheme.lightButtonBackground;

  Color get gymSkeletonBase =>
      gymIsDark ? AppTheme.darkSurfaceElevated : const Color(0xFFE7E2D9);

  Color get gymSkeletonHighlight =>
      gymIsDark ? AppTheme.darkGreyGradient : const Color(0xFFF5F2EA);

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
