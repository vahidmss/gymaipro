import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/services/muscle_heatmap_aggregate.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// خلاصهٔ زندهٔ نقشهٔ جلسه — بدنهٔ کامل فقط در شیت جزئیات.
class SessionLiveHeatmapCard extends StatelessWidget {
  const SessionLiveHeatmapCard({
    required this.viewModel,
    required this.onDetails,
    super.key,
  });

  final WorkoutLogViewModel viewModel;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    if (viewModel.selectedSession == null) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<int>(
      valueListenable: viewModel.sessionHeatmapTick,
      builder: (context, _, __) {
        final snap = viewModel.sessionHeatmapSnapshot;
        final live = snap.hasHeatmapData;

        return Material(
          color: WorkoutLogColors.sectionBackground(context),
          borderRadius: BorderRadius.circular(14.r),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onDetails();
            },
            borderRadius: BorderRadius.circular(14.r),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: live
                      ? AppTheme.goldColor.withValues(alpha: 0.35)
                      : WorkoutLogColors.inputBorder(context),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 12.w, 12.h),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: live
                            ? AppTheme.goldColor.withValues(alpha: 0.14)
                            : WorkoutLogColors.chipFill(
                                context,
                                selected: false,
                              ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        LucideIcons.flame,
                        size: 18.sp,
                        color: live
                            ? AppTheme.goldColor
                            : WorkoutLogColors.mutedText(context),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _LiveDot(active: live),
                              SizedBox(width: 6.w),
                              Text(
                                'نقشهٔ این جلسه',
                                style: WorkoutLogTypography.sectionTitle(
                                  context,
                                ).copyWith(fontSize: 13.5.sp),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            live
                                ? _subtitle(snap)
                                : 'با ثبت حرکت، نقشه زنده می‌شود',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WorkoutLogTypography.caption(
                              context,
                              color: WorkoutLogColors.mutedText(context),
                            ),
                          ),
                          if (live && snap.topMuscles.isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Text(
                              snap.topMuscles
                                  .map(
                                    (e) =>
                                        '${MuscleTargets.label(e.key)} ${e.value}',
                                  )
                                  .join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WorkoutLogTypography.caption(
                                context,
                                fontWeight: FontWeight.w700,
                              ).copyWith(fontSize: 11.sp),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronLeft,
                      size: 18.sp,
                      color: WorkoutLogColors.mutedText(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _subtitle(MuscleHeatmapSnapshot snap) {
    final parts = <String>[];
    if (snap.completedSets > 0) parts.add('${snap.completedSets} ثبت');
    if (snap.topMuscleLabel != null) {
      parts.add('بیشترین: ${snap.topMuscleLabel}');
    }
    return parts.isEmpty ? 'شدت نسبی جلسه' : parts.join(' · ');
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7.w,
      height: 7.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? WorkoutLogColors.successSolid(context)
            : WorkoutLogColors.mutedText(context).withValues(alpha: 0.35),
      ),
    );
  }
}
