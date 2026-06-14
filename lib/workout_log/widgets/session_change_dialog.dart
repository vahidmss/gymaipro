import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SessionChangeDialog extends StatelessWidget {
  const SessionChangeDialog({
    required this.dateTime,
    required this.loggedSessionDay,
    required this.newSessionDay,
    this.hasUnsavedData = false,
    super.key,
  });

  final DateTime dateTime;
  final String loggedSessionDay;
  final String newSessionDay;
  final bool hasUnsavedData;

  @override
  Widget build(BuildContext context) {
    final dateString = MealLogUtils.getPersianFormattedDate(dateTime);
    final warningColor = WorkoutLogColors.warningText(context);

    return AlertDialog(
      backgroundColor: WorkoutLogColors.sectionBackground(context),
      title: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: warningColor, size: 24.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'تغییر سشن تمرین',
              style: WorkoutLogTypography.dialogTitle(context).copyWith(
                fontSize: 18.sp,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasUnsavedData && loggedSessionDay.isNotEmpty)
            Text(
              'شما در حال حاضر روز "$loggedSessionDay" را مقداردهی کرده‌اید.',
              style: WorkoutLogTypography.dialogBody(context),
            )
          else if (loggedSessionDay.isNotEmpty)
            Text(
              'برای تاریخ $dateString، سشن "$loggedSessionDay" قبلاً ثبت شده است.',
              style: WorkoutLogTypography.dialogBody(context),
            )
          else if (hasUnsavedData)
            Text(
              'شما داده‌هایی در فرم فعلی وارد کرده‌اید.',
              style: WorkoutLogTypography.dialogBody(context),
            ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: WorkoutLogColors.warningBackground(context),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: WorkoutLogColors.warningBorder(context),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, color: warningColor, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    hasUnsavedData && loggedSessionDay.isNotEmpty
                        ? 'در صورت تغییر به روز "$newSessionDay"، تمام اطلاعات وارد شده در روز "$loggedSessionDay" پاک خواهد شد.'
                        : hasUnsavedData
                        ? 'در صورت تغییر به روز "$newSessionDay"، تمام اطلاعات وارد شده در فرم فعلی پاک خواهد شد.'
                        : 'در صورت تغییر به سشن "$newSessionDay"، تمام اطلاعات ثبت شده در سشن "$loggedSessionDay" حذف خواهد شد.',
                    style: WorkoutLogTypography.dialogBody(context).copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'آیا مطمئن هستید که می‌خواهید ادامه دهید؟',
            style: WorkoutLogTypography.dialogMuted(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'لغو',
            style: WorkoutLogTypography.dialogMuted(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
          child: Text(
            'تایید و حذف',
            style: WorkoutLogTypography.dialogBody(context).copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.errorColor,
            ),
          ),
        ),
      ],
    );
  }
}
