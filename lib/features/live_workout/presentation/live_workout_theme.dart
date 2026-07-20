import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';

/// Readable typography for Live Workout (AppTheme-aware).
extension LiveWorkoutTheme on BuildContext {
  TextStyle get lwTitle => gymTextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  TextStyle get lwExerciseName => gymTextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 1.2,
  );

  TextStyle get lwSection => gymTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  TextStyle get lwBody => gymTextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );

  TextStyle get lwBodyStrong => gymTextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.45,
  );

  TextStyle get lwCaption => gymTextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: gymTextSecondary,
  );

  TextStyle get lwMetric => gymTextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    height: 1.1,
  );
}

class LiveWorkoutSectionHeader extends StatelessWidget {
  const LiveWorkoutSectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GymSpacing.md),
      child: Text(title, style: context.lwSection),
    );
  }
}
