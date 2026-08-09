import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key, this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.dumbbell,
              size: 36.sp,
              color: AppTheme.goldColor.withValues(alpha: 0.7),
            ),
            SizedBox(height: 14.h),
            Text(
              'این روز هنوز خالیه',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              'اولین حرکت رو اضافه کن تا ساخت برنامه شروع بشه.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark
                    ? AppTheme.goldColor.withValues(alpha: 0.7)
                    : context.textColor.withValues(alpha: 0.55),
                fontSize: 12.sp,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAdd != null) ...[
              SizedBox(height: 18.h),
              Material(
                color: AppTheme.goldColor,
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 11.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.plus,
                          size: 16.sp,
                          color: AppTheme.onGoldColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'افزودن حرکت',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: AppTheme.onGoldColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
