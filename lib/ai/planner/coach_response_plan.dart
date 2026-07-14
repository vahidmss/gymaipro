import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/knowledge/knowledge_requirement.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/planner/response_priority.dart';
import 'package:gymaipro/ai/planner/response_step.dart';

/// Integration-ready response plan produced by GymAI Coach Brain.
///
/// The plan is descriptive only. It does not execute navigation, call OpenAI,
/// build prompts, or change current app behavior.
class CoachResponsePlan {
  const CoachResponsePlan({
    required this.id,
    required this.intent,
    required this.action,
    required this.requiresAI,
    required this.requiredProviders,
    required this.missingProviders,
    required this.followUpQuestions,
    required this.contextKeys,
    required this.confidence,
    required this.estimatedTokens,
    required this.estimatedCost,
    required this.estimatedLatency,
    required this.notes,
    this.localMessage,
    this.promptTemplateId,
    this.steps = const <ResponseStep>[],
  });

  /// Builds a plan from the Coach v2 knowledge-driven decision layer.
  factory CoachResponsePlan.fromKnowledgeDecision({
    required CoachDecision decision,
    required CoachKnowledgeResult knowledgeResult,
  }) {
    final node = knowledgeResult.selectedNode;
    final action = _actionForDecision(decision);
    final contextKeys = <AIContextProviderKey>{
      for (final requirement in <KnowledgeRequirement>[
        ...node.requiredKnowledge,
        ...node.optionalKnowledge,
      ])
        requirement.providerKey,
    };

    return CoachResponsePlan(
      id: '${node.id}_${action.name}_plan',
      intent: node.intent ?? AIIntent.generalChat,
      action: action,
      requiresAI: decision.shouldCallAI,
      requiredProviders: decision.requiredProviders,
      missingProviders: decision.missingProviders,
      followUpQuestions: <String>[
        if (decision.followUpQuestion != null) decision.followUpQuestion!,
      ],
      localMessage: decision.localResponse,
      promptTemplateId: decision.shouldCallAI ? node.id : null,
      contextKeys: Set<AIContextProviderKey>.unmodifiable(contextKeys),
      confidence: decision.confidence,
      estimatedTokens: decision.shouldCallAI
          ? node.requiredKnowledge.length * 250 +
              node.optionalKnowledge.length * 120 +
              600
          : 0,
      estimatedCost: decision.shouldCallAI ? 1 : 0,
      estimatedLatency: decision.shouldCallAI
          ? const Duration(seconds: 3)
          : Duration.zero,
      notes: decision.notes,
      steps: <ResponseStep>[
        ResponseStep(
          id: 'route_${action.wireName.toLowerCase()}',
          action: action,
          priority: decision.requiresFollowUp
              ? ResponsePriority.immediate
              : ResponsePriority.high,
          description: 'Prepared ${action.wireName} route.',
        ),
      ],
    );
  }

  /// Stable plan id.
  final String id;

  /// Resolved intent.
  final AIIntent intent;

  /// Primary action to be executed by a future integration.
  final CoachAction action;

  /// Whether this plan expects an AI call in a future executor.
  final bool requiresAI;

  /// Provider keys required by this intent.
  final Set<AIContextProviderKey> requiredProviders;

  /// Provider keys still missing.
  final Set<AIContextProviderKey> missingProviders;

  /// Follow-up questions to ask before execution.
  final List<String> followUpQuestions;

  /// Local response message, when action is local.
  final String? localMessage;

  /// Future prompt-template id. Phase 4 does not resolve templates.
  final String? promptTemplateId;

  /// Context keys the future executor may need.
  final Set<AIContextProviderKey> contextKeys;

  /// Confidence in this plan from 0 to 1.
  final double confidence;

  /// Estimated prompt/response token budget.
  final int estimatedTokens;

  /// Estimated relative cost for future routing.
  final double estimatedCost;

  /// Estimated latency for future routing.
  final Duration estimatedLatency;

  /// Diagnostic notes.
  final List<String> notes;

  /// Future response steps. Phase 4 only creates descriptive steps.
  final List<ResponseStep> steps;

  static CoachAction _actionForDecision(CoachDecision decision) {
    if (decision.missingProviders.isNotEmpty) return CoachAction.error;
    if (decision.requiresFollowUp) return CoachAction.followUp;
    if (decision.shouldCallAI) return CoachAction.callOpenAI;
    if (decision.hasLocalResponse) return CoachAction.localResponse;
    return CoachAction.error;
  }
}
