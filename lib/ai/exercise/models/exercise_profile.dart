import 'package:gymaipro/ai/exercise/models/exercise_intelligence_enums.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_versions.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';

/// Immutable intelligence profile for a single exercise.
///
/// Data-only model. No business logic.
class ExerciseProfile {
  const ExerciseProfile({
    required this.id,
    required this.slug,
    required this.canonicalName,
    this.aliases = const <String>[],
    this.primaryMuscles = const <String>[],
    this.secondaryMuscles = const <String>[],
    this.movementPattern = ExerciseMovementPattern.other,
    this.movementType = ExerciseMovementType.compound,
    this.equipment = const <ExerciseEquipmentType>[],
    this.difficulty = ExerciseDifficultyLevel.intermediate,
    this.fatigueScore = 0.5,
    this.stimulusScore = 0.5,
    this.injuryRisk = 0.3,
    this.stabilityRequirement = 0.5,
    this.executionComplexity = 0.5,
    this.recoveryCost = 0.5,
    this.preferredGoals = const <TrainingGoal>[],
    this.experienceLevel = ExerciseExperienceLevel.beginner,
    this.jointStress = ExerciseJointStressLevel.low,
    this.spineLoad = 0,
    this.shoulderLoad = 0,
    this.kneeLoad = 0,
    this.hipLoad = 0,
    this.elbowLoad = 0,
    this.wristLoad = 0,
    this.gripType = ExerciseGripType.none,
    this.unilateral = false,
    this.compound = true,
    this.isolation = false,
    this.warmupRecommended = false,
    this.defaultTempo = '',
    this.notes = const <String>[],
    this.version = ExerciseIntelligenceVersions.profileSchemaVersion,
  });

  factory ExerciseProfile.fromJson(Map<String, Object?> json) {
    return ExerciseProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: (json['slug'] as String?) ?? '',
      canonicalName: (json['canonicalName'] as String?) ?? '',
      aliases: _stringList(json['aliases']),
      primaryMuscles: _stringList(json['primaryMuscles']),
      secondaryMuscles: _stringList(json['secondaryMuscles']),
      movementPattern: _enumByName(
        ExerciseMovementPattern.values,
        json['movementPattern'] as String?,
        ExerciseMovementPattern.other,
      ),
      movementType: _enumByName(
        ExerciseMovementType.values,
        json['movementType'] as String?,
        ExerciseMovementType.compound,
      ),
      equipment: _equipmentList(json['equipment']),
      difficulty: _enumByName(
        ExerciseDifficultyLevel.values,
        json['difficulty'] as String?,
        ExerciseDifficultyLevel.intermediate,
      ),
      fatigueScore: (json['fatigueScore'] as num?)?.toDouble() ?? 0.5,
      stimulusScore: (json['stimulusScore'] as num?)?.toDouble() ?? 0.5,
      injuryRisk: (json['injuryRisk'] as num?)?.toDouble() ?? 0.3,
      stabilityRequirement:
          (json['stabilityRequirement'] as num?)?.toDouble() ?? 0.5,
      executionComplexity:
          (json['executionComplexity'] as num?)?.toDouble() ?? 0.5,
      recoveryCost: (json['recoveryCost'] as num?)?.toDouble() ?? 0.5,
      preferredGoals: _goalList(json['preferredGoals']),
      experienceLevel: _enumByName(
        ExerciseExperienceLevel.values,
        json['experienceLevel'] as String?,
        ExerciseExperienceLevel.beginner,
      ),
      jointStress: _enumByName(
        ExerciseJointStressLevel.values,
        json['jointStress'] as String?,
        ExerciseJointStressLevel.low,
      ),
      spineLoad: (json['spineLoad'] as num?)?.toDouble() ?? 0,
      shoulderLoad: (json['shoulderLoad'] as num?)?.toDouble() ?? 0,
      kneeLoad: (json['kneeLoad'] as num?)?.toDouble() ?? 0,
      hipLoad: (json['hipLoad'] as num?)?.toDouble() ?? 0,
      elbowLoad: (json['elbowLoad'] as num?)?.toDouble() ?? 0,
      wristLoad: (json['wristLoad'] as num?)?.toDouble() ?? 0,
      gripType: _enumByName(
        ExerciseGripType.values,
        json['gripType'] as String?,
        ExerciseGripType.none,
      ),
      unilateral: json['unilateral'] as bool? ?? false,
      compound: json['compound'] as bool? ?? true,
      isolation: json['isolation'] as bool? ?? false,
      warmupRecommended: json['warmupRecommended'] as bool? ?? false,
      defaultTempo: (json['defaultTempo'] as String?) ?? '',
      notes: _stringList(json['notes']),
      version:
          (json['version'] as String?) ??
          ExerciseIntelligenceVersions.profileSchemaVersion,
    );
  }

  final int id;
  final String slug;
  final String canonicalName;
  final List<String> aliases;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final ExerciseMovementPattern movementPattern;
  final ExerciseMovementType movementType;
  final List<ExerciseEquipmentType> equipment;
  final ExerciseDifficultyLevel difficulty;
  final double fatigueScore;
  final double stimulusScore;
  final double injuryRisk;
  final double stabilityRequirement;
  final double executionComplexity;
  final double recoveryCost;
  final List<TrainingGoal> preferredGoals;
  final ExerciseExperienceLevel experienceLevel;
  final ExerciseJointStressLevel jointStress;
  final double spineLoad;
  final double shoulderLoad;
  final double kneeLoad;
  final double hipLoad;
  final double elbowLoad;
  final double wristLoad;
  final ExerciseGripType gripType;
  final bool unilateral;
  final bool compound;
  final bool isolation;
  final bool warmupRecommended;
  final String defaultTempo;
  final List<String> notes;
  final String version;

  Iterable<String> get searchableNames sync* {
    yield canonicalName;
    for (final alias in aliases) {
      yield alias;
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'slug': slug,
    'canonicalName': canonicalName,
    'aliases': aliases,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'movementPattern': movementPattern.name,
    'movementType': movementType.name,
    'equipment': equipment.map((item) => item.name).toList(),
    'difficulty': difficulty.name,
    'fatigueScore': fatigueScore,
    'stimulusScore': stimulusScore,
    'injuryRisk': injuryRisk,
    'stabilityRequirement': stabilityRequirement,
    'executionComplexity': executionComplexity,
    'recoveryCost': recoveryCost,
    'preferredGoals': preferredGoals.map((goal) => goal.name).toList(),
    'experienceLevel': experienceLevel.name,
    'jointStress': jointStress.name,
    'spineLoad': spineLoad,
    'shoulderLoad': shoulderLoad,
    'kneeLoad': kneeLoad,
    'hipLoad': hipLoad,
    'elbowLoad': elbowLoad,
    'wristLoad': wristLoad,
    'gripType': gripType.name,
    'unilateral': unilateral,
    'compound': compound,
    'isolation': isolation,
    'warmupRecommended': warmupRecommended,
    'defaultTempo': defaultTempo,
    'notes': notes,
    'version': version,
  };

  ExerciseProfile copyWith({
    int? id,
    String? slug,
    String? canonicalName,
    List<String>? aliases,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    ExerciseMovementPattern? movementPattern,
    ExerciseMovementType? movementType,
    List<ExerciseEquipmentType>? equipment,
    ExerciseDifficultyLevel? difficulty,
    double? fatigueScore,
    double? stimulusScore,
    double? injuryRisk,
    double? stabilityRequirement,
    double? executionComplexity,
    double? recoveryCost,
    List<TrainingGoal>? preferredGoals,
    ExerciseExperienceLevel? experienceLevel,
    ExerciseJointStressLevel? jointStress,
    double? spineLoad,
    double? shoulderLoad,
    double? kneeLoad,
    double? hipLoad,
    double? elbowLoad,
    double? wristLoad,
    ExerciseGripType? gripType,
    bool? unilateral,
    bool? compound,
    bool? isolation,
    bool? warmupRecommended,
    String? defaultTempo,
    List<String>? notes,
    String? version,
  }) {
    return ExerciseProfile(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      canonicalName: canonicalName ?? this.canonicalName,
      aliases: aliases ?? this.aliases,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      movementPattern: movementPattern ?? this.movementPattern,
      movementType: movementType ?? this.movementType,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      fatigueScore: fatigueScore ?? this.fatigueScore,
      stimulusScore: stimulusScore ?? this.stimulusScore,
      injuryRisk: injuryRisk ?? this.injuryRisk,
      stabilityRequirement: stabilityRequirement ?? this.stabilityRequirement,
      executionComplexity: executionComplexity ?? this.executionComplexity,
      recoveryCost: recoveryCost ?? this.recoveryCost,
      preferredGoals: preferredGoals ?? this.preferredGoals,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      jointStress: jointStress ?? this.jointStress,
      spineLoad: spineLoad ?? this.spineLoad,
      shoulderLoad: shoulderLoad ?? this.shoulderLoad,
      kneeLoad: kneeLoad ?? this.kneeLoad,
      hipLoad: hipLoad ?? this.hipLoad,
      elbowLoad: elbowLoad ?? this.elbowLoad,
      wristLoad: wristLoad ?? this.wristLoad,
      gripType: gripType ?? this.gripType,
      unilateral: unilateral ?? this.unilateral,
      compound: compound ?? this.compound,
      isolation: isolation ?? this.isolation,
      warmupRecommended: warmupRecommended ?? this.warmupRecommended,
      defaultTempo: defaultTempo ?? this.defaultTempo,
      notes: notes ?? this.notes,
      version: version ?? this.version,
    );
  }

  static List<String> _stringList(Object? value) {
    return (value as List<Object?>? ?? const <Object?>[])
        .map((item) => item.toString())
        .toList();
  }

  static List<ExerciseEquipmentType> _equipmentList(Object? value) {
    return (value as List<Object?>? ?? const <Object?>[])
        .map((item) => item.toString())
        .map(
          (name) => _enumByName(
            ExerciseEquipmentType.values,
            name,
            ExerciseEquipmentType.other,
          ),
        )
        .toList();
  }

  static List<TrainingGoal> _goalList(Object? value) {
    return (value as List<Object?>? ?? const <Object?>[])
        .map((item) => item.toString())
        .map(
          (name) => _enumByName(
            TrainingGoal.values,
            name,
            TrainingGoal.general,
          ),
        )
        .toList();
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null || name.isEmpty) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
