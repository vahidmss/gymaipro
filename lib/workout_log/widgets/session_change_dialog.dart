import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 24.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'تغییر سشن تمرین',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
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
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                height: 1.6,
              ),
            )
          else if (loggedSessionDay.isNotEmpty)
            Text(
              'برای تاریخ $dateString، سشن "$loggedSessionDay" قبلاً ثبت شده است.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                height: 1.6,
              ),
            )
          else if (hasUnsavedData)
            Text(
              'شما داده‌هایی در فرم فعلی وارد کرده‌اید.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                height: 1.6,
              ),
            ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: Colors.orange, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    hasUnsavedData && loggedSessionDay.isNotEmpty
                        ? 'در صورت تغییر به روز "$newSessionDay"، تمام اطلاعات وارد شده در روز "$loggedSessionDay" پاک خواهد شد.'
                        : hasUnsavedData
                        ? 'در صورت تغییر به روز "$newSessionDay"، تمام اطلاعات وارد شده در فرم فعلی پاک خواهد شد.'
                        : 'در صورت تغییر به سشن "$newSessionDay"، تمام اطلاعات ثبت شده در سشن "$loggedSessionDay" حذف خواهد شد.',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[900],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'آیا مطمئن هستید که می‌خواهید ادامه دهید؟',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'لغو',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(
            'تایید و حذف',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
