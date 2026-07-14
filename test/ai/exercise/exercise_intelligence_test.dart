import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/exercise/compatibility/exercise_compatibility_engine.dart';
import 'package:gymaipro/ai/exercise/fatigue/exercise_fatigue_engine.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_enums.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_versions.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile_mapper.dart';
import 'package:gymaipro/ai/exercise/replacement/exercise_replacement_engine.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_intelligence_runtime.dart';
import 'package:gymaipro/ai/exercise/safety/exercise_safety_engine.dart';
import 'package:gymaipro/ai/exercise/scoring/exercise_scoring_engine.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';

import 'fixtures/exercise_profile_fixture.dart';
import '../workout/fixtures/workout_exercise_catalog_fixture.dart';

void main() {
  const scoringEngine = ExerciseScoringEngine();
  const compatibilityEngine = ExerciseCompatibilityEngine();
  const safetyEngine = ExerciseSafetyEngine();
  const fatigueEngine = ExerciseFatigueEngine();
  const replacementEngine = ExerciseReplacementEngine();
  const runtime = ExerciseIntelligenceRuntime();
  const mapper = ExerciseProfileMapper();

  const hypertrophyQuery = ExerciseIntelligenceQuery(
    goal: TrainingGoal.hypertrophy,
    experience: 'متوسط',
    availableEquipment: <String>['هالتر', 'دمبل', 'دستگاه'],
    targetMuscles: <String>['ران'],
    recoveryScore: 0.85,
  );

  group('EPIC 21 exercise intelligence', () {
    test('exercise profile models are immutable via copyWith', () {
      final original = ExerciseProfileFixture.barbellSquat();
      final updated = original.copyWith(fatigueScore: 0.2);
      expect(updated.fatigueScore, 0.2);
      expect(original.fatigueScore, 0.8);
      expect(original.version, ExerciseIntelligenceVersions.profileSchemaVersion);
    });

    test('profile mapper maps catalog exercise into intelligence profile', () {
      final exercise = WorkoutExerciseCatalogFixture.gymCatalog().first;
      final profile = mapper.fromExercise(exercise);
      expect(profile.id, exercise.id);
      expect(profile.canonicalName, exercise.name);
      expect(profile.primaryMuscles, isNotEmpty);
      expect(profile.equipment, isNotEmpty);
    });

    test('scoring engine emits goal and equipment reasons', () {
      final result = scoringEngine.score(
        exercise: ExerciseProfileFixture.dumbbellBench(),
        query: const ExerciseIntelligenceQuery(
          goal: TrainingGoal.hypertrophy,
          availableEquipment: <String>['دمبل'],
          targetMuscles: <String>['سینه'],
        ),
      );
      expect(result.score, greaterThan(0.5));
      expect(
        result.reasons.any((reason) => reason.code == 'goal.match'),
        isTrue,
      );
      expect(
        result.reasons.any(
          (reason) =>
              reason.code == 'equipment.match' &&
              reason.because.contains('Equipment Match'),
        ),
        isTrue,
      );
    });

    test('compatibility engine rejects missing equipment', () {
      final result = compatibilityEngine.evaluate(
        exercise: ExerciseProfileFixture.barbellSquat(),
        query: const ExerciseIntelligenceQuery(
          availableEquipment: <String>['دمبل'],
        ),
      );
      expect(result.isCompatible, isFalse);
      expect(
        result.reasons.any((reason) => reason.code == 'compatibility.equipment'),
        isTrue,
      );
    });

    test('safety engine blocks high knee load with knee limitation', () {
      final result = safetyEngine.evaluate(
        exercise: ExerciseProfileFixture.barbellSquat(),
        query: const ExerciseIntelligenceQuery(
          limitations: <String>['آسیب زانو'],
        ),
      );
      expect(result.isSafe, isFalse);
      expect(
        result.reasons.any(
          (reason) =>
              reason.code == 'safety.knee_risk' ||
              reason.because.any((line) => line.contains('Knee')),
        ),
        isTrue,
      );
    });

    test('safety engine marks low-risk exercise as injury safe', () {
      final result = safetyEngine.evaluate(
        exercise: ExerciseProfileFixture.dumbbellBench(),
        query: const ExerciseIntelligenceQuery(),
      );
      expect(result.isSafe, isTrue);
      expect(
        result.reasons.any(
          (reason) =>
              reason.code == 'safety.injury_safe' &&
              reason.because.contains('Injury Safe'),
        ),
        isTrue,
      );
    });

    test('fatigue engine flags high fatigue when recovery is low', () {
      final result = fatigueEngine.evaluate(
        exercise: ExerciseProfileFixture.barbellSquat(),
        query: const ExerciseIntelligenceQuery(
          recoveryScore: 0.35,
          maxFatigueBudget: 0.4,
          sessionFatigueAccumulated: 0.2,
        ),
      );
      expect(result.isAcceptable, isFalse);
      expect(
        result.reasons.any(
          (reason) =>
              reason.code == 'fatigue.too_high' &&
              reason.because.contains('Fatigue Too High'),
        ),
        isTrue,
      );
    });

    test('fatigue engine marks recovery-friendly exercises', () {
      final result = fatigueEngine.evaluate(
        exercise: ExerciseProfileFixture.legPressMachine(),
        query: hypertrophyQuery,
      );
      expect(result.isAcceptable, isTrue);
      expect(
        result.reasons.any(
          (reason) =>
              reason.code == 'fatigue.recovery_friendly' &&
              reason.because.contains('Recovery Friendly'),
        ),
        isTrue,
      );
    });

    test('replacement engine finds safer squat alternative', () {
      final result = replacementEngine.findReplacements(
        original: ExerciseProfileFixture.barbellSquat(),
        catalog: ExerciseProfileFixture.gymCatalog(),
        query: hypertrophyQuery,
      );
      expect(result.candidates, isNotEmpty);
      final top = result.candidates.first;
      expect(top.exercise.canonicalName, 'پرس پا دستگاه');
      expect(
        top.reasons.any(
          (reason) =>
              reason.code == 'replacement.better' &&
              reason.because.contains('Better Replacement'),
        ),
        isTrue,
      );
    });

    test('explainability aggregates reasons across engines', () {
      if (!CoachV2Config.coachV2Enabled) return;

      final evaluation = runtime.evaluate(
        exercise: ExerciseProfileFixture.legPressMachine(),
        query: hypertrophyQuery,
      );
      expect(evaluation.enabled, isTrue);
      expect(evaluation.reasons.length, greaterThan(3));
      expect(
        evaluation.reasons.any((reason) => reason.because.isNotEmpty),
        isTrue,
      );
    });

    test('runtime returns disabled evaluation when CoachV2 is off', () {
      if (CoachV2Config.coachV2Enabled) return;

      final evaluation = runtime.evaluate(
        exercise: ExerciseProfileFixture.dumbbellBench(),
        query: hypertrophyQuery,
      );
      expect(evaluation.enabled, isFalse);
      expect(
        evaluation.reasons.any((reason) => reason.code == 'runtime.disabled'),
        isTrue,
      );
    });

    test('runtime exposes engine version', () {
      expect(runtime.engineVersion, ExerciseIntelligenceVersions.engineVersion);
    });

    test('exercise profile serializes required intelligence fields', () {
      final profile = ExerciseProfile(
        id: 99,
        slug: 'test-move',
        canonicalName: 'Test Move',
        primaryMuscles: const <String>['سینه'],
        secondaryMuscles: const <String>['سه‌سر بازو'],
        movementPattern: ExerciseMovementPattern.horizontalPush,
        movementType: ExerciseMovementType.compound,
        equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.dumbbell],
        difficulty: ExerciseDifficultyLevel.beginner,
        fatigueScore: 0.4,
        stimulusScore: 0.6,
        injuryRisk: 0.2,
        stabilityRequirement: 0.3,
        executionComplexity: 0.35,
        recoveryCost: 0.3,
        preferredGoals: const <TrainingGoal>[TrainingGoal.hypertrophy],
        experienceLevel: ExerciseExperienceLevel.beginner,
        jointStress: ExerciseJointStressLevel.low,
        gripType: ExerciseGripType.neutral,
        defaultTempo: '3010',
        notes: const <String>['Keep scapula retracted'],
      );

      final json = profile.toJson();
      final restored = ExerciseProfile.fromJson(json);

      expect(restored.id, 99);
      expect(restored.slug, 'test-move');
      expect(restored.canonicalName, 'Test Move');
      expect(restored.primaryMuscles, contains('سینه'));
      expect(restored.movementPattern, ExerciseMovementPattern.horizontalPush);
      expect(restored.fatigueScore, 0.4);
      expect(restored.defaultTempo, '3010');
      expect(restored.compound, isTrue);
    });
  });
}
