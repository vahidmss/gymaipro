import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_metric_tile.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';

/// Compact workout stats row — visual variety vs hero.
class WorkoutSummaryCard extends StatelessWidget {
  const WorkoutSummaryCard({required this.workout, super.key});

  final WorkoutTodayDomainModel workout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          ProductCopy.workoutSummary,
          style: GymTypography.caption.copyWith(
            color: GymColors.textTertiary,
          ),
        ),
        GymSpacing.gapMd,
        Row(
          children: <Widget>[
            Expanded(
              child: GymMetricTile(
                title: 'ست کل',
                value: '${workout.totalSets}',
                compact: true,
                icon: GymIcons.activity,
              ),
            ),
            GymSpacing.gapMd,
            Expanded(
              child: GymMetricTile(
                title: ProductCopy.exercisesCount,
                value: '${workout.exercises.length}',
                compact: true,
                icon: GymIcons.workout,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
