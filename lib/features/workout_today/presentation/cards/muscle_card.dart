import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_chip.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_speech_card.dart';

class MuscleCard extends StatelessWidget {
  const MuscleCard({required this.muscles, super.key});

  final List<String> muscles;

  @override
  Widget build(BuildContext context) {
    if (muscles.isEmpty) return const SizedBox.shrink();

    return CoachSpeechCard(
      title: 'عضلات هدف',
      child: Wrap(
        spacing: GymSpacing.xs,
        runSpacing: GymSpacing.xs,
        children: muscles
            .take(6)
            .map(
              (muscle) => GymChip(
                label: muscle,
                variant: GymChipVariant.filled,
                selected: true,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
