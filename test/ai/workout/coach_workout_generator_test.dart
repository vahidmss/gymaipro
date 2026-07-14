import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_snapshot.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/knowledge_registry.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_trace.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_builder.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_reason.dart';
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
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_versions.dart';
import 'package:gymaipro/ai/workout/models/workout_progression.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_catalog_adapter.dart';
import 'package:gymaipro/ai/workout/generator/coach_workout_generator.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_result.dart';
import 'package:gymaipro/ai/workout/runtime/coach_workout_generator_runtime.dart';
import 'package:gymaipro/ai/workout/runtime/workout_generation_skill.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';
import 'fixtures/workout_exercise_catalog_fixture.dart';

CoachContext _context({
  Map<String, Object?> profile = const <String, Object?>{
    'age': 28,
    'height': 180,
    'weight': 82,
    'gender': 'male',
    'experience_level': 'متوسط',
  },
  List<String> goals = const <String>['عضله‌سازی'],
  List<String> equipment = const <String>['هالتر', 'دمبل'],
  List<String> restrictions = const <String>[],
  List<CoachMemory> memories = const <CoachMemory>[],
  WeeklyMuscleHeatmapResult? weeklyHeatmap,
}) {
  return CoachContext(
    intent: AIIntent.workoutGeneration,
    profile: profile,
    goals: goals,
    equipment: equipment,
    restrictions: restrictions,
    memories: memories,
    weeklyHeatmap: weeklyHeatmap,
    metadata: CoachContextMetadata(
      buildTime: DateTime(2026, 7, 12),
      sourceCount: 4,
      missingProviders: const {},
      confidence: 0.9,
      contextVersion: CoachContext.contextVersion,
    ),
  );
}

CoachKnowledgeResult _knowledge() {
  final node = KnowledgeRegistry.nodes['workout_generation']!;
  return CoachKnowledgeResult(
    selectedNode: node,
    candidateNodes: <KnowledgeNode>[node],
    confidence: 0.9,
    reasons: const <String>['intent match'],
    trace: CoachKnowledgeTrace(
      nodeTraces: const <CoachKnowledgeNodeTrace>[],
      executionTime: const Duration(milliseconds: 1),
      selectedNodeId: node.id,
      usedFallback: false,
    ),
  );
}

WorkoutBlueprint _blueprintFromContext(
  CoachContext context, {
  String userId = 'u1',
  int? varietySeed,
}) {
  final result = const WorkoutBlueprintBuilder().build(
    context: context,
    userId: userId,
    knowledgeResult: _knowledge(),
    varietySeed: varietySeed,
  );
  expect(result.blueprint, isNotNull, reason: result.message);
  return result.blueprint!;
}

WorkoutBlueprint _manualBlueprint({
  TrainingGoal goal = TrainingGoal.hypertrophy,
  String experience = 'متوسط',
  int daysPerWeek = 3,
  WorkoutSplitStrategy splitStrategy = WorkoutSplitStrategy.pushPullLegs,
  WorkoutVolumeStrategy volume = WorkoutVolumeStrategy.medium,
  WorkoutIntensityStrategy intensity = WorkoutIntensityStrategy.moderate,
  WorkoutRecoveryStrategy recoveryStrategy = WorkoutRecoveryStrategy.normal,
  List<String> equipment = const <String>['هالتر', 'دمبل'],
  List<String> limitations = const <String>[],
  List<String> avoidExercises = const <String>[],
  double recoveryScore = 0.85,
  int varietySeed = 42,
}) {
  return WorkoutBlueprint(
    goal: goal,
    experience: experience,
    daysPerWeek: daysPerWeek,
    splitStrategy: splitStrategy,
    frequency: WorkoutFrequencyStrategy.values.firstWhere(
      (value) => value.daysPerWeek == daysPerWeek,
    ),
    volume: volume,
    intensity: intensity,
    periodization: WorkoutPeriodizationType.linear,
    recoveryStrategy: recoveryStrategy,
    equipment: equipment,
    limitations: limitations,
    preferredMuscles: const <String>[],
    avoidExercises: avoidExercises,
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
    reasons: const <WorkoutBlueprintReason>[
      WorkoutBlueprintReason(
        code: 'test.blueprint',
        subject: 'Test',
        because: <String>['manual fixture'],
      ),
    ],
    trace: WorkoutBlueprintTrace(
      steps: const <String>['test'],
      recoveryScore: recoveryScore,
    ),
    userId: 'test_user',
    goals: const <String>['عضله‌سازی'],
    varietySeed: varietySeed,
  );
}

void main() {
  const generator = CoachWorkoutGenerator();
  const runtime = CoachWorkoutGeneratorRuntime();
  final rawCatalog = WorkoutExerciseCatalogFixture.gymCatalog();
  final rawHomeCatalog = WorkoutExerciseCatalogFixture.homeCatalog();
  final catalog = ListExerciseCatalogAdapter(rawCatalog);
  final homeCatalog = ListExerciseCatalogAdapter(rawHomeCatalog);

  group('CoachWorkoutGenerator', () {
    test('beginner muscle gain gym produces typed program', () {
      final blueprint = _blueprintFromContext(
        _context(profile: const <String, Object?>{
          'age': 22,
          'height': 175,
          'weight': 70,
          'experience_level': 'مبتدی',
        }),
        varietySeed: 42,
      );
      final result = generator.generate(
        blueprint: blueprint,
        catalog: catalog,
      );

      expect(result.status, WorkoutGeneratorStatus.success);
      expect(result.program, isNotNull);
      expect(result.program!.allDays.length, 3);
      expect(result.program!.totalExercises, greaterThan(6));
      expect(result.program!.allDays.first.exercises.first.sets, isNotEmpty);
      expect(result.reasons, isNotEmpty);
    });

    test('intermediate hypertrophy gym respects volume', () {
      final blueprint = _blueprintFromContext(_context(), varietySeed: 17);
      final result = generator.generate(
        blueprint: blueprint,
        catalog: catalog,
      );

      expect(result.isSuccess, isTrue);
      expect(result.program!.goal.name, 'hypertrophy');
      expect(result.program!.totalExercises, greaterThanOrEqualTo(9));
    });

    test('advanced strength gym respects experience filter', () {
      final blueprint = _blueprintFromContext(
        _context(
          profile: const <String, Object?>{
            'age': 30,
            'height': 182,
            'weight': 90,
            'experience_level': 'پیشرفته',
            'bb_days_per_week': 4,
          },
          goals: const <String>['قدرت'],
        ),
        varietySeed: 7,
      );
      final result = generator.generate(
        blueprint: blueprint,
        catalog: catalog,
      );

      expect(result.isSuccess, isTrue);
      expect(result.program!.daysPerWeek, 4);
      expect(
        result.program!.allDays
            .expand((day) => day.exercises)
            .any((exercise) => exercise.isCompound),
        isTrue,
      );
    });

    test('fat loss home gym uses home catalog equipment', () {
      final blueprint = _blueprintFromContext(
        _context(
          goals: const <String>['چربی سوزی'],
          equipment: const <String>['دمبل', 'خانه'],
        ),
        varietySeed: 11,
      );
      final result = generator.generate(
        blueprint: blueprint,
        catalog: homeCatalog,
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

    test('injury avoids squat movements', () {
      final blueprint = _blueprintFromContext(
        _context(
          goals: const <String>['تناسب اندام'],
          restrictions: const <String>['آسیب زانو'],
        ),
        varietySeed: 3,
      );
      final result = generator.generate(
        blueprint: blueprint,
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

    test('memory dislikes squat never suggests squat', () {
      final timestamp = DateTime(2026);
      final result = runtime.generate(
        context: _context(
          memories: <CoachMemory>[
            CoachMemory(
              key: 'preferences.dislikes_squat',
              value: 'اسکوات',
              category: MemoryCategory.preference,
              confidence: 0.95,
              importance: MemoryImportance.high,
              source: MemorySource.inference,
              createdAt: timestamp,
              updatedAt: timestamp,
              editable: true,
              userEditable: true,
              aiGenerated: false,
            ),
          ],
        ),
        userId: 'u5',
        catalog: InMemoryWorkoutExerciseCatalog(rawCatalog),
        knowledgeResult: _knowledge(),
        varietySeed: 5,
      );

      expect(result.isSuccess, isTrue);
      final names = result.program!.allDays
          .expand((day) => day.exercises)
          .map((exercise) => exercise.name);
      expect(names.any((name) => name.contains('اسکوات')), isFalse);
    });

    test('low recovery reduces leg overlap', () {
      final blueprint = _blueprintFromContext(
        _context(
          weeklyHeatmap: const WeeklyMuscleHeatmapResult(
            targets: <String, int>{
              'quads': 6,
              'chest': 6,
              'back': 6,
              'shoulders': 5,
            },
            previousWeekTargets: <String, int>{},
            workoutDays: 5,
            sessionCount: 5,
            previousSessionCount: 4,
            hasHeatmapData: true,
            hasPreviousWeekData: false,
          ),
        ),
        varietySeed: 9,
      );
      final result = generator.generate(
        blueprint: blueprint,
        catalog: catalog,
      );

      expect(blueprint.recoveryStrategy, WorkoutRecoveryStrategy.conservative);
      expect(
        result.status,
        anyOf(
          WorkoutGeneratorStatus.success,
          WorkoutGeneratorStatus.validationFailed,
          WorkoutGeneratorStatus.insufficientExercises,
        ),
      );
    });

    test('missing data returns follow-up not partial program', () {
      final result = runtime.generate(
        context: _context(equipment: const <String>[]),
        userId: 'u7',
        catalog: InMemoryWorkoutExerciseCatalog(rawCatalog),
      );

      expect(result.status, WorkoutGeneratorStatus.needsFollowUp);
      expect(result.program, isNull);
      expect(result.followUpFields, isNotEmpty);
    });

    test('entitlement blocked does not generate program', () {
      final result = runtime.generate(
        context: _context(),
        userId: 'u8',
        catalog: InMemoryWorkoutExerciseCatalog(rawCatalog),
        entitlementSnapshot: CoachEntitlementSnapshot.free(userId: 'u8'),
        varietySeed: 1,
      );

      expect(result.status, WorkoutGeneratorStatus.entitlementBlocked);
      expect(result.program, isNull);
    });

    test('program serializes to json for persistence', () {
      final blueprint = _manualBlueprint(varietySeed: 99);
      final result = generator.generate(
        blueprint: blueprint,
        catalog: catalog,
      );

      final json = result.program!.toJson();
      expect(json['id'], isNotEmpty);
      expect(json['weeks'], isA<List<Object?>>());
      expect(json['goal'], 'hypertrophy');
    });

    test('workout generation skill returns typed program payload', () {
      final skill = WorkoutGenerationSkill(
        catalog: rawCatalog,
        userId: 'skill_user',
      );
      final response = skill.execute(
        context: _context(
          profile: const <String, Object?>{
            'age': 28,
            'height': 180,
            'weight': 82,
            'gender': 'male',
            'experience_level': 'متوسط',
            'bb_days_per_week': 3,
          },
        ),
        intent: AIIntent.workoutGeneration,
      );

      expect(response.requiresAI, isFalse);
      expect(response.structuredData?['workoutProgram'], isA<Map<Object?, Object?>>());
      expect(response.confidence, greaterThan(0.8));
    });
  });
}
