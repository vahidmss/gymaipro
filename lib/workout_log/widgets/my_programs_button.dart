import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// لینک کم‌رنگ به برنامه‌ها — نه CTA طلایی وسط مسیر تمرین.
class MyProgramsButton extends StatelessWidget {
  const MyProgramsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/my-club',
            arguments: {'initialTab': 0},
          );
        },
        icon: Icon(
          LucideIcons.listChecks,
          size: 15.sp,
          color: WorkoutLogColors.mutedText(context),
        ),
        label: Text(
          'برنامه‌های من',
          style: WorkoutLogTypography.caption(
            context,
            color: WorkoutLogColors.secondaryText(context),
            fontWeight: FontWeight.w700,
          ).copyWith(fontSize: 12.5.sp),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
