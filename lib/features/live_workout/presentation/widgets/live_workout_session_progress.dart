import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';

/// Session-level progress — same dot style as workout-log exercise headers.
class LiveWorkoutSessionProgress extends StatelessWidget {
  const LiveWorkoutSessionProgress({
    required this.session,
    required this.savedSets,
    required this.totalSets,
    super.key,
  });

  final WorkoutSession session;
  final int savedSets;
  final int totalSets;

  @override
  Widget build(BuildContext context) {
    if (totalSets == 0) return const SizedBox.shrink();

    final isAllDone = savedSets >= totalSets;
    final progress = totalSets == 0 ? 0.0 : savedSets / totalSets;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: WorkoutLogColors.sectionBackground(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: WorkoutLogColors.accent(context).withValues(alpha: 0.28),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            session.focus,
            style: WorkoutLogTypography.sectionTitle(context),
          ),
          if (session.title.isNotEmpty && session.title != session.focus) ...[
            SizedBox(height: 4.h),
            Text(
              session.title,
              style: WorkoutLogTypography.caption(context),
            ),
          ],
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6.h,
              backgroundColor: WorkoutLogColors.pendingDot(context),
              color: WorkoutLogColors.successSolid(context),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: <Widget>[
              ...List.generate(totalSets.clamp(0, 24), (i) {
                final done = i < savedSets;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 8.w,
                  height: 8.w,
                  margin: EdgeInsets.only(left: 3.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? WorkoutLogColors.successSolid(context)
                        : WorkoutLogColors.pendingDot(context),
                  ),
                );
              }),
              if (totalSets > 24) ...[
                SizedBox(width: 6.w),
                Text(
                  '…',
                  style: WorkoutLogTypography.caption(context),
                ),
              ],
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  isAllDone ? '✓ همه ست‌ها ثبت شد' : '$savedSets/$totalSets ست',
                  key: ValueKey('$savedSets-$totalSets'),
                  style: WorkoutLogTypography.caption(
                    context,
                    color: isAllDone
                        ? WorkoutLogColors.successText(context)
                        : WorkoutLogColors.secondaryText(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
