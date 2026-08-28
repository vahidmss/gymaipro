import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

class StartWorkoutCard extends StatelessWidget {
  const StartWorkoutCard({
    required this.hasWorkout,
    required this.onStart,
    required this.onBuildProgram,
    this.hasExistingAiPrograms = false,
    super.key,
  });

  final bool hasWorkout;
  final VoidCallback onStart;
  final VoidCallback onBuildProgram;

  /// True when Coach AI programs exist but none is active for today.
  final bool hasExistingAiPrograms;

  @override
  Widget build(BuildContext context) {
    if (hasWorkout) return const SizedBox.shrink();

    return GymEmptyState(
      title: hasExistingAiPrograms
          ? ProductCopy.existingAiProgramTitle
          : ProductCopy.emptyWorkoutTitle,
      message: hasExistingAiPrograms
          ? 'برنامه هوش مصنوعی داری؛ یکی را فعال کن یا از گزینه‌های مربی استفاده کن.'
          : ProductCopy.emptyWorkoutMessage,
      icon: GymIcons.calendar,
      actionLabel: hasExistingAiPrograms
          ? ProductCopy.manageAiProgramOrbit
          : ProductCopy.buildProgram,
      onAction: onBuildProgram,
    );
  }
}
