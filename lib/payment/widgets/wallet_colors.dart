import 'package:flutter/material.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// رنگ‌ها و تایپوگرافی یکپارچه برای بخش کیف پول.
abstract final class WalletColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryText(BuildContext context) => context.textColor;

  static Color secondaryText(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.72)
      : AppTheme.lightTextSecondary;

  static Color accent(BuildContext context) =>
      isDark(context) ? AppTheme.goldColor : AppTheme.darkGold;

  static Color cardSurface(BuildContext context) => context.cardColor;

  static Color cardBorder(BuildContext context) => isDark(context)
      ? AppTheme.darkGreySeparator
      : AppTheme.lightDividerColor;

  static Color positive(BuildContext context) => AppTheme.successColor;

  static Color negative(BuildContext context) => AppTheme.errorColor;

  static TextStyle titleStyle(BuildContext context) => TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: primaryText(context),
      );

  static TextStyle balanceStyle(BuildContext context) => TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5,
        color: accent(context),
      );

  static TextStyle captionStyle(BuildContext context) => TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12,
        color: secondaryText(context),
      );
}
