import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/coach_conversation_summary.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_stage.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_planner.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_priority.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_section.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_validator.dart';
import 'package:gymaipro/ai/prompt/prompt_budget.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';

void main() {
  final metadata = CoachContextMetadata(
    buildTime: DateTime(2026, 7, 12),
    sourceCount: 8,
    missingProviders: const {},
    confidence: 0.9,
    contextVersion: CoachContext.contextVersion,
  );

  CoachMemory memory(String key, MemoryImportance importance) {
    final now = DateTime(2026, 7, 12);
    return CoachMemory(
      key: key,
      value: 'value $key',
      category: MemoryCategory.goal,
      confidence: 0.8,
      importance: importance,
      source: MemorySource.user,
      createdAt: now,
      updatedAt: now,
      editable: true,
      userEditable: true,
      aiGenerated: false,
    );
  }

  CoachContext richContext() {
    return CoachContext(
      intent: AIIntent.workoutGeneration,
      metadata: metadata,
      profile: const <String, Object?>{'age': 30, 'weight': 80},
      goals: const <String>['muscle gain'],
      restrictions: const <String>['shoulder pain'],
      equipment: const <String>['dumbbells', 'pull-up bar'],
      activeProgram: const <String, Object?>{'name': 'Strength'},
      weeklyHeatmap: const WeeklyMuscleHeatmapResult(
        targets: <String, int>{'chest': 20, 'quads': 12},
        previousWeekTargets: <String, int>{'chest': 16},
        workoutDays: 4,
        sessionCount: 4,
        previousSessionCount: 3,
        hasHeatmapData: true,
        hasPreviousWeekData: true,
        balanceLine: 'balanced',
        weekTrendLine: 'up',
      ),
      memories: <CoachMemory>[
        memory('critical', MemoryImportance.critical),
        memory('high', MemoryImportance.high),
        memory('medium', MemoryImportance.medium),
        memory('low_1', MemoryImportance.low),
        memory('low_2', MemoryImportance.low),
      ],
      currentQuestion: 'Build me a workout plan for muscle gain.',
      conversationSummary: const CoachConversationSummary(
        summary:
            'User asked several follow-up questions about workouts, equipment, recovery, preferences, and progression.',
        messageCount: 12,
        placeholder: false,
      ),
    );
  }

  group('CoachPromptPlanner', () {
    const planner = CoachPromptPlanner();

    test('calculates prompt budget and remaining tokens', () {
      final plan = planner.plan(
        CoachPromptPlanningRequest(coachContext: richContext()),
      );

      expect(plan.budget.maxTokens, PromptBudget.standard.maxTokens);
      expect(plan.budget.availablePromptTokens, 2800);
      expect(plan.estimatedTokens, greaterThan(0));
      expect(plan.budget.remainingTokens, 2800 - plan.estimatedTokens);
    });

    test('sorts sections by priority', () {
      final plan = planner.plan(
        CoachPromptPlanningRequest(coachContext: richContext()),
      );

      expect(plan.sections.first.priority, CoachPromptPriority.critical);
      final ranks = plan.sections.map((section) => section.priority.rank).toList();
      expect(ranks, orderedEquals(List<int>.from(ranks)..sort((a, b) => b.compareTo(a))));
    });

    test('compresses conversation before removals under tight budget', () {
      final plan = planner.plan(
        CoachPromptPlanningRequest(
          coachContext: richContext(),
          budget: const PromptBudget(
            maxTokens: 760,
            reservedResponseTokens: 200,
            maxEstimatedCost: 1,
          ),
        ),
      );

      expect(
        plan.compressedSections.map((section) => section.type),
        contains(CoachPromptSectionType.conversation),
      );
      expect(
        plan.trace.sectionTraces.any(
          (trace) => trace.sectionId == 'conversation.summary' && trace.compressed,
        ),
        isTrue,
      );
    });

    test('removes heatmap before critical sections', () {
      final plan = planner.plan(
        CoachPromptPlanningRequest(
          coachContext: richContext(),
          budget: const PromptBudget(
            maxTokens: 760,
            reservedResponseTokens: 200,
            maxEstimatedCost: 1,
          ),
        ),
      );

      expect(
        plan.removedSections.map((section) => section.type),
        contains(CoachPromptSectionType.heatmap),
      );
      expect(
        plan.sections.map((section) => section.type),
        containsAll(<CoachPromptSectionType>[
          CoachPromptSectionType.system,
          CoachPromptSectionType.currentQuestion,
        ]),
      );
    });

    test('compresses workout history under tight budget', () {
      final plan = planner.plan(
        CoachPromptPlanningRequest(
          coachContext: richContext(),
          budget: const PromptBudget(
            maxTokens: 760,
            reservedResponseTokens: 200,
            maxEstimatedCost: 1,
          ),
        ),
      );

      expect(
        plan.compressedSections.map((section) => section.type),
        contains(CoachPromptSectionType.workout),
      );
    });

    test('keeps only most important memory items when compressed', () {
      final plan = planner.plan(
        CoachPromptPlanningRequest(
          coachContext: richContext(),
          budget: const PromptBudget(
            maxTokens: 720,
            reservedResponseTokens: 200,
            maxEstimatedCost: 1,
          ),
        ),
      );

      final memorySection = plan.sections.firstWhere(
        (section) => section.type == CoachPromptSectionType.memory,
      );
      expect(memorySection.compressed, isTrue);
      expect(memorySection.content, isA<List<Object?>>());
      expect(memorySection.content as List<Object?>, hasLength(3));
    });

    test('generates trace for selected and removed sections', () {
      final plan = planner.plan(
        CoachPromptPlanningRequest(
          coachContext: richContext(),
          budget: const PromptBudget(
            maxTokens: 760,
            reservedResponseTokens: 200,
            maxEstimatedCost: 1,
          ),
        ),
      );

      expect(plan.trace.sectionTraces, isNotEmpty);
      expect(
        plan.trace.sectionTraces.any((trace) => trace.removed),
        isTrue,
      );
    });
  });

  group('CoachPromptValidator', () {
    const planner = CoachPromptPlanner();
    const validator = CoachPromptValidator();

    test('accepts valid plans with critical sections', () {
      final plan = planner.plan(
        CoachPromptPlanningRequest(coachContext: richContext()),
      );

      final result = validator.validate(plan);

      expect(result.isValid, isTrue);
    });

    test('rejects plan without current question', () {
      final plan = planner.plan(
        CoachPromptPlanningRequest(
          coachContext: CoachContext(
            intent: AIIntent.generalChat,
            metadata: metadata,
          ),
        ),
      );

      final result = validator.validate(plan);

      expect(result.isValid, isFalse);
      expect(result.issues.join(' '), contains('Current question'));
    });
  });

  group('CoachPipeline prompt planning stage', () {
    test('runs before prompt builder', () {
      expect(
        CoachPipelineConfig.defaultExecutionOrder,
        containsAllInOrder(<CoachPipelineStage>[
          CoachPipelineStage.promptPlanning,
          CoachPipelineStage.prompt,
        ]),
      );
    });
  });
}
