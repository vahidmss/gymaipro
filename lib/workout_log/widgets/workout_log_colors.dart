import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// رنگ‌ها و تایپوگرافی خوانا برای ثبت تمرین.
abstract final class WorkoutLogColors {
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

  /// متن و آیکن روی پس‌زمینه روشن — در لایت همیشه تیره.
  static Color iconOnSurface(BuildContext context) => isDark(context)
      ? AppTheme.goldColor
      : AppTheme.lightTextColor;

  static Color labelAccent(BuildContext context) => isDark(context)
      ? AppTheme.goldColor
      : AppTheme.lightTextColor;

  static Color chipText(BuildContext context, {required bool selected}) {
    if (!isDark(context)) {
      return AppTheme.lightTextColor;
    }
    return selected ? accent(context) : primaryText(context);
  }

  static Color sectionBackground(BuildContext context) => isDark(context)
      ? context.cardColor
      : Colors.white;

  static Color setsPanelBackground(BuildContext context) => isDark(context)
      ? const Color(0xFF0C0C0C).withValues(alpha: 0.72)
      : Colors.white.withValues(alpha: 0.88);

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

  static Color setBadgeFill(BuildContext context, {required bool isSaved}) {
    if (isSaved) return successSolid(context);
    return isDark(context)
        ? AppTheme.goldColor.withValues(alpha: 0.22)
        : AppTheme.goldColor.withValues(alpha: 0.16);
  }

  static Color setBadgeText(BuildContext context, {required bool isSaved}) {
    if (isSaved) return Colors.white;
    return isDark(context) ? AppTheme.goldColor : AppTheme.lightTextColor;
  }

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

  static Color pendingDot(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.38)
      : AppTheme.lightTextSecondary.withValues(alpha: 0.45);

  static Color warningText(BuildContext context) => isDark(context)
      ? const Color(0xFFFFCC80)
      : const Color(0xFFE65100);

  static Color warningBackground(BuildContext context) => isDark(context)
      ? const Color(0xFF3E2723)
      : const Color(0xFFFFF3E0);

  static Color warningBorder(BuildContext context) => isDark(context)
      ? const Color(0xFFFFB74D).withValues(alpha: 0.55)
      : const Color(0xFFFF9800).withValues(alpha: 0.45);

  static Color dialogTitle(BuildContext context) =>
      WorkoutLogColors.primaryText(context);

  static Color dialogBody(BuildContext context) =>
      WorkoutLogColors.primaryText(context);

  static Color dialogMuted(BuildContext context) =>
      WorkoutLogColors.secondaryText(context);

  static Color onGoldSurface(BuildContext context) => AppTheme.onGoldColor;

  static Color supersetAccent(BuildContext context) => isDark(context)
      ? const Color(0xFFFFD54F)
      : AppTheme.lightTextColor;
}

abstract final class WorkoutLogTypography {
  static TextStyle exerciseTitle(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w800,
    color: WorkoutLogColors.primaryText(context),
    height: 1.35,
  );

  static TextStyle fieldLabel(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 11.5.sp,
    fontWeight: FontWeight.w700,
    color: WorkoutLogColors.secondaryText(context),
  );

  static TextStyle inputValue(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
    color: WorkoutLogColors.primaryText(context),
  );

  static TextStyle inputHint(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: WorkoutLogColors.hintText(context),
  );

  static TextStyle inputSuffix(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    color: WorkoutLogColors.secondaryText(context),
  );

  static TextStyle caption(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 11.sp,
    fontWeight: fontWeight,
    color: color ?? WorkoutLogColors.secondaryText(context),
  );

  static TextStyle note(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: WorkoutLogColors.noteText(context),
    height: 1.45,
  );

  static TextStyle sectionTitle(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: WorkoutLogColors.primaryText(context),
    height: 1.35,
  );

  static TextStyle chip(BuildContext context, {required bool selected}) =>
      TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 13.sp,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: WorkoutLogColors.chipText(context, selected: selected),
      );

  static TextStyle trainerLabel(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 11.5.sp,
    fontWeight: FontWeight.w600,
    color: WorkoutLogColors.secondaryText(context),
  );

  static TextStyle trainerName(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w800,
    color: WorkoutLogColors.primaryText(context),
    height: 1.2,
  );

  static TextStyle dialogTitle(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w800,
    color: WorkoutLogColors.dialogTitle(context),
  );

  static TextStyle dialogBody(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 1.55,
    color: WorkoutLogColors.dialogBody(context),
  );

  static TextStyle dialogMuted(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 13.sp,
    fontWeight: FontWeight.w500,
    color: WorkoutLogColors.dialogMuted(context),
  );
}
