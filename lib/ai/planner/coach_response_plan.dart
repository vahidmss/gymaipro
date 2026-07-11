import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_definitions.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';
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

  /// Builds a plan from the existing coach decision layer.
  factory CoachResponsePlan.fromDecision({
    required CoachDecision decision,
    required AIIntentDefinition intentDefinition,
    required AIContextProviderSelection providerSelection,
  }) {
    final action = _actionForDecision(decision);
    final contextKeys = <AIContextProviderKey>{
      ...intentDefinition.requiredProviders,
      ...intentDefinition.optionalProviders,
    };

    return CoachResponsePlan(
      id: _planId(intentDefinition.intent, action),
      intent: intentDefinition.intent,
      action: action,
      requiresAI: decision.shouldCallAI,
      requiredProviders: intentDefinition.requiredProviders,
      missingProviders: decision.missingProviders,
      followUpQuestions: <String>[
        if (decision.followUpQuestion != null) decision.followUpQuestion!,
      ],
      localMessage: decision.localResponse,
      promptTemplateId: decision.shouldCallAI ? intentDefinition.id : null,
      contextKeys: Set<AIContextProviderKey>.unmodifiable(contextKeys),
      confidence: decision.confidence,
      estimatedTokens: _estimatedTokens(decision, intentDefinition),
      estimatedCost: _estimatedCost(decision, providerSelection),
      estimatedLatency: _estimatedLatency(decision, providerSelection),
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

  static String _planId(AIIntent intent, CoachAction action) {
    return '${intent.name}_${action.name}_plan';
  }

  static int _estimatedTokens(
    CoachDecision decision,
    AIIntentDefinition intentDefinition,
  ) {
    if (!decision.shouldCallAI) return 0;
    return intentDefinition.requiredProviders.length * 250 +
        intentDefinition.optionalProviders.length * 120 +
        600;
  }

  static double _estimatedCost(
    CoachDecision decision,
    AIContextProviderSelection providerSelection,
  ) {
    final providerCost = providerSelection.providers.fold<double>(
      0,
      (total, provider) => total + provider.estimatedCost,
    );
    return decision.shouldCallAI ? providerCost + 1 : providerCost;
  }

  static Duration _estimatedLatency(
    CoachDecision decision,
    AIContextProviderSelection providerSelection,
  ) {
    final providerLatency = providerSelection.providers.fold<Duration>(
      Duration.zero,
      (total, provider) => total + provider.estimatedLatency,
    );
    if (!decision.shouldCallAI) return providerLatency;
    return providerLatency + const Duration(seconds: 3);
  }
}
