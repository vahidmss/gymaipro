import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WorkoutDateSeparatorWidget extends StatelessWidget {
  const WorkoutDateSeparatorWidget({required this.selectedDate, super.key});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateText = MealLogUtils.getPersianFormattedDate(selectedDate);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.3 : 0.35,
                ),
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 14.sp,
                  color: AppTheme.goldColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  dateText,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isDark ? AppTheme.goldColor : AppTheme.darkGold,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
