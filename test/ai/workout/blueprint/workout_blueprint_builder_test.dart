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
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_builder.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_validator.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_frequency_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_recovery_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_split_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_volume_strategy.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';

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

void main() {
  const builder = WorkoutBlueprintBuilder();
  const validator = WorkoutBlueprintValidator();

  group('WorkoutBlueprintBuilder', () {
    test('beginner blueprint selects moderate volume and safe split', () {
      final result = builder.build(
        context: _context(
          profile: const <String, Object?>{
            'age': 22,
            'height': 175,
            'weight': 70,
            'experience_level': 'مبتدی',
          },
        ),
        userId: 'u1',
        knowledgeResult: _knowledge(),
      );

      expect(result.needsFollowUp, isFalse);
      expect(result.blueprint, isNotNull);
      expect(result.blueprint!.frequency, WorkoutFrequencyStrategy.three);
      expect(result.blueprint!.volume, WorkoutVolumeStrategy.medium);
      expect(result.blueprint!.reasons, isNotEmpty);
    });

    test('advanced blueprint selects higher volume split', () {
      final result = builder.build(
        context: _context(
          profile: const <String, Object?>{
            'age': 30,
            'height': 182,
            'weight': 90,
            'experience_level': 'پیشرفته',
            'bb_days_per_week': 4,
          },
          goals: const <String>['قدرت'],
        ),
        userId: 'u2',
        knowledgeResult: _knowledge(),
      );

      expect(result.blueprint, isNotNull);
      expect(result.blueprint!.splitStrategy, WorkoutSplitStrategy.upperLower);
      expect(result.blueprint!.volume, WorkoutVolumeStrategy.high);
    });

    test('home blueprint keeps home equipment in blueprint data', () {
      final result = builder.build(
        context: _context(
          goals: const <String>['چربی سوزی'],
          equipment: const <String>['دمبل', 'خانه'],
        ),
        userId: 'u3',
      );

      expect(result.blueprint!.equipment, contains('خانه'));
      expect(result.blueprint!.goal, TrainingGoal.fatLoss);
    });

    test('gym blueprint includes barbell equipment', () {
      final result = builder.build(
        context: _context(equipment: const <String>['هالتر', 'دمبل']),
        userId: 'u4',
      );

      expect(result.blueprint!.equipment, contains('هالتر'));
    });

    test('fat loss blueprint selects fat loss goal and undulating periodization', () {
      final result = builder.build(
        context: _context(goals: const <String>['چربی سوزی']),
        userId: 'u5',
      );

      expect(result.blueprint!.goal, TrainingGoal.fatLoss);
      expect(result.blueprint!.periodization.name, 'undulating');
    });

    test('muscle gain blueprint selects hypertrophy goal', () {
      final result = builder.build(
        context: _context(goals: const <String>['عضله‌سازی']),
        userId: 'u6',
      );

      expect(result.blueprint!.goal, TrainingGoal.hypertrophy);
    });

    test('low recovery blueprint selects conservative recovery strategy', () {
      final result = builder.build(
        context: _context(
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
        userId: 'u7',
      );

      expect(
        result.blueprint!.recoveryStrategy,
        WorkoutRecoveryStrategy.conservative,
      );
      expect(
        result.blueprint!.reasons.any(
          (reason) => reason.because.any((line) => line.contains('Recovery')),
        ),
        isTrue,
      );
    });

    test('validation failure returns follow-up for missing equipment', () {
      final result = builder.build(
        context: _context(equipment: const <String>[]),
        userId: 'u8',
      );

      expect(result.needsFollowUp, isTrue);
      expect(result.followUpFields, contains('equipment'));
    });

    test('follow up generation when profile is incomplete', () {
      final result = builder.build(
        context: _context(
          profile: const <String, Object?>{'experience_level': 'متوسط'},
        ),
        userId: 'u9',
      );

      expect(result.needsFollowUp, isTrue);
      expect(result.followUpFields, isNotEmpty);
      expect(result.blueprint, isNull);
    });

    test('validator accepts complete blueprint', () {
      final result = builder.build(
        context: _context(),
        userId: 'u10',
      );
      final validation = validator.validate(result.blueprint!);
      expect(validation.isValid, isTrue);
      expect(validation.needsFollowUp, isFalse);
    });

    test('entitlement snapshot blocks free plan workout generation', () {
      final result = builder.build(
        context: _context(),
        userId: 'u11',
        entitlementSnapshot: CoachEntitlementSnapshot.free(userId: 'u11'),
      );

      expect(result.entitlementBlocked, isTrue);
      expect(result.blueprint, isNull);
    });
  });
}
