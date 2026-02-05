import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WorkoutLogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WorkoutLogAppBar({
    required this.selectedDate,
    required this.onBackPressed,
    required this.onDatePickerPressed,
    this.onPreviewPressed,
    super.key,
  });
  final DateTime selectedDate;
  final VoidCallback onBackPressed;
  final VoidCallback onDatePickerPressed;
  final VoidCallback? onPreviewPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? context.backgroundColor : Colors.transparent,
      elevation: 0,
      leading: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: onBackPressed,
          child: Container(
            width: 36.w,
            height: 36.h,
            padding: EdgeInsets.all(6.w),
            child: Icon(
              LucideIcons.arrowRight,
              color: AppTheme.goldColor,
              size: 22.sp,
            ),
          ),
        ),
      ),
      title: Text(
        'ثبت تمرین',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: isDark ? AppTheme.goldColor : context.textColor,
          fontWeight: FontWeight.w700,
          fontSize: 18.sp,
        ),
      ),
      centerTitle: true,
      actions: [
        if (onPreviewPressed != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.r),
              onTap: onPreviewPressed,
              child: Container(
                width: 36.w,
                height: 36.h,
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  LucideIcons.fileText,
                  color: AppTheme.goldColor,
                  size: 18.sp,
                ),
              ),
            ),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: onDatePickerPressed,
            child: Container(
              width: 36.w,
              height: 36.h,
              padding: EdgeInsets.all(8.w),
              child: Icon(
                LucideIcons.calendar,
                color: AppTheme.goldColor,
                size: 18.sp,
              ),
            ),
          ),
        ),
        SizedBox(width: 4.w),
      ],
    );
  }
}
