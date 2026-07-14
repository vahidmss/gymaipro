import 'package:gymaipro/ai/exercise/models/exercise_intelligence_enums.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/models/exercise.dart';

/// Maps catalog [Exercise] rows into intelligence [ExerciseProfile] records.
class ExerciseProfileMapper {
  const ExerciseProfileMapper();

  ExerciseProfile fromExercise(Exercise exercise) {
    final compound = _isCompound(exercise);
    final pattern = _movementPattern(exercise, compound);
    final equipment = _equipmentTypes(exercise.equipment);
    final difficulty = _difficultyLevel(exercise.difficulty);
    final goals = _preferredGoals(exercise);
    final jointLoads = _jointLoads(exercise, compound, pattern);

    return ExerciseProfile(
      id: exercise.id,
      slug: _slug(exercise),
      canonicalName: exercise.name,
      aliases: List<String>.from(exercise.otherNames),
      primaryMuscles: _muscleList(exercise.mainMuscle),
      secondaryMuscles: _muscleList(exercise.secondaryMuscles),
      movementPattern: pattern,
      movementType: compound
          ? ExerciseMovementType.compound
          : ExerciseMovementType.isolation,
      equipment: equipment,
      difficulty: difficulty,
      fatigueScore: compound ? 0.7 : 0.4,
      stimulusScore: compound ? 0.75 : 0.55,
      injuryRisk: jointLoads.maxLoad * 0.8 + (compound ? 0.1 : 0),
      stabilityRequirement: compound ? 0.65 : 0.35,
      executionComplexity: _executionComplexity(difficulty, compound),
      recoveryCost: compound ? 0.65 : 0.35,
      preferredGoals: goals,
      experienceLevel: _experienceLevel(difficulty),
      jointStress: _jointStress(jointLoads.maxLoad),
      spineLoad: jointLoads.spine,
      shoulderLoad: jointLoads.shoulder,
      kneeLoad: jointLoads.knee,
      hipLoad: jointLoads.hip,
      elbowLoad: jointLoads.elbow,
      wristLoad: jointLoads.wrist,
      gripType: _gripType(exercise),
      unilateral: _isUnilateral(exercise.name),
      compound: compound,
      isolation: !compound,
      warmupRecommended: compound,
      defaultTempo: exercise.richMeta.tempo,
      notes: exercise.tips,
    );
  }

  List<ExerciseProfile> fromExercises(Iterable<Exercise> exercises) {
    return exercises.map(fromExercise).toList();
  }

  String _slug(Exercise exercise) {
    final slug = exercise.richMeta.webSlug.trim();
    if (slug.isNotEmpty) return slug;
    return 'exercise-${exercise.id}';
  }

  bool _isCompound(Exercise exercise) {
    final mechanics = exercise.richMeta.mechanicsType.toLowerCase();
    if (mechanics.contains('compound') || mechanics.contains('ترکیبی')) {
      return true;
    }
    if (mechanics.contains('isolation') || mechanics.contains('ایزوله')) {
      return false;
    }
    return WorkoutScience.isCompoundExercise(
      exercise.name,
      exercise.exerciseType,
    );
  }

  ExerciseMovementPattern _movementPattern(Exercise exercise, bool compound) {
    final label = exercise.movementPattern.toLowerCase();
    final name = exercise.name.toLowerCase();
    if (label.contains('squat') || name.contains('اسکوات') || name.contains('squat')) {
      return ExerciseMovementPattern.squat;
    }
    if (label.contains('hinge') ||
        name.contains('ددلیفت') ||
        name.contains('deadlift')) {
      return ExerciseMovementPattern.hinge;
    }
    if (name.contains('لانج') || name.contains('lunge')) {
      return ExerciseMovementPattern.lunge;
    }
    if (name.contains('پرس سینه') ||
        name.contains('bench') ||
        name.contains('فلای')) {
      return ExerciseMovementPattern.horizontalPush;
    }
    if (name.contains('زیربغل') ||
        name.contains('لت') ||
        name.contains('row') ||
        name.contains('pull')) {
      return ExerciseMovementPattern.horizontalPull;
    }
    if (name.contains('سرشانه') ||
        name.contains('overhead') ||
        name.contains('press') && name.contains('شانه')) {
      return ExerciseMovementPattern.verticalPush;
    }
    if (name.contains('پول') && name.contains('آپ')) {
      return ExerciseMovementPattern.verticalPull;
    }
    if (exercise.exerciseType.contains('کاردیو') ||
        exercise.exerciseType.contains('هوازی')) {
      return ExerciseMovementPattern.cardio;
    }
    if (!compound) return ExerciseMovementPattern.isolation;
    return ExerciseMovementPattern.other;
  }

  List<ExerciseEquipmentType> _equipmentTypes(String raw) {
    final text = raw.toLowerCase();
    final out = <ExerciseEquipmentType>{};
    if (text.contains('هالتر') || text.contains('barbell')) {
      out.add(ExerciseEquipmentType.barbell);
    }
    if (text.contains('دمبل') || text.contains('dumbbell')) {
      out.add(ExerciseEquipmentType.dumbbell);
    }
    if (text.contains('دستگاه') || text.contains('machine') || text.contains('پولی')) {
      out.add(ExerciseEquipmentType.machine);
    }
    if (text.contains('کابل') || text.contains('cable')) {
      out.add(ExerciseEquipmentType.cable);
    }
    if (text.contains('بدون') ||
        text.contains('bodyweight') ||
        text.contains('وزن بدن')) {
      out.add(ExerciseEquipmentType.bodyweight);
    }
    if (text.contains('کتل') || text.contains('kettlebell')) {
      out.add(ExerciseEquipmentType.kettlebell);
    }
    if (text.contains('کش') || text.contains('band')) {
      out.add(ExerciseEquipmentType.band);
    }
    if (out.isEmpty) out.add(ExerciseEquipmentType.other);
    return out.toList();
  }

  ExerciseDifficultyLevel _difficultyLevel(String raw) {
    if (raw.contains('آسان') || raw.contains('مبتدی')) {
      return ExerciseDifficultyLevel.beginner;
    }
    if (raw.contains('سخت') || raw.contains('پیشرفته')) {
      return ExerciseDifficultyLevel.advanced;
    }
    return ExerciseDifficultyLevel.intermediate;
  }

  ExerciseExperienceLevel _experienceLevel(ExerciseDifficultyLevel difficulty) {
    return switch (difficulty) {
      ExerciseDifficultyLevel.beginner => ExerciseExperienceLevel.beginner,
      ExerciseDifficultyLevel.intermediate =>
        ExerciseExperienceLevel.intermediate,
      ExerciseDifficultyLevel.advanced => ExerciseExperienceLevel.advanced,
    };
  }

  double _executionComplexity(
    ExerciseDifficultyLevel difficulty,
    bool compound,
  ) {
    final base = switch (difficulty) {
      ExerciseDifficultyLevel.beginner => 0.3,
      ExerciseDifficultyLevel.intermediate => 0.5,
      ExerciseDifficultyLevel.advanced => 0.75,
    };
    return compound ? (base + 0.1).clamp(0, 1) : base;
  }

  List<TrainingGoal> _preferredGoals(Exercise exercise) {
    final goal = exercise.richMeta.programmingGoal.toLowerCase();
    if (goal.contains('قدرت') || goal.contains('strength')) {
      return const <TrainingGoal>[TrainingGoal.strength];
    }
    if (goal.contains('حجم') ||
        goal.contains('hypertrophy') ||
        goal.contains('عضله')) {
      return const <TrainingGoal>[TrainingGoal.hypertrophy];
    }
    if (goal.contains('چربی') || goal.contains('fat')) {
      return const <TrainingGoal>[TrainingGoal.fatLoss];
    }
    if (exercise.exerciseType.contains('کاردیو')) {
      return const <TrainingGoal>[TrainingGoal.endurance, TrainingGoal.fatLoss];
    }
    return const <TrainingGoal>[
      TrainingGoal.hypertrophy,
      TrainingGoal.general,
    ];
  }

  _JointLoads _jointLoads(
    Exercise exercise,
    bool compound,
    ExerciseMovementPattern pattern,
  ) {
    final name = exercise.name.toLowerCase();
    var spine = 0.0;
    var shoulder = 0.0;
    var knee = 0.0;
    var hip = 0.0;
    var elbow = 0.0;
    var wrist = 0.0;

    if (name.contains('اسکوات') || name.contains('squat') || name.contains('لانج')) {
      knee = compound ? 0.75 : 0.45;
      hip = compound ? 0.55 : 0.35;
      spine = compound ? 0.45 : 0.2;
    }
    if (name.contains('ددلیفت') || name.contains('deadlift')) {
      spine = 0.85;
      hip = 0.7;
      knee = 0.35;
    }
    if (name.contains('پرس') && name.contains('سینه')) {
      shoulder = 0.55;
      elbow = 0.35;
    }
    if (name.contains('سرشانه') || name.contains('overhead')) {
      shoulder = 0.8;
      spine = 0.35;
    }
    if (name.contains('جلو بازو') || name.contains('curl')) {
      elbow = 0.55;
      wrist = 0.25;
    }
    if (name.contains('پشت بازو') || name.contains('tricep')) {
      elbow = 0.5;
      shoulder = 0.25;
    }

    if (pattern == ExerciseMovementPattern.hinge && spine == 0) {
      spine = 0.7;
    }
    if (pattern == ExerciseMovementPattern.squat && knee == 0) {
      knee = 0.65;
    }

    return _JointLoads(
      spine: spine,
      shoulder: shoulder,
      knee: knee,
      hip: hip,
      elbow: elbow,
      wrist: wrist,
    );
  }

  ExerciseJointStressLevel _jointStress(double maxLoad) {
    if (maxLoad >= 0.75) return ExerciseJointStressLevel.high;
    if (maxLoad >= 0.45) return ExerciseJointStressLevel.moderate;
    if (maxLoad > 0) return ExerciseJointStressLevel.low;
    return ExerciseJointStressLevel.none;
  }

  ExerciseGripType _gripType(Exercise exercise) {
    final name = exercise.name.toLowerCase();
    if (name.contains('هامر') || name.contains('hammer')) {
      return ExerciseGripType.neutral;
    }
    if (name.contains('زیرین') || name.contains('supinated')) {
      return ExerciseGripType.supinated;
    }
    if (name.contains('قبضه') || name.contains('grip')) {
      return ExerciseGripType.pronated;
    }
    return ExerciseGripType.none;
  }

  bool _isUnilateral(String name) {
    final lower = name.toLowerCase();
    return lower.contains('تک') ||
        lower.contains('single') ||
        lower.contains('unilateral');
  }

  List<String> _muscleList(String raw) {
    if (raw.trim().isEmpty) return const <String>[];
    return raw
        .split(RegExp('[,،/]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class _JointLoads {
  const _JointLoads({
    required this.spine,
    required this.shoulder,
    required this.knee,
    required this.hip,
    required this.elbow,
    required this.wrist,
  });

  final double spine;
  final double shoulder;
  final double knee;
  final double hip;
  final double elbow;
  final double wrist;

  double get maxLoad => [
    spine,
    shoulder,
    knee,
    hip,
    elbow,
    wrist,
  ].fold<double>(0, (max, value) => value > max ? value : max);
}
