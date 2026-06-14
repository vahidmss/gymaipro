import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MyProgramsButton extends StatelessWidget {
  const MyProgramsButton({super.key});

  @override
  Widget build(BuildContext context) {
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
              color: WorkoutLogColors.chipFill(context, selected: true),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: WorkoutLogColors.chipBorder(context, selected: true),
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.listChecks,
                  color: WorkoutLogColors.iconOnSurface(context),
                  size: 17.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'برنامه‌های من',
                  style: WorkoutLogTypography.chip(context, selected: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
