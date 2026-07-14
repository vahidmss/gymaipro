import 'package:gymaipro/ai/exercise/models/exercise_intelligence_enums.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';

/// Offline exercise profiles for intelligence engine tests.
class ExerciseProfileFixture {
  const ExerciseProfileFixture._();

  static ExerciseProfile barbellSquat() {
    return const ExerciseProfile(
      id: 8,
      slug: 'barbell-squat',
      canonicalName: 'اسکوات هالتر',
      primaryMuscles: <String>['ران'],
      equipment: <ExerciseEquipmentType>[ExerciseEquipmentType.barbell],
      difficulty: ExerciseDifficultyLevel.intermediate,
      fatigueScore: 0.8,
      stimulusScore: 0.85,
      injuryRisk: 0.55,
      recoveryCost: 0.75,
      preferredGoals: <TrainingGoal>[TrainingGoal.strength, TrainingGoal.hypertrophy],
      experienceLevel: ExerciseExperienceLevel.intermediate,
      kneeLoad: 0.75,
      hipLoad: 0.55,
      spineLoad: 0.45,
      compound: true,
      movementPattern: ExerciseMovementPattern.squat,
    );
  }

  static ExerciseProfile dumbbellBench() {
    return const ExerciseProfile(
      id: 2,
      slug: 'dumbbell-bench',
      canonicalName: 'پرس سینه دمبل',
      primaryMuscles: <String>['سینه'],
      equipment: <ExerciseEquipmentType>[ExerciseEquipmentType.dumbbell],
      difficulty: ExerciseDifficultyLevel.intermediate,
      fatigueScore: 0.55,
      stimulusScore: 0.7,
      injuryRisk: 0.25,
      recoveryCost: 0.45,
      preferredGoals: <TrainingGoal>[TrainingGoal.hypertrophy],
      shoulderLoad: 0.45,
      compound: true,
      movementPattern: ExerciseMovementPattern.horizontalPush,
    );
  }

  static ExerciseProfile legPressMachine() {
    return const ExerciseProfile(
      id: 16,
      slug: 'leg-press',
      canonicalName: 'پرس پا دستگاه',
      primaryMuscles: <String>['ران'],
      equipment: <ExerciseEquipmentType>[ExerciseEquipmentType.machine],
      difficulty: ExerciseDifficultyLevel.beginner,
      fatigueScore: 0.5,
      stimulusScore: 0.6,
      injuryRisk: 0.2,
      recoveryCost: 0.4,
      preferredGoals: <TrainingGoal>[TrainingGoal.hypertrophy, TrainingGoal.general],
      experienceLevel: ExerciseExperienceLevel.beginner,
      kneeLoad: 0.35,
      compound: true,
      movementPattern: ExerciseMovementPattern.squat,
    );
  }

  static ExerciseProfile overheadPress() {
    return const ExerciseProfile(
      id: 17,
      slug: 'overhead-press',
      canonicalName: 'پرس سرشانه هالتر',
      primaryMuscles: <String>['شانه'],
      equipment: <ExerciseEquipmentType>[ExerciseEquipmentType.barbell],
      difficulty: ExerciseDifficultyLevel.advanced,
      fatigueScore: 0.65,
      stimulusScore: 0.7,
      injuryRisk: 0.6,
      recoveryCost: 0.55,
      preferredGoals: <TrainingGoal>[TrainingGoal.strength],
      experienceLevel: ExerciseExperienceLevel.advanced,
      shoulderLoad: 0.8,
      spineLoad: 0.35,
      compound: true,
      movementPattern: ExerciseMovementPattern.verticalPush,
    );
  }

  static List<ExerciseProfile> gymCatalog() => <ExerciseProfile>[
    dumbbellBench(),
    barbellSquat(),
    legPressMachine(),
    overheadPress(),
  ];
}
