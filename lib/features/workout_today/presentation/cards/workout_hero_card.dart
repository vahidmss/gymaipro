import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/animations/scale_in.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_progress_ring.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';

class WorkoutHeroCard extends StatelessWidget {
  const WorkoutHeroCard({
    required this.workout,
    required this.onStart,
    super.key,
  });

  final WorkoutTodayDomainModel workout;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GymScaleIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'سلام ${workout.userName} 👋',
            style: GymTypography.display,
          ),
          GymSpacing.gapMd,
          Text(
            workout.headline,
            style: GymTypography.headline.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          GymSpacing.gapXl,
          Wrap(
            spacing: GymSpacing.xl,
            runSpacing: GymSpacing.md,
            children: <Widget>[
              _HeroMetric(
                value: '${workout.exercises.length}',
                label: ProductCopy.exercisesCount,
              ),
              _HeroMetric(
                value: '${workout.durationMinutes}',
                label: ProductCopy.minutes,
              ),
              _HeroMetric(
                value: workout.intensity,
                label: ProductCopy.difficultyLabel,
              ),
            ],
          ),
          GymSpacing.gapXxl,
          GymButton(
            label: ProductCopy.startWorkout,
            fullWidth: true,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class WorkoutRecoveryRingCard extends StatelessWidget {
  const WorkoutRecoveryRingCard({required this.percent, super.key});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        GymProgressRing(
          value: percent / 100,
          label: '$percent٪',
          size: 88,
          color: GymColors.textPrimary,
        ),
        GymSpacing.gapLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(ProductCopy.recovery, style: GymTypography.title),
              GymSpacing.gapSm,
              Text(
                percent >= 70
                    ? 'بدنت برای تمرین امروز آماده است.'
                    : 'امروز بهتر است با شدت کنترل‌شده تمرین کنی.',
                style: GymTypography.body.copyWith(
                  fontSize: 15,
                  height: 1.6,
                  color: GymColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(value, style: GymTypography.metric),
        Text(
          label,
          style: GymTypography.caption.copyWith(color: GymColors.textTertiary),
        ),
      ],
    );
  }
}
