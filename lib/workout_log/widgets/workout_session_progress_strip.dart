import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نوار چسبان پیشرفت جلسه — سبک و بدون rebuild کل صفحه.
class WorkoutSessionProgressStrip extends StatelessWidget {
  const WorkoutSessionProgressStrip({
    required this.viewModel,
    this.onSessionTap,
    this.setupExpanded = false,
    this.restDefaultSeconds = 90,
    this.onRestSettingsTap,
    super.key,
  });

  final WorkoutLogViewModel viewModel;
  final VoidCallback? onSessionTap;
  final bool setupExpanded;

  /// ۰ = تایمر خاموش
  final int restDefaultSeconds;
  final VoidCallback? onRestSettingsTap;

  @override
  Widget build(BuildContext context) {
    final session = viewModel.selectedSession;
    if (session == null) return const SizedBox.shrink();

    return ValueListenableBuilder<int>(
      valueListenable: viewModel.sessionProgressTick,
      builder: (context, _, __) {
        final counts = viewModel.sessionSetCounts;
        final completed = counts.$1;
        final total = counts.$2;
        final progress = total == 0 ? 0.0 : completed / total;
        final done = total > 0 && completed >= total;

        return Material(
          color: WorkoutLogColors.sectionBackground(context),
          elevation: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 12.w, 10.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: WorkoutLogColors.inputBorder(context),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onSessionTap,
                          borderRadius: BorderRadius.circular(8.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    session.day,
                                    style: WorkoutLogTypography.sectionTitle(
                                      context,
                                    ).copyWith(fontSize: 13.5.sp),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (onSessionTap != null) ...[
                                  SizedBox(width: 4.w),
                                  Icon(
                                    setupExpanded
                                        ? LucideIcons.chevronUp
                                        : LucideIcons.chevronDown,
                                    size: 14.sp,
                                    color: WorkoutLogColors.mutedText(context),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      done ? 'کامل' : '$completed از $total',
                      style: WorkoutLogTypography.caption(
                        context,
                        color: done
                            ? WorkoutLogColors.successText(context)
                            : WorkoutLogColors.secondaryText(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (onRestSettingsTap != null) ...[
                      SizedBox(width: 8.w),
                      Material(
                        color: restDefaultSeconds > 0
                            ? WorkoutLogColors.chipFill(
                                context,
                                selected: true,
                              )
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
                              children: [
                                Icon(
                                  LucideIcons.timer,
                                  size: 14.sp,
                                  color: restDefaultSeconds > 0
                                      ? AppTheme.goldColor
                                      : WorkoutLogColors.mutedText(context),
                                ),
                                // فقط وقتی روشن است عدد نشان بده — «خاموش» گیج‌کننده بود
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
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999.r),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 4.h,
                    backgroundColor: WorkoutLogColors.pendingDot(
                      context,
                    ).withValues(alpha: 0.35),
                    color: done
                        ? WorkoutLogColors.successSolid(context)
                        : WorkoutLogColors.accent(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatShort(int seconds) {
    if (seconds % 60 == 0) return '${seconds ~/ 60}د';
    if (seconds < 60) return '$seconds ث';
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
