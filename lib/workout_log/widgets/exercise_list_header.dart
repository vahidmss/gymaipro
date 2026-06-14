import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExerciseListHeader extends StatelessWidget {
  const ExerciseListHeader({required this.sessionNotes, super.key});
  final String sessionNotes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.1),
            AppTheme.darkGold.withValues(alpha: isDark ? 0.06 :
            0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.35),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.lightTextColor.withValues(alpha: 0.05),
            blurRadius: 12.r,
            offset: Offset(0.w, 4.h),
          ),
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 6.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      const Color(0xFFB8860B).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  LucideIcons.clipboardList,
                  color: WorkoutLogColors.iconOnSurface(context),
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'توضیحات روز تمرینی',
                style: WorkoutLogTypography.sectionTitle(context).copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: WorkoutLogColors.labelAccent(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            sessionNotes,
            style: WorkoutLogTypography.note(context).copyWith(
              fontSize: 13.5.sp,
              color: WorkoutLogColors.primaryText(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
