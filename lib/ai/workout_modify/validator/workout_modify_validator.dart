import 'package:gymaipro/ai/workout/models/workout_program.dart';

/// Validation outcome for modified workout programs.
class WorkoutModifyValidation {
  const WorkoutModifyValidation({
    required this.isValid,
    required this.issues,
  });

  final bool isValid;
  final List<String> issues;
}

/// Validates modified programs before returning them.
class WorkoutModifyValidator {
  const WorkoutModifyValidator();

  WorkoutModifyValidation validate({
    required WorkoutProgram original,
    required WorkoutProgram modified,
  }) {
    final issues = <String>[];

    if (modified.weeks.isEmpty || modified.allDays.isEmpty) {
      issues.add('Modified program has no training days.');
    }

    for (final day in modified.allDays) {
      if (day.exercises.isEmpty) {
        issues.add('Day ${day.label} has no exercises after modification.');
      }
    }

    if (modified.totalExercises == 0) {
      issues.add('Modified program has zero exercises.');
    }

    if (modified.id != original.id) {
      issues.add('Program id changed during modification.');
    }

    return WorkoutModifyValidation(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }
}
