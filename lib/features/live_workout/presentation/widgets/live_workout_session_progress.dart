import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Session-level progress — same style as dashboard strip (light rebuilds).
class LiveWorkoutSessionProgress extends StatelessWidget {
  const LiveWorkoutSessionProgress({
    required this.session,
    required this.savedSets,
    required this.totalSets,
    this.restDefaultSeconds = 90,
    this.onRestSettingsTap,
    super.key,
  });

  final WorkoutSession session;
  final int savedSets;
  final int totalSets;

  /// ۰ = تایمر خاموش
  final int restDefaultSeconds;
  final VoidCallback? onRestSettingsTap;

  static String _formatShort(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return '${m}m';
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (totalSets == 0) return const SizedBox.shrink();

    final isAllDone = savedSets >= totalSets;
    final progress = totalSets == 0 ? 0.0 : savedSets / totalSets;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 12.w, 14.h),
      decoration: BoxDecoration(
        color: WorkoutLogColors.sectionBackground(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: WorkoutLogColors.accent(context).withValues(alpha: 0.28),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  session.focus,
                  style: WorkoutLogTypography.sectionTitle(context).copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isAllDone
                      ? WorkoutLogColors.successBackground(context)
                      : context.surfaceElevated,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  isAllDone ? 'کامل' : '$savedSets از $totalSets ست',
                  style: WorkoutLogTypography.caption(
                    context,
                    color: isAllDone
                        ? WorkoutLogColors.successText(context)
                        : WorkoutLogColors.secondaryText(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onRestSettingsTap != null) ...[
                SizedBox(width: 8.w),
                Material(
                  color: restDefaultSeconds > 0
                      ? WorkoutLogColors.chipFill(context, selected: true)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  child: InkWell(
                    onTap: onRestSettingsTap,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: restDefaultSeconds > 0 ? 8.w : 6.w,
                        vertical: 5.h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            LucideIcons.timer,
                            size: 14.sp,
                            color: restDefaultSeconds > 0
                                ? AppTheme.goldColor
                                : WorkoutLogColors.mutedText(context),
                          ),
                          if (restDefaultSeconds > 0) ...[
                            SizedBox(width: 4.w),
                            Text(
                              _formatShort(restDefaultSeconds),
                              style: WorkoutLogTypography.caption(
                                context,
                                color: AppTheme.goldColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (session.title.isNotEmpty && session.title != session.focus) ...[
            SizedBox(height: 4.h),
            Text(
              session.title,
              style: WorkoutLogTypography.caption(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(999.r),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 5.h,
              backgroundColor: WorkoutLogColors.pendingDot(
                context,
              ).withValues(alpha: 0.35),
              color: isAllDone
                  ? WorkoutLogColors.successSolid(context)
                  : WorkoutLogColors.accent(context),
            ),
          ),
        ],
      ),
    );
  }
}
