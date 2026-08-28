import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/features/product_experience/domain/exercise_coach_decision.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_speech_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';

/// Decision Card shown under an exercise after all sets are logged.
class WorkoutExerciseCoachFeedbackCard extends StatelessWidget {
  const WorkoutExerciseCoachFeedbackCard({
    required this.feedback,
    this.compact = false,
    super.key,
  });

  final WorkoutExerciseCoachFeedback feedback;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (feedback.isEmpty) return const SizedBox.shrink();

    final decision = feedback.decision;
    final lines = feedback.lines;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark
        ? WorkoutLogColors.primaryText(context)
        : AppTheme.lightTextColor;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 10.w : 12.w,
        compact ? 0 : 2.h,
        compact ? 10.w : 12.w,
        compact ? 10.h : 12.h,
      ),
      child: CoachSpeechCard(
        title: ProductCopy.decisionCardTitle,
        avatarSize: compact ? 28 : 32,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10.w : 12.w,
          vertical: compact ? 8.h : 10.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (decision != null) ...<Widget>[
              Wrap(
                spacing: 6.w,
                runSpacing: 4.h,
                children: <Widget>[
                  _DecisionChip(
                    label: decision.badgeLabel,
                    emphasized: decision.action == ExerciseCoachAction.increase ||
                        decision.action == ExerciseCoachAction.bridge,
                    compact: compact,
                  ),
                  if (decision.targetLine != null)
                    _DecisionChip(
                      label: decision.targetLine!,
                      emphasized: false,
                      compact: compact,
                    ),
                ],
              ),
              SizedBox(height: compact ? 6.h : 8.h),
            ],
            for (var i = 0; i < lines.length; i++) ...<Widget>[
              if (i > 0) SizedBox(height: compact ? 4.h : 6.h),
              Text(
                lines[i],
                style: TextStyle(
                  fontSize: compact ? 11.5.sp : 12.5.sp,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: bodyColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DecisionChip extends StatelessWidget {
  const _DecisionChip({
    required this.label,
    required this.emphasized,
    required this.compact,
  });

  final String label;
  final bool emphasized;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = emphasized
        ? AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.16)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));
    final fg = emphasized
        ? (isDark ? AppTheme.goldColor : AppTheme.goldColor.withValues(alpha: 0.95))
        : (isDark
            ? WorkoutLogColors.primaryText(context)
            : AppTheme.lightTextColor);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8.w : 10.w,
        vertical: compact ? 3.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10.5.sp : 11.5.sp,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
