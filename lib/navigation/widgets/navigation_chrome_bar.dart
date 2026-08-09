import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Chrome مشترک برای نوارهای پایین (تب اصلی + نوار ارسال پیام).
/// رنگ‌ها فقط از [AppTheme] و extension تم می‌آیند تا با مین نویگیشن یکی بماند.
class NavigationChromeBar {
  NavigationChromeBar._();

  static BoxDecoration barDecoration(BuildContext context) {
    return BoxDecoration(
      color: context.backgroundColor,
      boxShadow: [
        BoxShadow(
          color: context.isDark
              ? AppTheme.veryDarkBackground.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: 15.r,
          offset: const Offset(0, -3),
          spreadRadius: 1,
        ),
      ],
      border: Border(
        top: BorderSide(color: context.separatorColor),
      ),
    );
  }

  /// پس‌زمینهٔ کنترل‌های داخل نوار (دکمه + فیلد) — نیمه‌شفاف روی همان کروم.
  static Color innerWellColor(BuildContext context) {
    return context.isDark
        ? AppTheme.darkCardColor.withValues(alpha: 0.55)
        : AppTheme.lightCardColor.withValues(alpha: 0.92);
  }
}
