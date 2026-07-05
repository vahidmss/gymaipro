import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// رنگ‌ها و تایپوگرافی خوانا برای ثبت رژیم غذایی.
abstract final class MealLogColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryText(BuildContext context) => context.textColor;

  static Color secondaryText(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.88)
      : AppTheme.lightTextSecondary;

  static Color mutedText(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.68)
      : AppTheme.lightTextSecondary.withValues(alpha: 0.92);

  static Color hintText(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.55)
      : AppTheme.lightTextSecondary.withValues(alpha: 0.8);

  static Color accent(BuildContext context) =>
      isDark(context) ? AppTheme.goldColor : AppTheme.darkGold;

  static Color iconOnSurface(BuildContext context) => isDark(context)
      ? AppTheme.goldColor
      : AppTheme.lightTextColor;

  static Color labelAccent(BuildContext context) => isDark(context)
      ? AppTheme.goldColor
      : AppTheme.lightTextColor;

  static Color chipText(BuildContext context, {required bool selected}) {
    if (!isDark(context)) return AppTheme.lightTextColor;
    return selected ? accent(context) : primaryText(context);
  }

  static Color sectionBackground(BuildContext context) => isDark(context)
      ? context.cardColor
      : Colors.white;

  static Color panelBackground(BuildContext context) => isDark(context)
      ? const Color(0xFF0C0C0C).withValues(alpha: 0.72)
      : Colors.white.withValues(alpha: 0.92);

  static Color chipFill(BuildContext context, {required bool selected}) {
    if (selected) {
      return isDark(context)
          ? AppTheme.goldColor.withValues(alpha: 0.24)
          : AppTheme.goldColor.withValues(alpha: 0.18);
    }
    return isDark(context)
        ? const Color(0xFF161616)
        : AppTheme.lightSurfaceColor;
  }

  static Color chipBorder(BuildContext context, {required bool selected}) =>
      selected
      ? accent(context).withValues(alpha: 0.62)
      : (isDark(context)
            ? AppTheme.darkGreySeparator.withValues(alpha: 0.55)
            : AppTheme.lightDividerColor);

  static Color noteText(BuildContext context) => isDark(context)
      ? const Color(0xFFFFE082)
      : const Color(0xFF3E2723);

  static Color noteBackground(BuildContext context) => isDark(context)
      ? const Color(0xFF2C2618)
      : const Color(0xFFFFF8E1);

  static Color noteBorder(BuildContext context) => isDark(context)
      ? const Color(0xFFFFB74D).withValues(alpha: 0.45)
      : const Color(0xFFE6A800).withValues(alpha: 0.5);

  static Color inputFill(BuildContext context) => isDark(context)
      ? const Color(0xFF121212)
      : Colors.white;

  static Color inputBorder(BuildContext context) => isDark(context)
      ? AppTheme.darkGreySeparator.withValues(alpha: 0.65)
      : AppTheme.lightDividerColor;

  static Color inputBorderFocused(BuildContext context) => accent(context);

  static Color successSolid(BuildContext context) => isDark(context)
      ? const Color(0xFF388E3C)
      : const Color(0xFF2E7D32);

  static Color successText(BuildContext context) => isDark(context)
      ? const Color(0xFFA5D6A7)
      : const Color(0xFF1B5E20);

  static Color successBackground(BuildContext context) => isDark(context)
      ? const Color(0xFF1B3D1F).withValues(alpha: 0.9)
      : const Color(0xFFE8F5E9);

  static Color successBorder(BuildContext context) => isDark(context)
      ? const Color(0xFF66BB6A).withValues(alpha: 0.55)
      : const Color(0xFF43A047).withValues(alpha: 0.5);

  static Color warningText(BuildContext context) => isDark(context)
      ? const Color(0xFFFFCC80)
      : const Color(0xFFE65100);

  static Color warningBackground(BuildContext context) => isDark(context)
      ? const Color(0xFF3E2723)
      : const Color(0xFFFFF3E0);

  static Color warningBorder(BuildContext context) => isDark(context)
      ? const Color(0xFFFFB74D).withValues(alpha: 0.55)
      : const Color(0xFFFF9800).withValues(alpha: 0.45);

  static Color errorText(BuildContext context) => isDark(context)
      ? const Color(0xFFFF8A80)
      : const Color(0xFFB71C1C);

  static Color planAccent(BuildContext context) => isDark(context)
      ? const Color(0xFF64B5F6)
      : const Color(0xFF1565C0);

  static Color emptyHint(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.42)
      : AppTheme.lightTextSecondary.withValues(alpha: 0.72);

  static Color macroText(BuildContext context, Color macroColor) =>
      isDark(context)
      ? macroColor.withValues(alpha: 0.95)
      : macroColor.withValues(alpha: 0.88);

  static Color onGoldSurface(BuildContext context) => AppTheme.onGoldColor;
}

abstract final class MealLogTypography {
  static TextStyle sectionTitle(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: MealLogColors.primaryText(context),
    height: 1.35,
  );

  static TextStyle mealTitle(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: MealLogColors.primaryText(context),
    letterSpacing: 0.1,
  );

  static TextStyle foodName(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 11.5.sp,
    fontWeight: FontWeight.w600,
    color: MealLogColors.primaryText(context),
  );

  static TextStyle caption(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 11.sp,
    fontWeight: fontWeight,
    color: color ?? MealLogColors.secondaryText(context),
  );

  static TextStyle chip(BuildContext context, {required bool selected}) =>
      TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12.sp,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: MealLogColors.chipText(context, selected: selected),
      );

  static TextStyle note(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    color: MealLogColors.noteText(context),
    height: 1.45,
  );

  static TextStyle statValue(BuildContext context, {Color? color}) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 24.sp,
    fontWeight: FontWeight.w900,
    color: color ?? MealLogColors.primaryText(context),
    height: 1.1,
  );

  static TextStyle statLabel(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 10.sp,
    fontWeight: FontWeight.w600,
    color: MealLogColors.secondaryText(context),
  );
}
