import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// تاریخ شمسی مینیمال — مثل «۲ آذر».
class WorkoutSessionDateChip extends StatelessWidget {
  const WorkoutSessionDateChip({
    required this.selectedDate,
    this.onTap,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final jalali = Jalali.fromDateTime(selectedDate);
    final month = MealLogUtils.getPersianMonthName(jalali.month);
    final dayFa = MealLogUtils.convertToPersianNumbers('${jalali.day}');
    final label = '$dayFa $month';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 14.sp,
                  color: WorkoutLogColors.mutedText(context),
                ),
                SizedBox(width: 6.w),
                Text(
                  label,
                  style: WorkoutLogTypography.sectionTitle(context).copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
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
