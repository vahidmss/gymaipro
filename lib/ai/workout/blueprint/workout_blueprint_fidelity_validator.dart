import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_recovery_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_split_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_volume_strategy.dart';

/// Validation outcome when a blueprint cannot be executed faithfully.
class WorkoutBlueprintFidelityValidation {
  const WorkoutBlueprintFidelityValidation({
    required this.isValid,
    required this.issues,
  });

  final bool isValid;
  final List<String> issues;
}

/// Ensures the generator can execute a blueprint without overriding decisions.
class WorkoutBlueprintFidelityValidator {
  const WorkoutBlueprintFidelityValidator();

  WorkoutBlueprintFidelityValidation validate(WorkoutBlueprint blueprint) {
    final issues = <String>[];

    if (blueprint.daysPerWeek != blueprint.frequency.daysPerWeek) {
      issues.add(
        'Frequency conflict: daysPerWeek=${blueprint.daysPerWeek} '
        'but frequency=${blueprint.frequency.daysPerWeek}.',
      );
    }

    if (blueprint.maxSessionMinutes < 20) {
      issues.add('maxSessionMinutes must be at least 20.');
    }

    if (blueprint.exercisesPerSession < 2) {
      issues.add('exercisesPerSession must be at least 2.');
    }

    if (blueprint.weeklySetsTarget <= 0) {
      issues.add('weeklySetsTarget must be positive.');
    }

    if (_isSplitFrequencyConflict(blueprint)) {
      issues.add(
        'Split conflict: ${blueprint.splitStrategy.name} is incompatible '
        'with ${blueprint.frequency.daysPerWeek} training days.',
      );
    }

    if (_isRecoveryConflict(blueprint)) {
      issues.add(
        'Recovery conflict: ${blueprint.recoveryStrategy.name} recovery '
        'cannot support ${blueprint.volume.name} volume.',
      );
    }

    return WorkoutBlueprintFidelityValidation(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }

  bool _isSplitFrequencyConflict(WorkoutBlueprint blueprint) {
    final days = blueprint.frequency.daysPerWeek;
    return switch (blueprint.splitStrategy) {
      WorkoutSplitStrategy.phat => days < 5,
      WorkoutSplitStrategy.phul => days != 4,
      WorkoutSplitStrategy.broSplit => days < 4,
      WorkoutSplitStrategy.pushPullLegs => days < 3,
      WorkoutSplitStrategy.upperLower => days < 4,
      WorkoutSplitStrategy.fullBody => days < 2,
      WorkoutSplitStrategy.custom => false,
    };
  }

  bool _isRecoveryConflict(WorkoutBlueprint blueprint) {
    if (blueprint.recoveryStrategy != WorkoutRecoveryStrategy.conservative) {
      return false;
    }
    return blueprint.volume == WorkoutVolumeStrategy.veryHigh ||
        blueprint.volume == WorkoutVolumeStrategy.high;
  }
}
