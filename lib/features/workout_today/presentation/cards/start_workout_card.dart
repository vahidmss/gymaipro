import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

class StartWorkoutCard extends StatelessWidget {
  const StartWorkoutCard({
    required this.hasWorkout,
    required this.onStart,
    required this.onBuildProgram,
    super.key,
  });

  final bool hasWorkout;
  final VoidCallback onStart;
  final VoidCallback onBuildProgram;

  @override
  Widget build(BuildContext context) {
    if (hasWorkout) return const SizedBox.shrink();

    return GymEmptyState(
      title: ProductCopy.emptyWorkoutTitle,
      message: ProductCopy.emptyWorkoutMessage,
      icon: GymIcons.calendar,
      actionLabel: ProductCopy.buildProgram,
      onAction: onBuildProgram,
    );
  }
}
