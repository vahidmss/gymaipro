import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MyProgramsButton extends StatelessWidget {
  const MyProgramsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/my-club',
              arguments: {'initialTab': 0},
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.3 : 0.35,
                ),
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.listChecks,
                  color: AppTheme.goldColor,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'برنامه‌های من',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.goldColor : AppTheme.darkGold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
