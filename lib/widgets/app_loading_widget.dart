import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// ویجت استاندارد بارگذاری اپ — یک منبع برای همهٔ صفحات.
/// از تکرار Center + CircularProgressIndicator + متن جلوگیری می‌کند.
class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({super.key, this.message});

  /// متن اختیاری زیر اسپینر. پیش‌فرض: "در حال بارگذاری..."
  final String? message;

  static const String _defaultMessage = 'در حال بارگذاری...';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppTheme.goldColor.withValues(alpha: 0.8)
        : AppTheme.lightTextSecondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.goldColor, strokeWidth: 3),
          SizedBox(height: 16.h),
          Text(
            message ?? _defaultMessage,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: textColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
