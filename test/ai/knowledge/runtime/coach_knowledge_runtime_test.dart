import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/entity/entity_type.dart';
import 'package:gymaipro/ai/knowledge/knowledge_graph.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/knowledge_registry.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_ranker.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_runtime.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_selector.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_validator.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';

void main() {
  final metadata = CoachContextMetadata(
    buildTime: DateTime(2026, 7, 12),
    sourceCount: 6,
    missingProviders: const {},
    confidence: 0.85,
    contextVersion: CoachContext.contextVersion,
  );

  CoachContext richWorkoutContext({
    AIIntent intent = AIIntent.workoutGeneration,
  }) {
    return CoachContext(
      intent: intent,
      metadata: metadata,
      goals: const <String>['عضله‌سازی'],
      equipment: const <String>['دمبل', 'بارفیکس'],
      restrictions: const <String>['درد شانه'],
      activeProgram: const <String, Object?>{
        'active_program_id': 'program_1',
        'name': 'برنامه قدرتی',
      },
      currentQuestion: 'برنامه تمرینی بساز',
    );
  }

  EntityMatch entitySource(EntityType type) {
    return EntityMatch(
      ruleId: 'test_rule',
      type: type,
      rawText: 'test',
      rawValue: 'test',
      score: 0.9,
      start: 0,
      end: 4,
    );
  }

  NormalizedEntity normalizedEntity(EntityType type) {
    return NormalizedEntity(
      type: type,
      value: 'عضله‌سازی',
      confidence: 0.9,
      source: entitySource(type),
    );
  }

  CoachMemory goalMemory() {
    final timestamp = DateTime(2026, 7, 12);
    return CoachMemory(
      key: 'goal.primary',
      value: 'عضله‌سازی',
      category: MemoryCategory.goal,
      confidence: 0.9,
      importance: MemoryImportance.high,
      source: MemorySource.inference,
      createdAt: timestamp,
      updatedAt: timestamp,
      editable: true,
      userEditable: true,
      aiGenerated: false,
    );
  }

  group('CoachKnowledgeRanker', () {
    const ranker = CoachKnowledgeRanker();
    const graph = KnowledgeGraph();

    test('ranks intent-matched workout generation above unrelated nodes', () {
      final ranked = ranker.rank(
        input: CoachKnowledgeRankingInput(
          intent: AIIntent.workoutGeneration,
          coachContext: richWorkoutContext(),
          entities: <NormalizedEntity>[
            normalizedEntity(EntityType.goal),
            normalizedEntity(EntityType.equipment),
          ],
          memories: <CoachMemory>[goalMemory()],
        ),
        nodes: graph.allNodes,
      );

      expect(ranked, isNotEmpty);
      expect(ranked.first.node.id, 'workout_generation');
      expect(ranked.first.trace.matchedIntent, isTrue);
      expect(ranked.first.trace.matchedGoals, isNotEmpty);
      expect(ranked.first.trace.matchedEquipment, isNotEmpty);
      expect(ranked.first.trace.matchedRestrictions, isNotEmpty);
      expect(ranked.first.trace.matchedMemory, isNotEmpty);
      expect(ranked.first.trace.matchedEntities, contains('goal'));
      expect(ranked.first.trace.reasons, isNotEmpty);
    });

    test('entity overlap contributes to trace explainability', () {
      final ranked = ranker.rank(
        input: CoachKnowledgeRankingInput(
          intent: AIIntent.workoutGeneration,
          coachContext: richWorkoutContext(),
          entities: <NormalizedEntity>[normalizedEntity(EntityType.injury)],
        ),
        nodes: graph.allNodes,
      );

      final workoutTrace = ranked
          .firstWhere((entry) => entry.node.id == 'workout_generation')
          .trace;
      expect(workoutTrace.matchedEntities, contains('injury'));
      expect(
        workoutTrace.reasons.any((reason) => reason.contains('entity overlap')),
        isTrue,
      );
    });

    test('priority boost increases score for requirement-heavy nodes', () {
      const weights = CoachKnowledgeRankingWeights(knowledgePriority: 0.5);
      const priorityRanker = CoachKnowledgeRanker(weights: weights);
      final sparseContext = CoachContext.empty();

      final ranked = priorityRanker.rank(
        input: CoachKnowledgeRankingInput(
          intent: AIIntent.generalChat,
          coachContext: sparseContext,
        ),
        nodes: graph.allNodes,
      );

      final general = ranked.firstWhere((entry) => entry.node.id == 'general_chat');
      expect(
        general.trace.reasons.any((reason) => reason.contains('priority')),
        isTrue,
      );
    });
  });

  group('CoachKnowledgeSelector', () {
    const selector = CoachKnowledgeSelector();
    const ranker = CoachKnowledgeRanker();
    const graph = KnowledgeGraph();

    test('selects best node when score meets minimum threshold', () {
      final ranked = ranker.rank(
        input: CoachKnowledgeRankingInput(
          intent: AIIntent.workoutToday,
          coachContext: richWorkoutContext(intent: AIIntent.workoutToday),
        ),
        nodes: graph.allNodes,
      );

      final selected = selector.selectBest(ranked);
      expect(selected, isNotNull);
      expect(selected!.node.id, 'workout_today');
    });

    test('returns null when every candidate is below minimum score', () {
      final ranked = ranker.rank(
        input: CoachKnowledgeRankingInput(
          intent: AIIntent.generalChat,
          coachContext: CoachContext.empty(),
        ),
        nodes: <KnowledgeNode>[KnowledgeRegistry.nodes['program_review']!],
      );

      final selected = selector.selectBest(ranked);
      expect(selected, isNull);
    });
  });

  group('CoachKnowledgeValidator', () {
    const validator = CoachKnowledgeValidator();
    const graph = KnowledgeGraph();
    const ranker = CoachKnowledgeRanker();

    test('falls back to general_chat without throwing', () {
      final ranked = ranker.rank(
        input: CoachKnowledgeRankingInput(
          intent: AIIntent.generalChat,
          coachContext: CoachContext.empty(),
        ),
        nodes: <KnowledgeNode>[KnowledgeRegistry.nodes['program_review']!],
      );

      final result = validator.validate(
        graph: graph,
        selected: null,
        ranked: ranked,
        executionTime: const Duration(milliseconds: 2),
      );

      expect(result.selectedNode.id, 'general_chat');
      expect(result.usedFallback, isTrue);
      expect(result.reasons.any((reason) => reason.contains('Fell back')), isTrue);
      expect(result.trace.usedFallback, isTrue);
      expect(result.trace.nodeTraces, isNotEmpty);
    });

    test('builds explainable reasons for accepted selection', () {
      final ranked = ranker.rank(
        input: CoachKnowledgeRankingInput(
          intent: AIIntent.workoutGeneration,
          coachContext: richWorkoutContext(),
        ),
        nodes: graph.allNodes,
      );
      final selected = ranked.first;

      final result = validator.validate(
        graph: graph,
        selected: selected,
        ranked: ranked,
        executionTime: const Duration(milliseconds: 3),
      );

      expect(result.usedFallback, isFalse);
      expect(result.selectedNode.id, 'workout_generation');
      expect(result.confidence, greaterThan(0.35));
      expect(
        result.reasons.any((reason) => reason.contains('workout_generation')),
        isTrue,
      );
      expect(result.trace.selectedNodeId, 'workout_generation');
    });
  });

  group('CoachKnowledgeRuntime', () {
    const runtime = CoachKnowledgeRuntime();

    test('resolve returns null when Coach v2 flag is disabled', () {
      if (CoachV2Config.coachV2Enabled) return;

      final result = runtime.resolve(
        intent: AIIntent.workoutGeneration,
        coachContext: richWorkoutContext(),
      );

      expect(result, isNull);
    });

    test('resolve selects knowledge when Coach v2 flag is enabled', () {
      if (!CoachV2Config.coachV2Enabled) return;

      final result = runtime.resolve(
        intent: AIIntent.workoutGeneration,
        coachContext: richWorkoutContext(),
        entities: <NormalizedEntity>[
          normalizedEntity(EntityType.goal),
          normalizedEntity(EntityType.equipment),
        ],
        memories: <CoachMemory>[goalMemory()],
      );

      expect(result, isNotNull);
      expect(result!.selectedNode.id, 'workout_generation');
      expect(result.candidateNodes, isNotEmpty);
      expect(result.trace.nodeTraces, isNotEmpty);
      expect(result.reasons, isNotEmpty);
    });
  });
}
