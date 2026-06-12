import 'package:flutter/material.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// رنگ‌های خوانا برای ثبت تمرین: متن با کنتراست بالا، طلایی فقط برای accent.
abstract final class WorkoutLogColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryText(BuildContext context) => context.textColor;

  static Color secondaryText(BuildContext context) => isDark(context)
      ? context.textColor.withValues(alpha: 0.82)
      : AppTheme.lightTextSecondary;

  static Color accent(BuildContext context) =>
      isDark(context) ? AppTheme.goldColor : AppTheme.darkGold;

  static Color sectionBackground(BuildContext context) => isDark(context)
      ? context.cardColor
      : Colors.white;

  static Color chipFill(BuildContext context, {required bool selected}) {
    if (selected) {
      return isDark(context)
          ? AppTheme.goldColor.withValues(alpha: 0.22)
          : AppTheme.goldColor.withValues(alpha: 0.16);
    }
    return isDark(context)
        ? AppTheme.veryDarkBackground.withValues(alpha: 0.55)
        : AppTheme.lightBackgroundColor;
  }

  static Color chipText(BuildContext context, {required bool selected}) =>
      selected ? accent(context) : primaryText(context);

  static Color chipBorder(BuildContext context, {required bool selected}) =>
      selected
      ? accent(context).withValues(alpha: 0.55)
      : (isDark(context)
            ? AppTheme.darkGreySeparator.withValues(alpha: 0.45)
            : AppTheme.lightDividerColor);

  static Color noteText(BuildContext context) => isDark(context)
      ? const Color(0xFFFFE082)
      : const Color(0xFF4E342E);

  static Color noteBackground(BuildContext context) => isDark(context)
      ? const Color(0xFF2C2618)
      : const Color(0xFFFFF8E1);

  static Color noteBorder(BuildContext context) => isDark(context)
      ? const Color(0xFFFFB74D).withValues(alpha: 0.4)
      : const Color(0xFFE6A800).withValues(alpha: 0.45);

  static Color inputFill(BuildContext context) => isDark(context)
      ? const Color(0xFF121212)
      : Colors.white;

  static Color inputBorder(BuildContext context) => isDark(context)
      ? AppTheme.darkGreySeparator.withValues(alpha: 0.55)
      : AppTheme.lightDividerColor;

  static Color setBadgeText(BuildContext context, {required bool isSaved}) {
    if (isSaved) return Colors.white;
    return isDark(context) ? Colors.white : AppTheme.onGoldColor;
  }
}
