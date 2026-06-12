import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Chrome مشترک برای نوارهای پایین (تب اصلی + نوار ارسال پیام).
/// رنگ‌ها فقط از [AppTheme] و extension تم می‌آیند تا با مین نویگیشن یکی بماند.
class NavigationChromeBar {
  NavigationChromeBar._();

  static BoxDecoration barDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: isDark
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightGradientStart.withValues(alpha: 0.15),
                AppTheme.lightCardColor,
                AppTheme.lightGradientEnd.withValues(alpha: 0.1),
              ],
            ),
      color: isDark ? context.backgroundColor : null,
      boxShadow: [
        BoxShadow(
          color: isDark
              ? AppTheme.veryDarkBackground.withValues(alpha: 0.15)
              : AppTheme.goldColor.withValues(alpha: 0.1),
          blurRadius: 15.r,
          offset: const Offset(0, -3),
          spreadRadius: 1,
        ),
      ],
      border: Border(
        top: BorderSide(
          color: isDark
              ? Colors.transparent
              : AppTheme.goldColor.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  /// پس‌زمینهٔ کنترل‌های داخل نوار (دکمه + فیلد) — نیمه‌شفاف روی همان کروم.
  static Color innerWellColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppTheme.darkCardColor.withValues(alpha: 0.55)
        : AppTheme.lightCardColor.withValues(alpha: 0.92);
  }
}
