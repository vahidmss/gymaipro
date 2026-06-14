import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
              color: WorkoutLogColors.iconOnSurface(context),
              size: 22.sp,
            ),
          ),
        ),
      ),
      title: Text(
        'ثبت تمرین',
        style: WorkoutLogTypography.sectionTitle(context).copyWith(
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
          color: WorkoutLogColors.primaryText(context),
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
                  color: WorkoutLogColors.iconOnSurface(context),
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
                color: WorkoutLogColors.iconOnSurface(context),
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
