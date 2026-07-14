import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/coach/coach_reason.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/planner/response_priority.dart';
import 'package:gymaipro/ai/strategy/coach_strategy.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_reason.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_type.dart';

/// Builds immutable [CoachStrategy] objects from coach inputs.
///
/// The builder is deterministic and data-only. It never calls OpenAI, APIs,
/// prompts, or UI layers.
class CoachStrategyBuilder {
  const CoachStrategyBuilder();

  /// Transforms [context], [knowledgeNode], and [decision] into a strategy.
  CoachStrategy build({
    required CoachContext context,
    required KnowledgeNode knowledgeNode,
    required CoachDecision decision,
  }) {
    final safetyFlags = _detectSafetyFlags(
      context: context,
      knowledgeNode: knowledgeNode,
      decision: decision,
    );
    final reasoning = _buildReasoning(
      context: context,
      knowledgeNode: knowledgeNode,
      decision: decision,
      safetyFlags: safetyFlags,
    );
    final nextAction = _resolveNextAction(
      knowledgeNode: knowledgeNode,
      decision: decision,
      safetyFlags: safetyFlags,
    );
    final requiresAI = nextAction == CoachAction.callOpenAI;
    final requiresFollowUp =
        nextAction == CoachAction.followUp || decision.requiresFollowUp;
    final strategyType = _resolveStrategyType(
      context: context,
      knowledgeNode: knowledgeNode,
      decision: decision,
      nextAction: nextAction,
      safetyFlags: safetyFlags,
    );
    final recommendationType = _resolveRecommendationType(
      knowledgeNode: knowledgeNode,
      nextAction: nextAction,
      strategyType: strategyType,
    );
    final tone = _resolveTone(
      context: context,
      knowledgeNode: knowledgeNode,
      safetyFlags: safetyFlags,
    );
    final priority = _resolvePriority(
      strategyType: strategyType,
      requiresFollowUp: requiresFollowUp,
      safetyFlags: safetyFlags,
    );
    final confidence = _blendConfidence(context: context, decision: decision);
    final blockedActions = _resolveBlockedActions(
      decision: decision,
      nextAction: nextAction,
      safetyFlags: safetyFlags,
      requiresFollowUp: requiresFollowUp,
    );
    final availableActions = _resolveAvailableActions(
      knowledgeNode: knowledgeNode,
      nextAction: nextAction,
      blockedActions: blockedActions,
    );

    return CoachStrategy(
      primaryGoal: knowledgeNode.title,
      strategyType: strategyType,
      requiresAI: requiresAI,
      requiresFollowUp: requiresFollowUp,
      recommendationType: recommendationType,
      tone: tone,
      priority: priority,
      confidence: confidence,
      reasoning: reasoning,
      nextAction: nextAction,
      safetyFlags: safetyFlags,
      blockedActions: blockedActions,
      availableActions: availableActions,
      notes: _buildNotes(
        context: context,
        knowledgeNode: knowledgeNode,
        decision: decision,
      ),
    );
  }

  Set<CoachSafetyFlag> _detectSafetyFlags({
    required CoachContext context,
    required KnowledgeNode knowledgeNode,
    required CoachDecision decision,
  }) {
    final flags = <CoachSafetyFlag>{};

    if (context.restrictions.isNotEmpty) {
      flags.add(CoachSafetyFlag.medicalRestrictionsPresent);
    } else if (_isMedicalSensitiveIntent(knowledgeNode.intent)) {
      flags.add(CoachSafetyFlag.missingRestrictionsData);
    }

    if (knowledgeNode.intent == AIIntent.workoutGeneration &&
        decision.missingData.isNotEmpty) {
      flags.add(CoachSafetyFlag.workoutGenerationBlocked);
    }

    if (context.metadata.confidence > 0 && context.metadata.confidence < 0.5) {
      flags.add(CoachSafetyFlag.lowContextConfidence);
    }

    if (decision.missingProviders.isNotEmpty) {
      flags.add(CoachSafetyFlag.providerGap);
    }

    final usageLimited =
        context.apiUsage['is_limited'] == true ||
        context.apiUsage['rate_limited'] == true;
    if (usageLimited) {
      flags.add(CoachSafetyFlag.apiUsageLimited);
    }

    return Set<CoachSafetyFlag>.unmodifiable(flags);
  }

  Set<CoachStrategyReason> _buildReasoning({
    required CoachContext context,
    required KnowledgeNode knowledgeNode,
    required CoachDecision decision,
    required Set<CoachSafetyFlag> safetyFlags,
  }) {
    final reasons = <CoachStrategyReason>{};

    for (final reason in decision.decisionReason) {
      reasons.addAll(_mapDecisionReason(reason));
    }

    if (decision.shouldCallAI) {
      reasons.add(CoachStrategyReason.decisionRequiresAi);
    }
    if (decision.requiresFollowUp) {
      reasons.add(CoachStrategyReason.decisionRequiresFollowUp);
    }
    if (decision.hasLocalResponse) {
      reasons.add(CoachStrategyReason.decisionLocalResponse);
    }
    if (knowledgeNode.requiresAI) {
      reasons.add(CoachStrategyReason.knowledgeRequiresAi);
    }
    reasons
      ..add(CoachStrategyReason.knowledgeDefaultAction)
      ..add(CoachStrategyReason.knowledgeMissingBehaviour);
    if (decision.missingData.isEmpty && decision.missingProviders.isEmpty) {
      reasons.add(CoachStrategyReason.sufficientContext);
    } else {
      reasons.add(CoachStrategyReason.insufficientContext);
    }
    if (safetyFlags.contains(CoachSafetyFlag.medicalRestrictionsPresent) ||
        safetyFlags.contains(CoachSafetyFlag.missingRestrictionsData) ||
        safetyFlags.contains(CoachSafetyFlag.workoutGenerationBlocked)) {
      reasons.add(CoachStrategyReason.medicalSafety);
    }
    if (decision.missingProviders.isNotEmpty) {
      reasons.add(CoachStrategyReason.providerMissing);
    }
    if (decision.decisionReason.contains(CoachReason.localAnswer)) {
      reasons.add(CoachStrategyReason.localRoutePreferred);
    }
    if (decision.decisionReason.contains(CoachReason.validationFailed)) {
      reasons.add(CoachStrategyReason.validationBlocked);
    }
    if (decision.decisionReason.contains(CoachReason.lowConfidence) ||
        safetyFlags.contains(CoachSafetyFlag.lowContextConfidence)) {
      reasons.add(CoachStrategyReason.lowConfidenceContext);
    }
    if (knowledgeNode.intent == null ||
        knowledgeNode.intent == context.intent) {
      reasons.add(CoachStrategyReason.intentAligned);
    }
    if (context.metadata.confidence > 0 && context.metadata.confidence < 0.6) {
      reasons.add(CoachStrategyReason.contextMetadataWeak);
    }

    return Set<CoachStrategyReason>.unmodifiable(reasons);
  }

  Iterable<CoachStrategyReason> _mapDecisionReason(CoachReason reason) {
    switch (reason) {
      case CoachReason.needMoreProfile:
      case CoachReason.needWorkoutProgram:
      case CoachReason.needWorkoutLogs:
      case CoachReason.needCurrentQuestion:
      case CoachReason.needGoals:
        return const <CoachStrategyReason>[
          CoachStrategyReason.insufficientContext,
        ];
      case CoachReason.needRestrictions:
        return const <CoachStrategyReason>[
          CoachStrategyReason.insufficientContext,
          CoachStrategyReason.medicalSafety,
        ];
      case CoachReason.enoughContext:
        return const <CoachStrategyReason>[
          CoachStrategyReason.sufficientContext,
        ];
      case CoachReason.localAnswer:
        return const <CoachStrategyReason>[
          CoachStrategyReason.localRoutePreferred,
        ];
      case CoachReason.openAIRequired:
        return const <CoachStrategyReason>[
          CoachStrategyReason.decisionRequiresAi,
        ];
      case CoachReason.validationFailed:
        return const <CoachStrategyReason>[
          CoachStrategyReason.validationBlocked,
        ];
      case CoachReason.missingProvider:
        return const <CoachStrategyReason>[CoachStrategyReason.providerMissing];
      case CoachReason.lowConfidence:
        return const <CoachStrategyReason>[
          CoachStrategyReason.lowConfidenceContext,
        ];
      case CoachReason.unsupportedLocalResponse:
        return const <CoachStrategyReason>[
          CoachStrategyReason.insufficientContext,
        ];
    }
  }

  CoachAction _resolveNextAction({
    required KnowledgeNode knowledgeNode,
    required CoachDecision decision,
    required Set<CoachSafetyFlag> safetyFlags,
  }) {
    if (decision.missingProviders.isNotEmpty) {
      return CoachAction.error;
    }
    if (decision.requiresFollowUp) {
      return CoachAction.followUp;
    }
    if (safetyFlags.contains(CoachSafetyFlag.workoutGenerationBlocked)) {
      return CoachAction.followUp;
    }
    if (decision.shouldCallAI) {
      return CoachAction.callOpenAI;
    }
    if (decision.hasLocalResponse) {
      return CoachAction.localResponse;
    }

    final defaultAction = knowledgeNode.defaultAction;
    if (!decision.shouldCallAI && defaultAction == CoachAction.callOpenAI) {
      return CoachAction.localResponse;
    }
    return defaultAction;
  }

  CoachStrategyType _resolveStrategyType({
    required CoachContext context,
    required KnowledgeNode knowledgeNode,
    required CoachDecision decision,
    required CoachAction nextAction,
    required Set<CoachSafetyFlag> safetyFlags,
  }) {
    if (decision.missingProviders.isNotEmpty) {
      return CoachStrategyType.errorFallback;
    }
    if (safetyFlags.contains(CoachSafetyFlag.workoutGenerationBlocked) ||
        (safetyFlags.contains(CoachSafetyFlag.missingRestrictionsData) &&
            _isMedicalSensitiveIntent(knowledgeNode.intent))) {
      return CoachStrategyType.safetyGate;
    }
    if (decision.requiresFollowUp || nextAction == CoachAction.followUp) {
      return CoachStrategyType.followUpCollection;
    }
    if (decision.shouldCallAI || nextAction == CoachAction.callOpenAI) {
      return CoachStrategyType.aiCoaching;
    }
    if (decision.hasLocalResponse || nextAction == CoachAction.localResponse) {
      return CoachStrategyType.localGuidance;
    }

    switch (knowledgeNode.intent ?? context.intent) {
      case AIIntent.workoutToday:
        return CoachStrategyType.programFocus;
      case AIIntent.progressAnalysis:
        return CoachStrategyType.progressReview;
      case AIIntent.recovery:
        return CoachStrategyType.recoveryFocus;
      case AIIntent.motivation:
        return CoachStrategyType.localGuidance;
      case AIIntent.workoutGeneration:
      case AIIntent.workoutModification:
      case AIIntent.exerciseQuestion:
      case AIIntent.workoutQuestion:
      case AIIntent.nutrition:
      case AIIntent.supplement:
      case AIIntent.generalFitness:
      case AIIntent.generalChat:
      case AIIntent.appHelp:
      case AIIntent.bugReport:
      case AIIntent.feedback:
        return _strategyTypeFromAction(nextAction);
    }
  }

  CoachStrategyType _strategyTypeFromAction(CoachAction nextAction) {
    if (nextAction == CoachAction.showProgram) {
      return CoachStrategyType.programFocus;
    }
    if (nextAction == CoachAction.showProgress) {
      return CoachStrategyType.progressReview;
    }
    return CoachStrategyType.conversational;
  }

  CoachRecommendationType _resolveRecommendationType({
    required KnowledgeNode knowledgeNode,
    required CoachAction nextAction,
    required CoachStrategyType strategyType,
  }) {
    if (strategyType == CoachStrategyType.followUpCollection ||
        strategyType == CoachStrategyType.safetyGate) {
      return CoachRecommendationType.collectData;
    }

    switch (nextAction) {
      case CoachAction.callOpenAI:
        return knowledgeNode.requiresAI
            ? CoachRecommendationType.coach
            : CoachRecommendationType.answer;
      case CoachAction.followUp:
        return CoachRecommendationType.collectData;
      case CoachAction.localResponse:
        return CoachRecommendationType.explain;
      case CoachAction.showProgram:
      case CoachAction.showHeatmap:
      case CoachAction.showProgress:
      case CoachAction.showRecovery:
      case CoachAction.showChat:
        return CoachRecommendationType.navigate;
      case CoachAction.error:
        return CoachRecommendationType.defer;
    }
  }

  CoachStrategyTone _resolveTone({
    required CoachContext context,
    required KnowledgeNode knowledgeNode,
    required Set<CoachSafetyFlag> safetyFlags,
  }) {
    if (safetyFlags.contains(CoachSafetyFlag.medicalRestrictionsPresent) ||
        safetyFlags.contains(CoachSafetyFlag.missingRestrictionsData) ||
        safetyFlags.contains(CoachSafetyFlag.workoutGenerationBlocked)) {
      return CoachStrategyTone.cautious;
    }

    switch (knowledgeNode.intent ?? context.intent) {
      case AIIntent.motivation:
        return CoachStrategyTone.motivational;
      case AIIntent.appHelp:
      case AIIntent.bugReport:
      case AIIntent.feedback:
        return CoachStrategyTone.direct;
      case AIIntent.exerciseQuestion:
      case AIIntent.workoutQuestion:
      case AIIntent.generalFitness:
        return CoachStrategyTone.educational;
      case AIIntent.generalChat:
      case AIIntent.nutrition:
      case AIIntent.supplement:
      case AIIntent.workoutGeneration:
      case AIIntent.workoutToday:
      case AIIntent.workoutModification:
      case AIIntent.progressAnalysis:
      case AIIntent.recovery:
        return CoachStrategyTone.supportive;
    }
  }

  ResponsePriority _resolvePriority({
    required CoachStrategyType strategyType,
    required bool requiresFollowUp,
    required Set<CoachSafetyFlag> safetyFlags,
  }) {
    if (requiresFollowUp ||
        strategyType == CoachStrategyType.safetyGate ||
        strategyType == CoachStrategyType.followUpCollection) {
      return ResponsePriority.immediate;
    }
    if (strategyType == CoachStrategyType.errorFallback) {
      return ResponsePriority.high;
    }
    if (safetyFlags.contains(CoachSafetyFlag.providerGap)) {
      return ResponsePriority.high;
    }
    if (strategyType == CoachStrategyType.aiCoaching) {
      return ResponsePriority.high;
    }
    if (strategyType == CoachStrategyType.localGuidance) {
      return ResponsePriority.medium;
    }
    return ResponsePriority.medium;
  }

  double _blendConfidence({
    required CoachContext context,
    required CoachDecision decision,
  }) {
    final contextConfidence = context.metadata.confidence;
    if (contextConfidence <= 0) {
      return decision.confidence.clamp(0, 1);
    }
    final blended = decision.confidence * contextConfidence;
    return blended.clamp(0, 1);
  }

  Set<CoachAction> _resolveBlockedActions({
    required CoachDecision decision,
    required CoachAction nextAction,
    required Set<CoachSafetyFlag> safetyFlags,
    required bool requiresFollowUp,
  }) {
    final blocked = <CoachAction>{};

    if (requiresFollowUp || nextAction == CoachAction.followUp) {
      blocked
        ..add(CoachAction.callOpenAI)
        ..add(CoachAction.showProgram)
        ..add(CoachAction.showHeatmap)
        ..add(CoachAction.showProgress)
        ..add(CoachAction.showRecovery);
    }

    if (safetyFlags.contains(CoachSafetyFlag.workoutGenerationBlocked)) {
      blocked.add(CoachAction.callOpenAI);
    }

    if (decision.missingProviders.isNotEmpty ||
        nextAction == CoachAction.error) {
      blocked.addAll(
        CoachAction.values.where((action) => action != CoachAction.error),
      );
    }

    if (safetyFlags.contains(CoachSafetyFlag.apiUsageLimited) &&
        !decision.shouldCallAI) {
      blocked.add(CoachAction.callOpenAI);
    }

    return Set<CoachAction>.unmodifiable(blocked);
  }

  Set<CoachAction> _resolveAvailableActions({
    required KnowledgeNode knowledgeNode,
    required CoachAction nextAction,
    required Set<CoachAction> blockedActions,
  }) {
    final candidates = <CoachAction>{
      nextAction,
      knowledgeNode.defaultAction,
      CoachAction.followUp,
      CoachAction.localResponse,
      CoachAction.callOpenAI,
      CoachAction.showProgram,
      CoachAction.showHeatmap,
      CoachAction.showProgress,
      CoachAction.showRecovery,
      CoachAction.showChat,
    }..removeWhere(blockedActions.contains);

    if (nextAction == CoachAction.error) {
      return const <CoachAction>{CoachAction.error};
    }

    return Set<CoachAction>.unmodifiable(candidates);
  }

  List<String> _buildNotes({
    required CoachContext context,
    required KnowledgeNode knowledgeNode,
    required CoachDecision decision,
  }) {
    return List<String>.unmodifiable(<String>[
      'Strategy built for knowledge node ${knowledgeNode.id}.',
      'Resolved intent: ${context.intent.name}.',
      if (decision.notes.isNotEmpty) ...decision.notes,
      if (knowledgeNode.recommendedFollowUp.isNotEmpty)
        'Knowledge follow-up: ${knowledgeNode.recommendedFollowUp}',
    ]);
  }

  bool _isMedicalSensitiveIntent(AIIntent? intent) {
    return intent == AIIntent.workoutGeneration ||
        intent == AIIntent.workoutModification ||
        intent == AIIntent.nutrition ||
        intent == AIIntent.recovery;
  }
}
