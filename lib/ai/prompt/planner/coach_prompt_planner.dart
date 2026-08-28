import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_engine_facts.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_budget.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_optimizer.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_plan.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_priority.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_section.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_trace.dart';
import 'package:gymaipro/ai/prompt/prompt_budget.dart';
import 'package:gymaipro/ai/prompt/prompt_personality.dart';
import 'package:gymaipro/ai/prompt/prompt_version.dart';
import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_engine.dart';
import 'package:gymaipro/features/product_experience/domain/coach_decision_lock.dart';
import 'package:gymaipro/features/product_experience/domain/coach_user_card.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// Input for prompt planning.
class CoachPromptPlanningRequest {
  const CoachPromptPlanningRequest({
    required this.coachContext,
    this.knowledgeResult,
    this.strategyResult,
    this.conversationState,
    this.budget = PromptBudget.standard,
    this.personality = PromptPersonality.gymAiCoach,
    this.version = PromptVersion.v1,
    this.createdAt,
    this.decisionLock,
  });

  final CoachContext coachContext;
  final CoachKnowledgeResult? knowledgeResult;
  final CoachStrategyResult? strategyResult;
  final CoachConversationState? conversationState;
  final PromptBudget budget;
  final PromptPersonality personality;
  final PromptVersion version;
  final DateTime? createdAt;

  /// Locked numeric decisions / debrief / observations for LLM citation only.
  final Map<String, Object?>? decisionLock;
}

/// Builds token-aware prompt plans from Coach v2 runtime state.
class CoachPromptPlanner {
  const CoachPromptPlanner({
    CoachPromptOptimizer optimizer = const CoachPromptOptimizer(),
  }) : _optimizer = optimizer;

  final CoachPromptOptimizer _optimizer;

  CoachPromptPlan plan(CoachPromptPlanningRequest request) {
    final stopwatch = Stopwatch()..start();
    final initialSections = _initialSections(request);
    final baseBudget = CoachPromptBudget(
      maxTokens: request.budget.maxTokens,
      reservedForResponse: request.budget.reservedResponseTokens,
      estimatedPromptTokens: _estimatedTokens(initialSections),
    );
    final optimized = _optimizer.optimize(
      sections: initialSections,
      budget: baseBudget,
    );
    final selected = optimized.sections;
    final budget = baseBudget.copyWith(
      estimatedPromptTokens: _estimatedTokens(selected),
    );
    stopwatch.stop();

    final warnings = <String>[
      ...optimized.warnings,
      if (budget.remainingTokens < 0)
        'Prompt budget is still negative after fallback optimization.',
    ];

    return CoachPromptPlan(
      intent: request.coachContext.intent,
      sections: selected,
      priority: _highestPriority(selected),
      estimatedTokens: budget.estimatedPromptTokens,
      removedSections: optimized.removedSections,
      compressedSections: optimized.compressedSections,
      warnings: List<String>.unmodifiable(warnings),
      trace: CoachPromptTrace(
        sectionTraces: _traceFor(
          selected: selected,
          removed: optimized.removedSections,
        ),
        executionTime: stopwatch.elapsed,
      ),
      budget: budget,
      contextKeys: _contextKeys(selected),
      memoryKeys: _memoryKeys(selected),
      knowledgeNode: request.knowledgeResult?.selectedNode,
      personality: request.personality,
      version: request.version,
      createdAt: request.createdAt ?? request.coachContext.metadata.buildTime,
    );
  }

  List<CoachPromptSection> _initialSections(
    CoachPromptPlanningRequest request,
  ) {
    final context = request.coachContext;
    final sections = <CoachPromptSection>[
      const CoachPromptSection(
        id: 'system.coach',
        title: 'System',
        type: CoachPromptSectionType.system,
        content:
            'You are GymAI Coach — a personal Persian fitness and nutrition '
            'coach who knows this user. Ground every answer in the context '
            'sections below (profile, weight trend, nutrition log, workouts, '
            "heatmap); cite the user's own numbers when relevant. Prefer "
            'concrete answers over follow-up questions when the data is '
            'already present. ${CoachDecisionLock.systemRule} '
            '${CoachUserCard.systemRule}',
        priority: CoachPromptPriority.critical,
        estimatedTokens: 280,
        required: true,
      ),
    ];

    final lock = request.decisionLock ?? CoachDecisionLock.buildPackage();
    sections.add(
      CoachPromptSection(
        id: CoachDecisionLock.sectionId,
        title: 'Decision Lock',
        type: CoachPromptSectionType.restrictions,
        content: lock,
        priority: CoachPromptPriority.critical,
        estimatedTokens: 180,
        required: true,
      ),
    );

    final userCard = CoachUserCard.fromContext(context, decisionLock: lock);
    sections.add(
      CoachPromptSection(
        id: CoachUserCard.sectionId,
        title: 'User Card',
        type: CoachPromptSectionType.userCard,
        content: userCard.toPromptContent(),
        priority: CoachPromptPriority.critical,
        estimatedTokens: 160,
        required: true,
      ),
    );

    final knowledgeNode = request.knowledgeResult?.selectedNode;
    if (knowledgeNode != null) {
      sections.add(
        CoachPromptSection(
          id: 'knowledge.${knowledgeNode.id}',
          title: 'Knowledge',
          type: CoachPromptSectionType.knowledge,
          content: <String, Object?>{
            'id': knowledgeNode.id,
            'title': knowledgeNode.title,
            'description': knowledgeNode.description,
            'reasons': request.knowledgeResult?.reasons,
          },
          priority: CoachPromptPriority.high,
          estimatedTokens: 140,
          required: true,
        ),
      );
    }

    final question = context.currentQuestion;
    if (question != null && question.trim().isNotEmpty) {
      sections.add(
        CoachPromptSection(
          id: 'context.current_question',
          title: 'Current Question',
          type: CoachPromptSectionType.currentQuestion,
          content: question,
          priority: CoachPromptPriority.critical,
          estimatedTokens: _estimate(question, fallback: 80),
          providerKey: AIContextProviderKey.currentQuestion,
          required: true,
        ),
      );
    }

    if (context.memories.isNotEmpty) {
      final memories = List.of(context.memories)
        ..sort((a, b) {
          final importance = b.importance.rank.compareTo(a.importance.rank);
          if (importance != 0) return importance;
          return b.confidence.compareTo(a.confidence);
        });
      sections.add(
        CoachPromptSection(
          id: 'memory.selected',
          title: 'Memory',
          type: CoachPromptSectionType.memory,
          content: memories.map((memory) => memory.toJson()).toList(),
          priority: CoachPromptPriority.high,
          estimatedTokens: 240,
          providerKey: AIContextProviderKey.memory,
        ),
      );
    }

    final conversation = context.conversationSummary;
    if (!conversation.placeholder || conversation.summary != null) {
      sections.add(
        CoachPromptSection(
          id: 'conversation.summary',
          title: 'Conversation',
          type: CoachPromptSectionType.conversation,
          content: <String, Object?>{
            'summary': conversation.summary,
            'messageCount': conversation.messageCount,
          },
          priority: CoachPromptPriority.low,
          estimatedTokens: _estimate(conversation.summary ?? '', fallback: 180),
        ),
      );
    }

    if (context.profile.isNotEmpty) {
      sections.add(
        _contextSection(
          id: 'context.profile',
          title: 'User Profile',
          type: CoachPromptSectionType.userProfile,
          content: context.profile,
          providerKey: AIContextProviderKey.profile,
          priority: CoachPromptPriority.high,
          estimatedTokens: 220,
        ),
      );
    }
    if (context.goals.isNotEmpty) {
      sections.add(
        _contextSection(
          id: 'context.goals',
          title: 'Goals',
          type: CoachPromptSectionType.goals,
          content: context.goals,
          providerKey: AIContextProviderKey.goals,
          priority: CoachPromptPriority.high,
          estimatedTokens: 90,
        ),
      );
    }
    if (context.restrictions.isNotEmpty) {
      sections.add(
        _contextSection(
          id: 'context.restrictions',
          title: 'Restrictions',
          type: CoachPromptSectionType.restrictions,
          content: context.restrictions,
          providerKey: AIContextProviderKey.restrictions,
          priority: CoachPromptPriority.high,
          estimatedTokens: 120,
        ),
      );
    }
    if (context.equipment.isNotEmpty) {
      sections.add(
        _contextSection(
          id: 'context.equipment',
          title: 'Equipment',
          type: CoachPromptSectionType.equipment,
          content: context.equipment,
          providerKey: AIContextProviderKey.equipment,
          priority: CoachPromptPriority.medium,
          estimatedTokens: 90,
        ),
      );
    }
    if (context.activeProgram != null || context.workoutHistory.isNotEmpty) {
      sections.add(
        _contextSection(
          id: 'context.workout',
          title: 'Workout',
          type: CoachPromptSectionType.workout,
          content: <String, Object?>{
            'activeProgram': context.activeProgram,
            'historyCount': context.workoutHistory.length,
            'recentSessions': _recentWorkoutSummary(context.workoutHistory),
          },
          providerKey: AIContextProviderKey.workoutHistory,
          priority: CoachPromptPriority.medium,
          estimatedTokens: 320,
        ),
      );
    }
    if (context.nutrition.isNotEmpty) {
      sections.add(
        _contextSection(
          id: 'context.nutrition',
          title: 'Nutrition',
          type: CoachPromptSectionType.nutrition,
          content: context.nutrition,
          providerKey: AIContextProviderKey.nutrition,
          priority: CoachPromptPriority.high,
          estimatedTokens: 220,
        ),
      );
    }
    if (context.preferences.isNotEmpty) {
      sections.add(
        _contextSection(
          id: 'context.preferences',
          title: 'Preferences',
          type: CoachPromptSectionType.preferences,
          content: context.preferences,
          providerKey: AIContextProviderKey.preferences,
          priority: CoachPromptPriority.low,
          estimatedTokens: 160,
        ),
      );
    }
    if (context.weeklyHeatmap != null) {
      final heatmap = context.weeklyHeatmap!;
      sections.add(
        _contextSection(
          id: 'context.heatmap',
          title: 'Heatmap',
          type: CoachPromptSectionType.heatmap,
          content: <String, Object?>{
            'targets_fa': <String, int>{
              for (final entry in heatmap.targets.entries)
                if (entry.value > 0)
                  MuscleTargets.label(entry.key): entry.value,
            },
            'sessionCount': heatmap.sessionCount,
            'workoutDays': heatmap.workoutDays,
            'stimulusTotal': heatmap.stimulusTotal,
            if (heatmap.topMuscleLabel != null)
              'topMuscle': heatmap.topMuscleLabel,
            if (heatmap.lightMuscleLabel != null)
              'lightMuscle': heatmap.lightMuscleLabel,
            if (heatmap.balanceLine != null) 'balanceLine': heatmap.balanceLine,
            if (heatmap.weekTrendLine != null)
              'weekTrendLine': heatmap.weekTrendLine,
            if (heatmap.programGapLine != null)
              'programGapLine': heatmap.programGapLine,
            'activityLine': heatmap.activityLine,
            'label_rule':
                'Use only Persian muscle names from targets_fa. '
                'Never invent muscles (no forehead/پیشانی).',
          },
          providerKey: AIContextProviderKey.heatmap,
          priority: CoachPromptPriority.medium,
          estimatedTokens: 220,
        ),
      );
    }

    final engineFacts = CoachEngineFacts.build(context);
    if (engineFacts != null) {
      sections.add(
        CoachPromptSection(
          id: 'context.engine_facts',
          title: 'Engine Facts',
          type: CoachPromptSectionType.knowledge,
          content: engineFacts,
          priority: CoachPromptPriority.critical,
          estimatedTokens: 260,
          required: true,
        ),
      );
    }

    final state = request.conversationState;
    if (state != null) {
      sections.add(
        CoachPromptSection(
          id: 'state.current',
          title: 'State',
          type: CoachPromptSectionType.state,
          content: <String, Object?>{
            'phase': state.currentPhase.name,
            'pendingQuestions': state.pendingQuestions.length,
            'collectedFields': state.collectedFields,
          },
          priority: CoachPromptPriority.high,
          estimatedTokens: 120,
        ),
      );
    }
    final strategy = request.strategyResult?.strategy;
    if (strategy != null) {
      sections.add(
        CoachPromptSection(
          id: 'strategy.current',
          title: 'Strategy',
          type: CoachPromptSectionType.strategy,
          content: <String, Object?>{
            'primaryGoal': strategy.primaryGoal,
            'strategyType': strategy.strategyType.name,
            'tone': strategy.tone.name,
            'nextAction': strategy.nextAction.name,
            'notes': strategy.notes,
          },
          priority: CoachPromptPriority.high,
          estimatedTokens: 150,
        ),
      );
    }

    return List<CoachPromptSection>.unmodifiable(sections);
  }

  CoachPromptSection _contextSection({
    required String id,
    required String title,
    required CoachPromptSectionType type,
    required Object content,
    required AIContextProviderKey providerKey,
    required CoachPromptPriority priority,
    required int estimatedTokens,
  }) {
    return CoachPromptSection(
      id: id,
      title: title,
      type: type,
      content: content,
      providerKey: providerKey,
      priority: priority,
      estimatedTokens: estimatedTokens,
    );
  }

  /// Compact summary of the last sessions so the model can reference real
  /// training data (dates, day, volume) instead of only a history count.
  List<Map<String, Object?>> _recentWorkoutSummary(
    List<WorkoutDailyLog> history,
  ) {
    final sorted = List<WorkoutDailyLog>.from(history)
      ..sort((a, b) => b.logDate.compareTo(a.logDate));
    final recent = sorted.take(3);

    return <Map<String, Object?>>[
      for (final log in recent)
        <String, Object?>{
          'date': log.logDate.toIso8601String().substring(0, 10),
          'sessions': <Object?>[
            for (final session in log.sessions)
              <String, Object?>{
                'day': session.day,
                'exercises': session.exercises.length,
              },
          ],
        },
    ];
  }

  int _estimate(String content, {required int fallback}) {
    if (content.trim().isEmpty) return fallback;
    return (content.length / 4).ceil().clamp(20, fallback);
  }

  int _estimatedTokens(List<CoachPromptSection> sections) {
    return sections.fold<int>(
      0,
      (total, section) => total + section.estimatedTokens,
    );
  }

  CoachPromptPriority _highestPriority(List<CoachPromptSection> sections) {
    return sections.fold<CoachPromptPriority>(CoachPromptPriority.low, (
      highest,
      section,
    ) {
      return section.priority.rank > highest.rank ? section.priority : highest;
    });
  }

  Set<AIContextProviderKey> _contextKeys(List<CoachPromptSection> sections) {
    return Set<AIContextProviderKey>.unmodifiable(
      sections
          .map((section) => section.providerKey)
          .whereType<AIContextProviderKey>(),
    );
  }

  List<String> _memoryKeys(List<CoachPromptSection> sections) {
    final keys = <String>[];
    for (final section in sections) {
      if (section.type != CoachPromptSectionType.memory) continue;
      final content = section.content;
      if (content is! Iterable<Object?>) continue;
      for (final item in content) {
        if (item is Map<String, Object?>) {
          final key = item['key'];
          if (key is String) keys.add(key);
        }
      }
    }
    return List<String>.unmodifiable(keys);
  }

  List<CoachPromptSectionTrace> _traceFor({
    required List<CoachPromptSection> selected,
    required List<CoachPromptSection> removed,
  }) {
    return List<CoachPromptSectionTrace>.unmodifiable(<CoachPromptSectionTrace>[
      for (final section in selected)
        CoachPromptSectionTrace(
          sectionId: section.id,
          priority: section.priority,
          estimatedTokens: section.estimatedTokens,
          compressed: section.compressed,
          reason: section.reason,
        ),
      for (final section in removed)
        CoachPromptSectionTrace(
          sectionId: section.id,
          priority: section.priority,
          estimatedTokens: section.estimatedTokens,
          removed: true,
          compressed: section.compressed,
          reason: section.reason,
        ),
    ]);
  }
}
