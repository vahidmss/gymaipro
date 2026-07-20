import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';

/// Readable typography + spacing for Workout Today (AppTheme-aware).
extension WorkoutTodayTheme on BuildContext {
  TextStyle get wtGreeting => gymTextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  TextStyle get wtHeadline => gymTextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.45,
    color: gymTextSecondary,
  );

  TextStyle get wtSectionTitle => gymTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  TextStyle get wtMetricValue => gymTextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    height: 1.1,
  );

  TextStyle get wtMetricLabel => gymTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: gymTextSecondary,
  );

  TextStyle get wtBody => gymTextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.65,
  );

  TextStyle get wtBodyStrong => gymTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.45,
  );

  TextStyle get wtCaption => gymTextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: gymTextSecondary,
  );
}

class WorkoutTodaySectionHeader extends StatelessWidget {
  const WorkoutTodaySectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GymSpacing.md),
      child: Text(title, style: context.wtSectionTitle),
    );
  }
}
