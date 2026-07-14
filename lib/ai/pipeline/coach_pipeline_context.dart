import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';
import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_runtime.dart';
import 'package:gymaipro/ai/integration/coach_state_integration.dart';
import 'package:gymaipro/ai/integration/entity_memory_integration.dart';
import 'package:gymaipro/ai/intent/intent_intelligence_result.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_stage.dart';
import 'package:gymaipro/ai/planner/coach_executor.dart';
import 'package:gymaipro/ai/planner/coach_response_plan.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_plan.dart';
import 'package:gymaipro/ai/prompt/prompt_package.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_execution_result.dart';
import 'package:gymaipro/ai/skills/skill_result.dart';
import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_engine.dart';

/// Mutable context passed between pipeline stages.
class CoachPipelineContext {
  CoachPipelineContext({
    required this.userId,
    required this.userMessage,
    required this.metadata,
    required this.startedAt,
    this.mode = CoachPipelineMode.runtime,
    this.seedCoachContext,
    this.normalizedEntities = const <NormalizedEntity>[],
    this.intentIntelligence,
    this.statePrepareResult,
    this.memoryApplication = EntityMemoryApplicationResult.empty,
    this.conversationState,
    this.coachContext,
    this.knowledgeResult,
    this.entitlementResult,
    this.skillResult,
    this.skillExecutionResult,
    this.strategyResult,
    this.decision,
    this.responsePlan,
    this.promptPlan,
    this.promptPackage,
    this.executorPreview,
  });

  /// Creates the initial context for a pipeline run.
  factory CoachPipelineContext.initial({
    required String userId,
    required String userMessage,
    Map<String, Object?> metadata = const <String, Object?>{},
    DateTime? startedAt,
    CoachPipelineMode mode = CoachPipelineMode.runtime,
    CoachContext? seedCoachContext,
  }) {
    return CoachPipelineContext(
      userId: userId,
      userMessage: userMessage,
      metadata: metadata,
      startedAt: startedAt ?? DateTime.now(),
      mode: mode,
      seedCoachContext: seedCoachContext,
    );
  }

  final String userId;
  final String userMessage;
  final Map<String, Object?> metadata;
  final DateTime startedAt;
  final CoachPipelineMode mode;
  final CoachContext? seedCoachContext;

  List<NormalizedEntity> normalizedEntities;
  IntentIntelligenceResult? intentIntelligence;
  CoachStatePrepareResult? statePrepareResult;
  EntityMemoryApplicationResult memoryApplication;
  CoachConversationState? conversationState;
  CoachContext? coachContext;
  CoachKnowledgeResult? knowledgeResult;
  CoachEntitlementRuntimeResult? entitlementResult;
  SkillResult? skillResult;
  CoachSkillExecutionResult? skillExecutionResult;
  CoachStrategyResult? strategyResult;
  CoachDecision? decision;
  CoachResponsePlan? responsePlan;
  CoachPromptPlan? promptPlan;
  PromptPackage? promptPackage;
  CoachExecutionPreview? executorPreview;

  /// Resolved intent for downstream stages.
  AIIntent get intent =>
      intentIntelligence?.primaryIntent ?? AIIntent.generalChat;

  /// Whether this run is a dry-run preview.
  bool get isPreview => mode.isPreview;

  /// Whether v2 intelligence stages should execute for this run.
  bool get runsV2Stages => coachPipelineV2Active(mode);

  /// Whether a local skill runtime response should short-circuit AI stages.
  bool get localSkillHandled =>
      (skillExecutionResult?.handledLocally ?? false) &&
      (entitlementResult?.allowed ?? true);

  /// Stages skipped after a successful local skill runtime response.
  static const Set<CoachPipelineStage> stagesSkippedAfterLocalSkill =
      <CoachPipelineStage>{
        CoachPipelineStage.decision,
        CoachPipelineStage.strategy,
        CoachPipelineStage.stateFinalize,
        CoachPipelineStage.promptPlanning,
        CoachPipelineStage.prompt,
        CoachPipelineStage.execution,
      };

  CoachPipelineContext copyWith({
    CoachPipelineMode? mode,
    CoachContext? seedCoachContext,
    List<NormalizedEntity>? normalizedEntities,
    IntentIntelligenceResult? intentIntelligence,
    CoachStatePrepareResult? statePrepareResult,
    EntityMemoryApplicationResult? memoryApplication,
    CoachConversationState? conversationState,
    CoachContext? coachContext,
    CoachKnowledgeResult? knowledgeResult,
    CoachEntitlementRuntimeResult? entitlementResult,
    SkillResult? skillResult,
    CoachSkillExecutionResult? skillExecutionResult,
    CoachStrategyResult? strategyResult,
    CoachDecision? decision,
    CoachResponsePlan? responsePlan,
    CoachPromptPlan? promptPlan,
    PromptPackage? promptPackage,
    CoachExecutionPreview? executorPreview,
  }) {
    return CoachPipelineContext(
      userId: userId,
      userMessage: userMessage,
      metadata: metadata,
      startedAt: startedAt,
      mode: mode ?? this.mode,
      seedCoachContext: seedCoachContext ?? this.seedCoachContext,
      normalizedEntities: normalizedEntities ?? this.normalizedEntities,
      intentIntelligence: intentIntelligence ?? this.intentIntelligence,
      statePrepareResult: statePrepareResult ?? this.statePrepareResult,
      memoryApplication: memoryApplication ?? this.memoryApplication,
      conversationState: conversationState ?? this.conversationState,
      coachContext: coachContext ?? this.coachContext,
      knowledgeResult: knowledgeResult ?? this.knowledgeResult,
      entitlementResult: entitlementResult ?? this.entitlementResult,
      skillResult: skillResult ?? this.skillResult,
      skillExecutionResult:
          skillExecutionResult ?? this.skillExecutionResult,
      strategyResult: strategyResult ?? this.strategyResult,
      decision: decision ?? this.decision,
      responsePlan: responsePlan ?? this.responsePlan,
      promptPlan: promptPlan ?? this.promptPlan,
      promptPackage: promptPackage ?? this.promptPackage,
      executorPreview: executorPreview ?? this.executorPreview,
    );
  }
}

/// Outcome returned by one stage runner.
class CoachPipelineStageOutcome {
  const CoachPipelineStageOutcome({
    required this.context,
    required this.success,
    this.skipped = false,
    this.confidence,
    this.reason,
    this.metadata = const <String, Object?>{},
  });

  final CoachPipelineContext context;
  final bool success;
  final bool skipped;
  final double? confidence;
  final String? reason;
  final Map<String, Object?> metadata;
}

/// Contract for one pipeline stage implementation.
abstract class CoachPipelineStageRunner {
  const CoachPipelineStageRunner();

  /// Stage identifier handled by this runner.
  CoachPipelineStage get stage;

  /// Executes the stage and returns the updated context.
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context);
}
