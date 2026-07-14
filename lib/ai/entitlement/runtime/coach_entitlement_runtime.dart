import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/entitlement_engine.dart';
import 'package:gymaipro/ai/entitlement/entitlement_result.dart';
import 'package:gymaipro/ai/entitlement/feature_gate.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_provider.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_trace.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_validator.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/skills/skill_result.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_engine.dart';

/// Result emitted by Coach entitlement runtime.
class CoachEntitlementRuntimeResult {
  const CoachEntitlementRuntimeResult({
    required this.allowed,
    required this.status,
    required this.checkedCapabilities,
    required this.blockedCapabilities,
    required this.missingCapabilities,
    required this.remainingUsage,
    required this.trace,
    this.upgradeSuggestion,
  });

  /// Whether downstream decision/prompt/execution may proceed.
  final bool allowed;

  /// Normalized Coach decision status.
  final CoachDecisionStatus status;

  /// Capabilities evaluated for this request.
  final Set<CoachCapability> checkedCapabilities;

  /// Capabilities blocked by plan, policy, or usage.
  final Set<CoachCapability> blockedCapabilities;

  /// Capabilities not granted by current plan/grants.
  final Set<CoachCapability> missingCapabilities;

  /// Remaining usage counters keyed by capability and limit type.
  final Map<String, int?> remainingUsage;

  /// Upgrade or limit guidance.
  final String? upgradeSuggestion;

  /// Explainability trace for the entitlement stage.
  final CoachEntitlementTrace trace;
}

/// Runtime adapter connecting capability entitlements to Coach pipeline.
class CoachEntitlementRuntime {
  const CoachEntitlementRuntime({
    EntitlementEngine engine = const EntitlementEngine(),
    CoachEntitlementProvider provider = const CurrentSubscriptionAdapter(),
    CoachEntitlementValidator validator = const CoachEntitlementValidator(),
  }) : _engine = engine,
       _provider = provider,
       _validator = validator;

  final EntitlementEngine _engine;
  final CoachEntitlementProvider _provider;
  final CoachEntitlementValidator _validator;

  /// Resolves entitlement for the current Coach pipeline snapshot.
  Future<CoachEntitlementRuntimeResult?> resolve({
    required String userId,
    required CoachContext coachContext,
    required CoachKnowledgeResult knowledgeResult,
    SkillResult? skillResult,
    CoachStrategyResult? strategyResult,
    Map<String, Object?> metadata = const <String, Object?>{},
    CoachPipelineMode pipelineMode = CoachPipelineMode.runtime,
  }) async {
    if (!coachPipelineV2Active(pipelineMode)) return null;

    final stopwatch = Stopwatch()..start();
    final snapshot = await _provider.snapshotFor(
      userId: userId,
      context: coachContext,
      metadata: metadata,
    );
    final capabilities = _capabilitiesFor(
      knowledgeResult: knowledgeResult,
      skillResult: skillResult,
      strategyResult: strategyResult,
    );

    if (capabilities.isEmpty) {
      stopwatch.stop();
      return _allowed(
        checkedCapabilities: const <CoachCapability>{},
        remainingUsage: const <String, int?>{},
        executionTime: stopwatch.elapsed,
        snapshotSource: snapshot.source,
      );
    }

    final entitlementResult = _engine.checkGate(
      entitlement: snapshot.entitlement,
      gate: FeatureGate(
        id: 'coach_pipeline_${knowledgeResult.selectedNode.id}',
        requiredCapabilities: capabilities,
      ),
    );
    stopwatch.stop();

    final remainingUsage = _remainingUsage(entitlementResult.capabilityResults);
    final usageExhausted = _usageExhausted(remainingUsage);
    final blockedCapabilities = _validator.blockedCapabilities(
      entitlementResult,
    );
    final effectiveBlocked = usageExhausted && blockedCapabilities.isEmpty
        ? capabilities
        : blockedCapabilities;
    final status = usageExhausted
        ? CoachDecisionStatus.usageExceeded
        : _validator.statusFor(entitlementResult);
    final allowed = entitlementResult.allowed && !usageExhausted;
    final missingCapabilities = _validator.missingCapabilities(
      entitlementResult,
    );
    final upgradeSuggestion = _upgradeSuggestion(
      status: status,
      upgradePlanId: entitlementResult.upgradePlanId,
    );

    return CoachEntitlementRuntimeResult(
      allowed: allowed,
      status: status,
      checkedCapabilities: capabilities,
      blockedCapabilities: effectiveBlocked,
      missingCapabilities: missingCapabilities,
      remainingUsage: remainingUsage,
      upgradeSuggestion: upgradeSuggestion,
      trace: CoachEntitlementTrace(
        checkedCapabilities: capabilities,
        missingCapabilities: missingCapabilities,
        remainingUsage: remainingUsage,
        upgradeSuggestion: upgradeSuggestion,
        snapshotSource: snapshot.source,
        executionTime: stopwatch.elapsed,
      ),
    );
  }

  Set<CoachCapability> _capabilitiesFor({
    required CoachKnowledgeResult knowledgeResult,
    SkillResult? skillResult,
    CoachStrategyResult? strategyResult,
  }) {
    return Set<CoachCapability>.unmodifiable(<CoachCapability>{
      CoachCapability.coachConversation,
      if (knowledgeResult.selectedNode.requiresAI)
        ..._knowledgeCapabilities(knowledgeResult.selectedNode.id),
      if (skillResult?.selectedSkill != null)
        ..._skillCapabilities(skillResult!.selectedSkill!.skill.capability.id),
      if (strategyResult?.strategy.requiresAI ?? false)
        CoachCapability.premiumReasoning,
    });
  }

  Set<CoachCapability> _knowledgeCapabilities(String nodeId) {
    switch (nodeId) {
      case 'workout_generation':
        return const <CoachCapability>{CoachCapability.generateWorkout};
      case 'workout_modification':
        return const <CoachCapability>{CoachCapability.modifyWorkout};
      case 'progress_analysis':
        return const <CoachCapability>{CoachCapability.analyzeProgress};
      case 'recovery':
        return const <CoachCapability>{CoachCapability.recoveryAnalysis};
      case 'nutrition':
        return const <CoachCapability>{CoachCapability.nutritionPlanning};
      case 'supplement':
        return const <CoachCapability>{CoachCapability.supplementAdvice};
      case 'program_review':
        return const <CoachCapability>{CoachCapability.aiProgramReview};
      default:
        return const <CoachCapability>{};
    }
  }

  Set<CoachCapability> _skillCapabilities(String skillCapabilityId) {
    switch (skillCapabilityId) {
      case 'explain_heatmap':
        return const <CoachCapability>{CoachCapability.explainHeatmap};
      case 'recovery_guidance':
        return const <CoachCapability>{CoachCapability.recoveryAnalysis};
      case 'progress_summary':
        return const <CoachCapability>{CoachCapability.analyzeProgress};
      case 'show_today_workout':
      case 'motivation_message':
      case 'app_help_response':
        return const <CoachCapability>{CoachCapability.coachConversation};
      default:
        return const <CoachCapability>{};
    }
  }

  Map<String, int?> _remainingUsage(
    Iterable<CapabilityEntitlementResult> capabilityResults,
  ) {
    final usage = <String, int?>{};
    for (final result in capabilityResults) {
      final capabilityName = result.capability.name;
      usage['$capabilityName.daily'] = result.dailyRemaining;
      usage['$capabilityName.monthly'] = result.monthlyRemaining;
      usage['$capabilityName.token'] = result.tokenRemaining;
    }
    return Map<String, int?>.unmodifiable(usage);
  }

  bool _usageExhausted(Map<String, int?> remainingUsage) {
    return remainingUsage.values.any((remaining) {
      return remaining != null && remaining <= 0;
    });
  }

  String? _upgradeSuggestion({
    required CoachDecisionStatus status,
    required String? upgradePlanId,
  }) {
    switch (status) {
      case CoachDecisionStatus.allowed:
        return null;
      case CoachDecisionStatus.upgradeRequired:
        return upgradePlanId == null
            ? 'Upgrade is required for this coach capability.'
            : 'Upgrade to $upgradePlanId to use this coach capability.';
      case CoachDecisionStatus.usageExceeded:
        return 'Usage limit reached for this coach capability.';
      case CoachDecisionStatus.featureDisabled:
        return 'This coach capability is currently disabled.';
      case CoachDecisionStatus.temporarilyLocked:
        return 'This coach capability is temporarily locked.';
    }
  }

  CoachEntitlementRuntimeResult _allowed({
    required Set<CoachCapability> checkedCapabilities,
    required Map<String, int?> remainingUsage,
    required Duration executionTime,
    String? snapshotSource,
  }) {
    return CoachEntitlementRuntimeResult(
      allowed: true,
      status: CoachDecisionStatus.allowed,
      checkedCapabilities: checkedCapabilities,
      blockedCapabilities: const <CoachCapability>{},
      missingCapabilities: const <CoachCapability>{},
      remainingUsage: remainingUsage,
      trace: CoachEntitlementTrace(
        checkedCapabilities: checkedCapabilities,
        missingCapabilities: const <CoachCapability>{},
        remainingUsage: remainingUsage,
        snapshotSource: snapshotSource,
        executionTime: executionTime,
      ),
    );
  }
}
