import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_recovery_strategy.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';

/// Validation outcome for generated programs.
class WorkoutProgramValidation {
  const WorkoutProgramValidation({
    required this.isValid,
    required this.issues,
  });

  final bool isValid;
  final List<String> issues;
}

/// Validates generated workout programs before returning them.
class WorkoutProgramValidator {
  const WorkoutProgramValidator();

  WorkoutProgramValidation validate({
    required WorkoutProgram program,
    required WorkoutBlueprint blueprint,
  }) {
    final issues = <String>[];

    if (program.weeks.isEmpty || program.allDays.isEmpty) {
      issues.add('Program has no training days.');
    }

    final exerciseIds = <int>{};
    final muscleHits = <MuscleBucket, int>{};

    for (final day in program.allDays) {
      if (day.exercises.isEmpty) {
        issues.add('Day ${day.label} has no exercises.');
      }
      final dayIds = <int>{};
      for (final exercise in day.exercises) {
        if (!exerciseIds.add(exercise.catalogExerciseId)) {
          issues.add('Duplicate exercise ${exercise.name} across program.');
        }
        if (!dayIds.add(exercise.catalogExerciseId)) {
          issues.add('Duplicate muscle focus in ${day.label}: ${exercise.name}');
        }
        final bucket = WorkoutScience.muscleBucket(exercise.primaryMuscle);
        muscleHits[bucket] = (muscleHits[bucket] ?? 0) + 1;
      }
    }

    if (WorkoutScience.isBeginnerExperience(blueprint.experience) &&
        program.totalExercises > blueprint.daysPerWeek * 6) {
      issues.add('Beginner program volume is too high.');
    }
    if (WorkoutScience.isAdvancedExperience(blueprint.experience) &&
        program.totalExercises < blueprint.daysPerWeek * 2) {
      issues.add('Advanced program volume is too low.');
    }
    if (blueprint.recoveryStrategy == WorkoutRecoveryStrategy.conservative) {
      final legHits = (muscleHits[MuscleBucket.quads] ?? 0) +
          (muscleHits[MuscleBucket.hamstrings] ?? 0);
      if (legHits > blueprint.daysPerWeek) {
        issues.add('Recovery constraint violated: too much leg volume.');
      }
    }

    for (final avoid in blueprint.avoidExercises) {
      final token = avoid.toLowerCase();
      for (final day in program.allDays) {
        for (final exercise in day.exercises) {
          if (exercise.name.toLowerCase().contains(token)) {
            issues.add('Avoided exercise present: ${exercise.name}');
          }
        }
      }
    }

    return WorkoutProgramValidation(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }
}
