import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_frequency_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_intensity_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_periodization_type.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_volume_strategy.dart';

/// Validation outcome for workout blueprints.
class WorkoutBlueprintValidation {
  const WorkoutBlueprintValidation({
    required this.isValid,
    required this.needsFollowUp,
    required this.issues,
    required this.followUpFields,
  });

  final bool isValid;
  final bool needsFollowUp;
  final List<String> issues;
  final List<String> followUpFields;
}

/// Validates blueprint completeness before generation.
class WorkoutBlueprintValidator {
  const WorkoutBlueprintValidator();

  WorkoutBlueprintValidation validate(WorkoutBlueprint blueprint) {
    final issues = <String>[];
    final followUp = <String>[];

    if (blueprint.goals.isEmpty && blueprint.goal == TrainingGoal.general) {
      issues.add('Goal is required.');
      followUp.add('goal');
    }

    if (blueprint.equipment.isEmpty) {
      issues.add('Equipment is required.');
      followUp.add('equipment');
    }

    if (!_isValidFrequency(blueprint.frequency)) {
      issues.add('Frequency is invalid.');
      followUp.add('workoutDays');
    }

    if (!_isValidVolume(blueprint.volume)) {
      issues.add('Volume strategy is invalid.');
    }

    if (!_isValidIntensity(blueprint.intensity)) {
      issues.add('Intensity strategy is invalid.');
    }

    if (!_isValidPeriodization(blueprint.periodization)) {
      issues.add('Periodization type is invalid.');
    }

    if (blueprint.experience.trim().isEmpty) {
      issues.add('Experience is required.');
      followUp.add('experience');
    }

    if (blueprint.maxSessionMinutes < 20) {
      issues.add('Session duration is too short.');
      followUp.add('workoutDuration');
    }

    if (blueprint.weeklySetsTarget <= 0) {
      issues.add('weeklySetsTarget must be positive.');
    }

    if (blueprint.exercisesPerSession < 2) {
      issues.add('exercisesPerSession must be at least 2.');
    }

    if (blueprint.daysPerWeek != blueprint.frequency.daysPerWeek) {
      issues.add('daysPerWeek must match frequency.');
      followUp.add('workoutDays');
    }

    final needsFollowUp = followUp.isNotEmpty;
    return WorkoutBlueprintValidation(
      isValid: issues.isEmpty,
      needsFollowUp: needsFollowUp,
      issues: List<String>.unmodifiable(issues),
      followUpFields: List<String>.unmodifiable(followUp),
    );
  }

  bool _isValidFrequency(WorkoutFrequencyStrategy frequency) {
    return WorkoutFrequencyStrategy.values.contains(frequency);
  }

  bool _isValidVolume(WorkoutVolumeStrategy volume) {
    return WorkoutVolumeStrategy.values.contains(volume);
  }

  bool _isValidIntensity(WorkoutIntensityStrategy intensity) {
    return WorkoutIntensityStrategy.values.contains(intensity);
  }

  bool _isValidPeriodization(WorkoutPeriodizationType periodization) {
    return WorkoutPeriodizationType.values.contains(periodization);
  }
}
