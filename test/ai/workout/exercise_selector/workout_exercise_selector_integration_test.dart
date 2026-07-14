import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_enums.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_catalog_adapter.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_intelligence_runtime.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_trace.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_frequency_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_intensity_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_periodization_type.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_recovery_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_split_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_exercise_complexity.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_exercise_replacement_policy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_training_style.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_volume_strategy.dart';
import 'package:gymaipro/ai/workout/exercise_selector/workout_exercise_selector.dart';
import 'package:gymaipro/ai/workout/generator/coach_workout_generator.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_result.dart';
import 'package:gymaipro/ai/workout/models/workout_progression.dart';
import 'package:gymaipro/ai/workout/planner/workout_split_planner.dart';
import 'package:gymaipro/models/exercise.dart';

import '../../exercise/fixtures/exercise_profile_fixture.dart';
import '../fixtures/workout_exercise_catalog_fixture.dart';

WorkoutBlueprint _blueprint({
  List<String> equipment = const <String>['هالتر', 'دمبل', 'دستگاه'],
  List<String> limitations = const <String>[],
  double recoveryScore = 0.85,
  WorkoutRecoveryStrategy recovery = WorkoutRecoveryStrategy.normal,
}) {
  return WorkoutBlueprint(
    goal: TrainingGoal.hypertrophy,
    experience: 'متوسط',
    daysPerWeek: 3,
    splitStrategy: WorkoutSplitStrategy.pushPullLegs,
    frequency: WorkoutFrequencyStrategy.three,
    volume: WorkoutVolumeStrategy.medium,
    intensity: WorkoutIntensityStrategy.moderate,
    periodization: WorkoutPeriodizationType.linear,
    recoveryStrategy: recovery,
    equipment: equipment,
    limitations: limitations,
    preferredMuscles: const <String>[],
    avoidExercises: const <String>[],
    preferredExercises: const <String>[],
    weeklySetsTarget: 14,
    maxSessionMinutes: 60,
    minRecoveryHours: 24,
    preferredExerciseComplexity: WorkoutExerciseComplexity.moderate,
    exerciseReplacementPolicy: WorkoutExerciseReplacementPolicy.substitute,
    deloadFrequencyWeeks: 4,
    progressionStrategy: WorkoutProgressionStrategy.increaseReps,
    trainingStyle: WorkoutTrainingStyle.hypertrophy,
    exercisesPerSession: 4,
    confidence: 0.9,
    reasons: const [],
    trace: WorkoutBlueprintTrace(
      steps: const <String>['test'],
      recoveryScore: recoveryScore,
    ),
    userId: 'test',
    varietySeed: 42,
  );
}

Exercise _exerciseFromProfile(ExerciseProfile profile) {
  return Exercise(
    id: profile.id,
    title: profile.canonicalName,
    name: profile.canonicalName,
    mainMuscle: profile.primaryMuscles.first,
    secondaryMuscles: profile.secondaryMuscles.join(','),
    tips: profile.notes,
    videoUrl: '',
    imageUrl: '',
    otherNames: profile.aliases,
    content: '',
    difficulty: profile.difficulty.name,
    equipment: profile.equipment.map((e) => e.name).join(','),
    exerciseType: profile.compound ? 'قدرتی' : 'ایزوله',
  );
}

ListExerciseCatalogAdapter _adapterFromProfiles(List<ExerciseProfile> profiles) {
  return ListExerciseCatalogAdapter(
    profiles.map(_exerciseFromProfile).toList(),
  );
}

void main() {
  const generator = CoachWorkoutGenerator();
  const selector = WorkoutExerciseSelector();
  const splitPlanner = WorkoutSplitPlanner();
  const intelligenceRuntime = ExerciseIntelligenceRuntime(
    enforceCoachV2Gate: false,
  );

  group('EPIC 22 exercise intelligence integration', () {
    test('injury replacement selects safer leg exercise', () {
      final catalog = ListExerciseCatalogAdapter(
        WorkoutExerciseCatalogFixture.gymCatalog(),
      );
      final result = generator.generate(
        blueprint: _blueprint(limitations: const <String>['آسیب زانو']),
        catalog: catalog,
      );

      expect(result.isSuccess, isTrue);
      final names = result.program!.allDays
          .expand((day) => day.exercises)
          .map((exercise) => exercise.name)
          .join(' ');
      expect(names.contains('اسکوات'), isFalse);
      expect(names.contains('لانج'), isFalse);
    });

    test('home gym replacement uses dumbbell catalog', () {
      final catalog = ListExerciseCatalogAdapter(
        WorkoutExerciseCatalogFixture.homeCatalog(),
      );
      final result = generator.generate(
        blueprint: _blueprint(
          equipment: const <String>['دمبل', 'خانه'],
        ),
        catalog: catalog,
      );

      expect(result.isSuccess, isTrue);
      for (final day in result.program!.allDays) {
        for (final exercise in day.exercises) {
          expect(
            exercise.equipment.contains('دمبل') ||
                exercise.equipment.contains('بدون'),
            isTrue,
          );
        }
      }
    });

    test('equipment unavailable rejects barbell-only exercises', () {
      final catalog = ListExerciseCatalogAdapter(
        WorkoutExerciseCatalogFixture.gymCatalog(),
      );
      final blueprint = _blueprint(equipment: const <String>['دمبل']);
      final dayPlan = splitPlanner.planFromBlueprint(blueprint).first;

      final squatEntry = catalog.findById(8)!;
      final evaluation = intelligenceRuntime.evaluate(
        exercise: squatEntry.profile,
        query: const ExerciseIntelligenceQuery(
          availableEquipment: <String>['دمبل'],
          targetMuscles: <String>['ران'],
        ),
      );

      expect(evaluation.recommended, isFalse);

      final result = selector.selectForDay(
        dayPlan: dayPlan,
        blueprint: blueprint,
        catalog: catalog,
        usedInProgram: <int>{},
      );

      expect(
        result.selected.every(
          (item) => !item.exercise.equipment.contains('هالتر'),
        ),
        isTrue,
      );
    });

    test('low recovery uses fatigue engine budget', () {
      final catalog = _adapterFromProfiles(ExerciseProfileFixture.gymCatalog());
      final blueprint = _blueprint(
        recoveryScore: 0.35,
        recovery: WorkoutRecoveryStrategy.conservative,
      );
      final legDay = splitPlanner.planFromBlueprint(blueprint).firstWhere(
        (day) => day.targetBuckets.contains(MuscleBucket.quads),
        orElse: () => splitPlanner.planFromBlueprint(blueprint).last,
      );

      final squat = catalog.findById(8)!;
      final fatigue = intelligenceRuntime.evaluate(
        exercise: squat.profile,
        query: const ExerciseIntelligenceQuery(
          recoveryScore: 0.35,
          maxFatigueBudget: 0.3,
          targetMuscles: <String>['ران'],
        ),
      );

      expect(fatigue.fatigue.isAcceptable, isFalse);

      final result = selector.selectForDay(
        dayPlan: legDay,
        blueprint: blueprint,
        catalog: catalog,
        usedInProgram: <int>{},
      );

      expect(result.trace.rejectedCount, greaterThanOrEqualTo(0));
    });

    test('high fatigue exercise rejected without replacement', () {
      final heavySquat = ExerciseProfileFixture.barbellSquat().copyWith(
        fatigueScore: 0.95,
        recoveryCost: 0.95,
      );
      final lightPress = ExerciseProfileFixture.legPressMachine();
      const query = ExerciseIntelligenceQuery(
        recoveryScore: 0.75,
        maxFatigueBudget: 0.65,
        availableEquipment: <String>['هالتر', 'دمبل', 'دستگاه'],
      );

      final heavyEval = intelligenceRuntime.evaluate(
        exercise: heavySquat,
        query: query,
      );
      expect(heavyEval.recommended, isFalse);
      expect(
        heavyEval.reasons.any((reason) => reason.code == 'fatigue.too_high'),
        isTrue,
      );

      final replacement = intelligenceRuntime.findReplacement(
        original: heavySquat,
        catalog: <ExerciseProfile>[heavySquat, lightPress],
        query: query,
      );
      expect(replacement.candidates, isNotEmpty);
      expect(replacement.candidates.first.exercise.id, lightPress.id);
    });

    test('multiple replacement candidates rank by intelligence score', () {
      final original = ExerciseProfileFixture.barbellSquat();
      final catalogProfiles = ExerciseProfileFixture.gymCatalog();
      final replacement = intelligenceRuntime.findReplacement(
        original: original,
        catalog: catalogProfiles,
        query: const ExerciseIntelligenceQuery(
          limitations: <String>['آسیب زانو'],
          targetMuscles: <String>['ران'],
          availableEquipment: <String>['دستگاه', 'دمبل'],
        ),
        limit: 3,
      );

      expect(replacement.candidates.length, greaterThanOrEqualTo(1));
      if (replacement.candidates.length >= 2) {
        expect(
          replacement.candidates.first.score,
          greaterThanOrEqualTo(replacement.candidates[1].score),
        );
      }
    });

    test('explainability stored on generated program exercises', () {
      final catalog = ListExerciseCatalogAdapter(
        WorkoutExerciseCatalogFixture.gymCatalog(),
      );
      final result = generator.generate(
        blueprint: _blueprint(),
        catalog: catalog,
      );

      expect(result.isSuccess, isTrue);
      final exercise = result.program!.allDays.first.exercises.first;
      expect(exercise.selectionReasons, isNotEmpty);
      expect(
        exercise.selectionReasons.any(
          (reason) => reason.code.startsWith('intelligence.'),
        ),
        isTrue,
      );
    });

    test('catalog ranking via intelligence runtime', () {
      final profiles = ExerciseProfileFixture.gymCatalog();
      final ranked = intelligenceRuntime.rankCatalog(
        catalog: profiles,
        query: const ExerciseIntelligenceQuery(
          goal: TrainingGoal.hypertrophy,
          targetMuscles: <String>['ران'],
          availableEquipment: <String>['دستگاه', 'دمبل', 'هالتر'],
        ),
      );

      expect(ranked, isNotEmpty);
      expect(ranked.first.scoring.score, greaterThan(0));
    });

    test('generator trace records selection pipeline counts', () {
      final catalog = ListExerciseCatalogAdapter(
        WorkoutExerciseCatalogFixture.gymCatalog(),
      );
      final result = generator.generate(
        blueprint: _blueprint(),
        catalog: catalog,
      );

      expect(result.selectionTrace, isNotNull);
      expect(result.selectionTrace!.catalogCount, greaterThan(0));
      expect(result.selectionTrace!.filteredCount, greaterThan(0));
      expect(result.selectionTrace!.finalCount, greaterThan(0));
      expect(result.selectionTrace!.steps, isNotEmpty);
    });
  });
}
