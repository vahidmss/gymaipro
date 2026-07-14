import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/coach/coach_reason.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_runtime.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/planner/coach_response_plan.dart';

/// Coordinates knowledge-driven validation and route decision.
///
/// Coach v2 decisions are sourced from [CoachKnowledgeResult], not
/// AIIntentDefinitions or KnowledgeRegistry lookups.
class CoachBrain {
  const CoachBrain();

  /// Returns a knowledge-driven decision for Coach v2.
  CoachDecision decide({
    required CoachContext context,
    required CoachKnowledgeResult knowledgeResult,
    CoachEntitlementRuntimeResult? entitlementResult,
  }) {
    final node = knowledgeResult.selectedNode;
    final requiredProviders = _requiredProviders(node);
    final missingProviders = _missingProviders(context, requiredProviders);

    if (entitlementResult != null && !entitlementResult.allowed) {
      return _blockedDecision(
        node: node,
        knowledgeResult: knowledgeResult,
        entitlementResult: entitlementResult,
        requiredProviders: requiredProviders,
      );
    }

    if (missingProviders.isNotEmpty) {
      return CoachDecision(
        shouldCallAI: false,
        followUpQuestion: node.recommendedFollowUp,
        missingData: _providerNames(missingProviders),
        requiredProviders: requiredProviders,
        missingProviders: missingProviders,
        decisionReason: const <CoachReason>{
          CoachReason.validationFailed,
          CoachReason.missingProvider,
        },
        confidence: 0.92,
        notes: _notesFor(knowledgeResult, <String>[
          'Knowledge node ${node.id} is missing required context.',
        ]),
        selectedKnowledgeId: node.id,
        knowledgeConfidence: knowledgeResult.confidence,
        knowledgeReasons: knowledgeResult.reasons,
      );
    }

    final shouldCallAI =
        node.requiresAI || node.defaultAction == CoachAction.callOpenAI;
    return CoachDecision(
      shouldCallAI: shouldCallAI,
      localResponse: shouldCallAI ? null : 'Local coach route selected.',
      missingData: const <String>[],
      requiredProviders: requiredProviders,
      missingProviders: const <AIContextProviderKey>{},
      decisionReason: <CoachReason>{
        CoachReason.enoughContext,
        if (shouldCallAI) CoachReason.openAIRequired else CoachReason.localAnswer,
      },
      confidence: knowledgeResult.confidence.clamp(0.0, 1.0),
      notes: _notesFor(knowledgeResult, <String>[
        'Knowledge node ${node.id} selected route source.',
      ]),
      selectedKnowledgeId: node.id,
      knowledgeConfidence: knowledgeResult.confidence,
      knowledgeReasons: knowledgeResult.reasons,
    );
  }

  /// Converts a knowledge-driven decision into a response plan.
  CoachResponsePlan plan({
    required CoachContext context,
    required CoachKnowledgeResult knowledgeResult,
    CoachEntitlementRuntimeResult? entitlementResult,
  }) {
    final decision = decide(
      context: context,
      knowledgeResult: knowledgeResult,
      entitlementResult: entitlementResult,
    );
    return CoachResponsePlan.fromKnowledgeDecision(
      decision: decision,
      knowledgeResult: knowledgeResult,
    );
  }

  CoachDecision _blockedDecision({
    required KnowledgeNode node,
    required CoachKnowledgeResult knowledgeResult,
    required CoachEntitlementRuntimeResult entitlementResult,
    required Set<AIContextProviderKey> requiredProviders,
  }) {
    return CoachDecision(
      shouldCallAI: false,
      localResponse: entitlementResult.upgradeSuggestion ??
          'This coach capability is not available for the current entitlement.',
      missingData: entitlementResult.missingCapabilities
          .map((capability) => capability.name)
          .toList(growable: false),
      requiredProviders: requiredProviders,
      missingProviders: const <AIContextProviderKey>{},
      decisionReason: const <CoachReason>{CoachReason.validationFailed},
      confidence: knowledgeResult.confidence.clamp(0.0, 1.0),
      notes: _notesFor(knowledgeResult, <String>[
        'Entitlement blocked knowledge node ${node.id}.',
        'Status: ${entitlementResult.status.name}.',
        if (entitlementResult.upgradeSuggestion != null)
          entitlementResult.upgradeSuggestion!,
      ]),
      status: entitlementResult.status,
      selectedKnowledgeId: node.id,
      knowledgeConfidence: knowledgeResult.confidence,
      knowledgeReasons: knowledgeResult.reasons,
    );
  }

  Set<AIContextProviderKey> _requiredProviders(KnowledgeNode node) {
    return Set<AIContextProviderKey>.unmodifiable(
      node.requiredKnowledge.map((requirement) => requirement.providerKey),
    );
  }

  Set<AIContextProviderKey> _missingProviders(
    CoachContext context,
    Set<AIContextProviderKey> providers,
  ) {
    return Set<AIContextProviderKey>.unmodifiable(
      providers.where((provider) => !_hasProvider(context, provider)),
    );
  }

  bool _hasProvider(CoachContext context, AIContextProviderKey provider) {
    switch (provider) {
      case AIContextProviderKey.profile:
        return context.profile.isNotEmpty;
      case AIContextProviderKey.goals:
        return context.goals.isNotEmpty ||
            _hasValue(context.profile['fitness_goals']) ||
            _hasValue(context.profile['goal']);
      case AIContextProviderKey.restrictions:
        return context.restrictions.isNotEmpty;
      case AIContextProviderKey.activeProgram:
        return context.activeProgram != null &&
            context.activeProgram!.isNotEmpty;
      case AIContextProviderKey.workoutHistory:
        return context.workoutHistory.isNotEmpty;
      case AIContextProviderKey.heatmap:
        return context.weeklyHeatmap != null;
      case AIContextProviderKey.equipment:
        return context.equipment.isNotEmpty;
      case AIContextProviderKey.memory:
        return context.memories.isNotEmpty;
      case AIContextProviderKey.currentQuestion:
        final question = context.currentQuestion;
        return question != null && question.trim().isNotEmpty;
      case AIContextProviderKey.apiUsage:
        return context.apiUsage.isNotEmpty;
      case AIContextProviderKey.recovery:
        return context.preferences.containsKey('recovery') ||
            context.preferences.containsKey('recovery_score');
      case AIContextProviderKey.preferences:
        return context.preferences.isNotEmpty;
      case AIContextProviderKey.chatHistory:
        return !context.conversationSummary.placeholder ||
            context.conversationSummary.messageCount > 0;
      case AIContextProviderKey.nutrition:
      case AIContextProviderKey.supplements:
      case AIContextProviderKey.appHelp:
      case AIContextProviderKey.diagnostics:
        return context.preferences.containsKey(provider.name);
    }
  }

  bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable<Object?>) return value.isNotEmpty;
    return true;
  }

  List<String> _providerNames(Set<AIContextProviderKey> providers) {
    return List<String>.unmodifiable(
      providers.map((provider) => provider.name),
    );
  }

  List<String> _notesFor(
    CoachKnowledgeResult knowledgeResult,
    List<String> notes,
  ) {
    return List<String>.unmodifiable(<String>[
      'knowledge_node:${knowledgeResult.selectedNode.id}',
      ...knowledgeResult.reasons,
      ...notes,
    ]);
  }
}
