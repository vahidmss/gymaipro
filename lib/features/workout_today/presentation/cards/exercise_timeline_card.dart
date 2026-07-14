import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';

class ExerciseTimelineCard extends StatelessWidget {
  const ExerciseTimelineCard({required this.exercises, super.key});

  final List<WorkoutTodayExercise> exercises;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(ProductCopy.exerciseTimeline, style: GymTypography.title),
        GymSpacing.gapLg,
        for (var i = 0; i < exercises.length; i++)
          _TimelineItem(
            exercise: exercises[i],
            index: i,
            isLast: i == exercises.length - 1,
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.exercise,
    required this.index,
    required this.isLast,
  });

  final WorkoutTodayExercise exercise;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: GymSpacing.sm),
                decoration: BoxDecoration(
                  color: index.isEven
                      ? GymColors.textPrimary
                      : GymColors.neutral600,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: GymSpacing.xs),
                    color: GymColors.border,
                  ),
                ),
            ],
          ),
          GymSpacing.gapMd,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : GymSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(exercise.name, style: GymTypography.bodyStrong),
                  GymSpacing.gapXs,
                  Text(
                    ProductExperienceFormatter.timelineSubtitle(exercise),
                    style: GymTypography.caption,
                  ),
                  if (exercise.notes != null && exercise.notes!.trim().isNotEmpty) ...<Widget>[
                    GymSpacing.gapXs,
                    Text(
                      exercise.notes!,
                      style: GymTypography.caption.copyWith(
                        color: GymColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
