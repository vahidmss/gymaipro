import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_speech_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';

/// Compact coach note shown under an exercise after all sets are logged.
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

    final lines = feedback.lines;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 10.w : 12.w,
        compact ? 0 : 2.h,
        compact ? 10.w : 12.w,
        compact ? 10.h : 12.h,
      ),
      child: CoachSpeechCard(
        title: ProductCopy.coachTipTitle,
        avatarSize: compact ? 28 : 32,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10.w : 12.w,
          vertical: compact ? 8.h : 10.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var i = 0; i < lines.length; i++) ...<Widget>[
              if (i > 0) SizedBox(height: compact ? 4.h : 6.h),
              Text(
                lines[i],
                style: TextStyle(
                  fontSize: compact ? 11.5.sp : 12.5.sp,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? WorkoutLogColors.primaryText(context)
                      : AppTheme.lightTextColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
