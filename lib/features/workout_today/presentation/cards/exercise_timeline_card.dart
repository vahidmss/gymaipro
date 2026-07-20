import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_speech_card.dart';

class ExerciseTimelineCard extends StatelessWidget {
  const ExerciseTimelineCard({required this.exercises, super.key});

  final List<WorkoutTodayExercise> exercises;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) return const SizedBox.shrink();

    return CoachSpeechCard(
      title: ProductCopy.exerciseTimeline,
      child: Column(
        children: <Widget>[
          for (var i = 0; i < exercises.length; i++) ...<Widget>[
            _ScrollableExerciseRow(exercise: exercises[i], index: i),
            if (i < exercises.length - 1)
              Divider(
                height: 8,
                thickness: 0.5,
                color: context.gymBorderSubtle,
              ),
          ],
        ],
      ),
    );
  }
}

class _ScrollableExerciseRow extends StatelessWidget {
  const _ScrollableExerciseRow({
    required this.exercise,
    required this.index,
  });

  final WorkoutTodayExercise exercise;
  final int index;

  @override
  Widget build(BuildContext context) {
    final name = ProductExperienceFormatter.displayExerciseName(
      name: exercise.name,
      primaryMuscle: exercise.primaryMuscle,
      orderIndex: index,
    );
    final meta = ProductExperienceFormatter.timelineSubtitle(exercise);
    final textStyle = context.gymTextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: context.gymTextPrimary,
    );
    final metaStyle = context.gymTextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: context.gymTextSecondary,
    );

    return SizedBox(
      height: 22,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 16,
            child: Text(
              '${index + 1}',
              style: context.gymTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.gymPrimary,
              ),
            ),
          ),
          GymSpacing.gapXs,
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: <Widget>[
                  Text(name, style: textStyle),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('·', style: metaStyle),
                  ),
                  Text(meta, style: metaStyle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
