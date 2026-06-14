import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
                  WorkoutLogColors.accent(context).withValues(
                    alpha: isDark ? 0.35 : 0.45,
                  ),
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
              color: WorkoutLogColors.chipFill(context, selected: true),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: WorkoutLogColors.chipBorder(context, selected: true),
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 15.sp,
                  color: WorkoutLogColors.iconOnSurface(context),
                ),
                SizedBox(width: 8.w),
                Text(
                  dateText,
                  style: WorkoutLogTypography.sectionTitle(context).copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
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
                  WorkoutLogColors.accent(context).withValues(
                    alpha: isDark ? 0.35 : 0.45,
                  ),
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
