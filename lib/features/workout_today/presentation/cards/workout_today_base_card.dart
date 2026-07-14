import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';

/// Shared card wrapper for Workout Today sections.
class WorkoutTodayBaseCard extends StatelessWidget {
  const WorkoutTodayBaseCard({
    required this.child,
    this.variant = GymCardVariant.insight,
    super.key,
  });

  final Widget child;
  final GymCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return GymCard(variant: variant, child: child);
  }
}
