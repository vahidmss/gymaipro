import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/animations/scale_in.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_speech_card.dart';
import 'package:gymaipro/features/workout_today/presentation/workout_today_theme.dart';

class WorkoutHeroCard extends StatelessWidget {
  const WorkoutHeroCard({
    required this.workout,
    super.key,
  });

  final WorkoutTodayDomainModel workout;

  @override
  Widget build(BuildContext context) {
    return GymScaleIn(
      child: CoachSpeechCard(
        avatarSize: 44,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'سلام ${workout.userName}',
              style: context.gymTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              workout.headline,
              style: context.gymTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: context.gymTextSecondary,
              ),
            ),
            GymSpacing.gapSm,
            Text(
              '${workout.exercises.length} ${ProductCopy.exercisesCount}'
              '  ·  ${workout.durationMinutes} ${ProductCopy.minutes}'
              '  ·  ${workout.totalSets} ست',
              style: context.wtCaption.copyWith(fontSize: 11),
            ),
            if (workout.readinessHint.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                workout.readinessHint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.wtCaption.copyWith(fontSize: 11, height: 1.3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
