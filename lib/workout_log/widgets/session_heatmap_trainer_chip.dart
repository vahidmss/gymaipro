import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/muscle_heatmap_aggregate.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// دکمهٔ «نقشه جلسه» داخل کارت مربی — واضح و کم‌هزینه.
class SessionHeatmapTrainerChip extends StatefulWidget {
  const SessionHeatmapTrainerChip({
    required this.viewModel,
    required this.onTap,
    super.key,
  });

  final WorkoutLogViewModel viewModel;
  final VoidCallback onTap;

  @override
  State<SessionHeatmapTrainerChip> createState() =>
      _SessionHeatmapTrainerChipState();
}

class _SessionHeatmapTrainerChipState extends State<SessionHeatmapTrainerChip> {
  bool _wasLive = false;

  @override
  Widget build(BuildContext context) {
    if (widget.viewModel.selectedSession == null) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<int>(
      valueListenable: widget.viewModel.sessionHeatmapTick,
      builder: (context, _, __) {
        final snap = widget.viewModel.sessionHeatmapSnapshot;
        final isLive = snap.hasHeatmapData;
        final hasSets = snap.hasAnySets;
        final isActive = isLive || hasSets;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (isLive && !_wasLive) {
          _wasLive = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            HapticFeedback.mediumImpact();
          });
        } else if (!isLive) {
          _wasLive = false;
        }

        final subtitle = isLive
            ? _liveSubtitle(snap)
            : hasSets
                ? '${snap.completedSets} ست ثبت شد'
                : 'بعد از ثبت ست‌ها، نقشه زنده می‌شود';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: LinearGradient(
                  colors: isLive
                      ? [
                          AppTheme.goldColor.withValues(alpha: 0.28),
                          AppTheme.goldColor.withValues(alpha: 0.1),
                        ]
                      : isActive
                          ? [
                              AppTheme.goldColor.withValues(alpha: 0.22),
                              AppTheme.goldColor.withValues(alpha: 0.08),
                            ]
                          : [
                              (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.06),
                              (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.02),
                            ],
                ),
                border: Border.all(
                  color: isLive
                      ? AppTheme.goldColor.withValues(alpha: 0.65)
                      : isActive
                          ? AppTheme.goldColor.withValues(alpha: 0.4)
                          : AppTheme.goldColor.withValues(alpha: 0.25),
                  width: isLive ? 1.4 : isActive ? 1.2 : 1,
                ),
                boxShadow: isLive
                    ? [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: isLive
                            ? AppTheme.goldColor.withValues(alpha: 0.32)
                            : AppTheme.goldColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Icon(
                          isLive ? LucideIcons.sparkles : LucideIcons.flame,
                          size: 20.sp,
                          color: isActive
                              ? AppTheme.goldColor
                              : AppTheme.goldColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLive ? 'نقشهٔ زنده' : 'نقشهٔ این جلسه',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: WorkoutLogColors.primaryText(context),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                              color: WorkoutLogColors.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLive && snap.topMuscleLabel != null) ...[
                      Container(
                        margin: EdgeInsets.only(left: 6.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          snap.topMuscleLabel!,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.goldColor,
                          ),
                        ),
                      ),
                    ],
                    Icon(
                      LucideIcons.chevronLeft,
                      size: 18.sp,
                      color: AppTheme.goldColor.withValues(alpha: 0.8),
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

  static String _liveSubtitle(MuscleHeatmapSnapshot snap) {
    final parts = <String>['${snap.completedSets} ست'];
    if (snap.topMuscleLabel != null) {
      parts.add('بیشترین: ${snap.topMuscleLabel}');
    }
    return parts.join(' · ');
  }
}
