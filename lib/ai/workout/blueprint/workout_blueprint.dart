import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_reason.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_trace.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_versions.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_exercise_complexity.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_exercise_replacement_policy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_frequency_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_intensity_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_periodization_type.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_recovery_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_split_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_training_style.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_volume_strategy.dart';
import 'package:gymaipro/ai/workout/models/workout_progression.dart';

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const <String, Object?>{};
}

/// Immutable high-level workout plan decided before generation.
///
/// Data-only model. No business logic or derived decisions.
class WorkoutBlueprint {
  const WorkoutBlueprint({
    required this.goal,
    required this.experience,
    required this.daysPerWeek,
    required this.splitStrategy,
    required this.frequency,
    required this.volume,
    required this.intensity,
    required this.periodization,
    required this.recoveryStrategy,
    required this.equipment,
    required this.limitations,
    required this.preferredMuscles,
    required this.avoidExercises,
    required this.preferredExercises,
    required this.weeklySetsTarget,
    required this.maxSessionMinutes,
    required this.minRecoveryHours,
    required this.preferredExerciseComplexity,
    required this.exerciseReplacementPolicy,
    required this.deloadFrequencyWeeks,
    required this.progressionStrategy,
    required this.trainingStyle,
    required this.exercisesPerSession,
    required this.confidence,
    required this.reasons,
    required this.trace,
    this.schemaVersion = WorkoutBlueprintVersions.schemaVersion,
    this.builderVersion = WorkoutBlueprintVersions.builderVersion,
    this.createdBy = WorkoutBlueprintVersions.createdBy,
    this.planningEngineVersion = WorkoutBlueprintVersions.planningEngineVersion,
    this.userId,
    this.goals = const <String>[],
    this.entitlementAllowed = true,
    this.varietySeed,
  });

  factory WorkoutBlueprint.fromJson(Map<String, Object?> json) {
    final traceRaw = json['trace'];
    return WorkoutBlueprint(
      goal: TrainingGoal.values.firstWhere(
        (value) => value.name == json['goal'],
        orElse: () => TrainingGoal.general,
      ),
      experience: (json['experience'] as String?) ?? 'متوسط',
      daysPerWeek: (json['daysPerWeek'] as int?) ?? 3,
      splitStrategy: WorkoutSplitStrategy.values.firstWhere(
        (value) => value.name == json['splitStrategy'],
        orElse: () => WorkoutSplitStrategy.pushPullLegs,
      ),
      frequency: WorkoutFrequencyStrategy.values.firstWhere(
        (value) => value.name == json['frequency'],
        orElse: () => WorkoutFrequencyStrategy.three,
      ),
      volume: WorkoutVolumeStrategy.values.firstWhere(
        (value) => value.name == json['volume'],
        orElse: () => WorkoutVolumeStrategy.medium,
      ),
      intensity: WorkoutIntensityStrategy.values.firstWhere(
        (value) => value.name == json['intensity'],
        orElse: () => WorkoutIntensityStrategy.moderate,
      ),
      periodization: WorkoutPeriodizationType.values.firstWhere(
        (value) => value.name == json['periodization'],
        orElse: () => WorkoutPeriodizationType.linear,
      ),
      recoveryStrategy: WorkoutRecoveryStrategy.values.firstWhere(
        (value) => value.name == json['recoveryStrategy'],
        orElse: () => WorkoutRecoveryStrategy.normal,
      ),
      equipment: (json['equipment'] as List<Object?>? ?? const <Object?>[])
          .map((item) => item.toString())
          .toList(),
      limitations: (json['limitations'] as List<Object?>? ?? const <Object?>[])
          .map((item) => item.toString())
          .toList(),
      preferredMuscles:
          (json['preferredMuscles'] as List<Object?>? ?? const <Object?>[])
              .map((item) => item.toString())
              .toList(),
      avoidExercises:
          (json['avoidExercises'] as List<Object?>? ?? const <Object?>[])
              .map((item) => item.toString())
              .toList(),
      preferredExercises:
          (json['preferredExercises'] as List<Object?>? ?? const <Object?>[])
              .map((item) => item.toString())
              .toList(),
      weeklySetsTarget:
          (json['weeklySetsTarget'] as int?) ??
          (json['estimatedWeeklyVolume'] as int?) ??
          0,
      maxSessionMinutes:
          (json['maxSessionMinutes'] as int?) ??
          (json['estimatedSessionDuration'] as int?) ??
          60,
      minRecoveryHours: (json['minRecoveryHours'] as int?) ?? 24,
      preferredExerciseComplexity:
          WorkoutExerciseComplexity.values.firstWhere(
            (value) => value.name == json['preferredExerciseComplexity'],
            orElse: () => WorkoutExerciseComplexity.moderate,
          ),
      exerciseReplacementPolicy:
          WorkoutExerciseReplacementPolicy.values.firstWhere(
            (value) => value.name == json['exerciseReplacementPolicy'],
            orElse: () => WorkoutExerciseReplacementPolicy.substitute,
          ),
      deloadFrequencyWeeks: (json['deloadFrequencyWeeks'] as int?) ?? 4,
      progressionStrategy: WorkoutProgressionStrategy.values.firstWhere(
        (value) => value.name == json['progressionStrategy'],
        orElse: () => WorkoutProgressionStrategy.maintenance,
      ),
      trainingStyle: WorkoutTrainingStyle.values.firstWhere(
        (value) => value.name == json['trainingStyle'],
        orElse: () => WorkoutTrainingStyle.generalFitness,
      ),
      exercisesPerSession: (json['exercisesPerSession'] as int?) ?? 4,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      reasons: (json['reasons'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map((item) => WorkoutBlueprintReason.fromJson(_mapFromJson(item)))
          .toList(),
      trace: traceRaw is Map
          ? WorkoutBlueprintTrace.fromJson(_mapFromJson(traceRaw))
          : const WorkoutBlueprintTrace(steps: <String>[], recoveryScore: 1),
      schemaVersion:
          (json['schemaVersion'] as String?) ??
          WorkoutBlueprintVersions.schemaVersion,
      builderVersion:
          (json['builderVersion'] as String?) ??
          WorkoutBlueprintVersions.builderVersion,
      createdBy:
          (json['createdBy'] as String?) ?? WorkoutBlueprintVersions.createdBy,
      planningEngineVersion:
          (json['planningEngineVersion'] as String?) ??
          WorkoutBlueprintVersions.planningEngineVersion,
      userId: json['userId'] as String?,
      goals: (json['goals'] as List<Object?>? ?? const <Object?>[])
          .map((item) => item.toString())
          .toList(),
      entitlementAllowed: json['entitlementAllowed'] as bool? ?? true,
      varietySeed: json['varietySeed'] as int?,
    );
  }

  final TrainingGoal goal;
  final String experience;
  final int daysPerWeek;
  final WorkoutSplitStrategy splitStrategy;
  final WorkoutFrequencyStrategy frequency;
  final WorkoutVolumeStrategy volume;
  final WorkoutIntensityStrategy intensity;
  final WorkoutPeriodizationType periodization;
  final WorkoutRecoveryStrategy recoveryStrategy;
  final List<String> equipment;
  final List<String> limitations;
  final List<String> preferredMuscles;
  final List<String> avoidExercises;
  final List<String> preferredExercises;
  final int weeklySetsTarget;
  final int maxSessionMinutes;
  final int minRecoveryHours;
  final WorkoutExerciseComplexity preferredExerciseComplexity;
  final WorkoutExerciseReplacementPolicy exerciseReplacementPolicy;
  final int deloadFrequencyWeeks;
  final WorkoutProgressionStrategy progressionStrategy;
  final WorkoutTrainingStyle trainingStyle;
  final int exercisesPerSession;
  final double confidence;
  final List<WorkoutBlueprintReason> reasons;
  final WorkoutBlueprintTrace trace;
  final String schemaVersion;
  final String builderVersion;
  final String createdBy;
  final String planningEngineVersion;
  final String? userId;
  final List<String> goals;
  final bool entitlementAllowed;
  final int? varietySeed;

  Map<String, Object?> toJson() => <String, Object?>{
    'goal': goal.name,
    'experience': experience,
    'daysPerWeek': daysPerWeek,
    'splitStrategy': splitStrategy.name,
    'frequency': frequency.name,
    'volume': volume.name,
    'intensity': intensity.name,
    'periodization': periodization.name,
    'recoveryStrategy': recoveryStrategy.name,
    'equipment': equipment,
    'limitations': limitations,
    'preferredMuscles': preferredMuscles,
    'avoidExercises': avoidExercises,
    'preferredExercises': preferredExercises,
    'weeklySetsTarget': weeklySetsTarget,
    'maxSessionMinutes': maxSessionMinutes,
    'minRecoveryHours': minRecoveryHours,
    'preferredExerciseComplexity': preferredExerciseComplexity.name,
    'exerciseReplacementPolicy': exerciseReplacementPolicy.name,
    'deloadFrequencyWeeks': deloadFrequencyWeeks,
    'progressionStrategy': progressionStrategy.name,
    'trainingStyle': trainingStyle.name,
    'exercisesPerSession': exercisesPerSession,
    'confidence': confidence,
    'reasons': reasons.map((reason) => reason.toJson()).toList(),
    'trace': trace.toJson(),
    'schemaVersion': schemaVersion,
    'builderVersion': builderVersion,
    'createdBy': createdBy,
    'planningEngineVersion': planningEngineVersion,
    if (userId != null) 'userId': userId,
    'goals': goals,
    'entitlementAllowed': entitlementAllowed,
    if (varietySeed != null) 'varietySeed': varietySeed,
  };

  WorkoutBlueprint copyWith({
    TrainingGoal? goal,
    String? experience,
    int? daysPerWeek,
    WorkoutSplitStrategy? splitStrategy,
    WorkoutFrequencyStrategy? frequency,
    WorkoutVolumeStrategy? volume,
    WorkoutIntensityStrategy? intensity,
    WorkoutPeriodizationType? periodization,
    WorkoutRecoveryStrategy? recoveryStrategy,
    List<String>? equipment,
    List<String>? limitations,
    List<String>? preferredMuscles,
    List<String>? avoidExercises,
    List<String>? preferredExercises,
    int? weeklySetsTarget,
    int? maxSessionMinutes,
    int? minRecoveryHours,
    WorkoutExerciseComplexity? preferredExerciseComplexity,
    WorkoutExerciseReplacementPolicy? exerciseReplacementPolicy,
    int? deloadFrequencyWeeks,
    WorkoutProgressionStrategy? progressionStrategy,
    WorkoutTrainingStyle? trainingStyle,
    int? exercisesPerSession,
    double? confidence,
    List<WorkoutBlueprintReason>? reasons,
    WorkoutBlueprintTrace? trace,
    String? schemaVersion,
    String? builderVersion,
    String? createdBy,
    String? planningEngineVersion,
    String? userId,
    List<String>? goals,
    bool? entitlementAllowed,
    int? varietySeed,
  }) {
    return WorkoutBlueprint(
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      splitStrategy: splitStrategy ?? this.splitStrategy,
      frequency: frequency ?? this.frequency,
      volume: volume ?? this.volume,
      intensity: intensity ?? this.intensity,
      periodization: periodization ?? this.periodization,
      recoveryStrategy: recoveryStrategy ?? this.recoveryStrategy,
      equipment: equipment ?? this.equipment,
      limitations: limitations ?? this.limitations,
      preferredMuscles: preferredMuscles ?? this.preferredMuscles,
      avoidExercises: avoidExercises ?? this.avoidExercises,
      preferredExercises: preferredExercises ?? this.preferredExercises,
      weeklySetsTarget: weeklySetsTarget ?? this.weeklySetsTarget,
      maxSessionMinutes: maxSessionMinutes ?? this.maxSessionMinutes,
      minRecoveryHours: minRecoveryHours ?? this.minRecoveryHours,
      preferredExerciseComplexity:
          preferredExerciseComplexity ?? this.preferredExerciseComplexity,
      exerciseReplacementPolicy:
          exerciseReplacementPolicy ?? this.exerciseReplacementPolicy,
      deloadFrequencyWeeks: deloadFrequencyWeeks ?? this.deloadFrequencyWeeks,
      progressionStrategy: progressionStrategy ?? this.progressionStrategy,
      trainingStyle: trainingStyle ?? this.trainingStyle,
      exercisesPerSession: exercisesPerSession ?? this.exercisesPerSession,
      confidence: confidence ?? this.confidence,
      reasons: reasons ?? this.reasons,
      trace: trace ?? this.trace,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      builderVersion: builderVersion ?? this.builderVersion,
      createdBy: createdBy ?? this.createdBy,
      planningEngineVersion:
          planningEngineVersion ?? this.planningEngineVersion,
      userId: userId ?? this.userId,
      goals: goals ?? this.goals,
      entitlementAllowed: entitlementAllowed ?? this.entitlementAllowed,
      varietySeed: varietySeed ?? this.varietySeed,
    );
  }
}

/// Result of blueprint planning before generation.
class WorkoutBlueprintResult {
  const WorkoutBlueprintResult({
    this.blueprint,
    this.needsFollowUp = false,
    this.entitlementBlocked = false,
    this.followUpFields = const <String>[],
    this.reasons = const <WorkoutBlueprintReason>[],
    this.message,
  });

  final WorkoutBlueprint? blueprint;
  final bool needsFollowUp;
  final bool entitlementBlocked;
  final List<String> followUpFields;
  final List<WorkoutBlueprintReason> reasons;
  final String? message;

  WorkoutBlueprintResult copyWith({
    WorkoutBlueprint? blueprint,
    bool? needsFollowUp,
    bool? entitlementBlocked,
    List<String>? followUpFields,
    List<WorkoutBlueprintReason>? reasons,
    String? message,
  }) {
    return WorkoutBlueprintResult(
      blueprint: blueprint ?? this.blueprint,
      needsFollowUp: needsFollowUp ?? this.needsFollowUp,
      entitlementBlocked: entitlementBlocked ?? this.entitlementBlocked,
      followUpFields: followUpFields ?? this.followUpFields,
      reasons: reasons ?? this.reasons,
      message: message ?? this.message,
    );
  }
}
