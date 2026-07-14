import 'package:gymaipro/ai/coach/coach_brain.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_engine.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/entity/entity_extractor.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_runtime.dart';
import 'package:gymaipro/ai/integration/coach_state_integration.dart';
import 'package:gymaipro/ai/integration/entity_memory_integration.dart';
import 'package:gymaipro/ai/integration/integration_event.dart';
import 'package:gymaipro/ai/integration/integration_logger.dart';
import 'package:gymaipro/ai/intent/intent_intelligence_engine.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_runtime.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_dependencies.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_context.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_stage.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/planner/coach_executor.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_planner.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_validator.dart';
import 'package:gymaipro/ai/prompt/prompt_builder.dart';
import 'package:gymaipro/ai/skills/coach_skill_engine.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_execution_result.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_executor.dart';
import 'package:gymaipro/ai/skills/skill_result.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_engine.dart';

/// Builds a configured [CoachPipeline] for Coach v2 runtime integration.
class CoachPipelineBuilder {
  CoachPipelineBuilder({
    required CoachPipelineDependencies dependencies,
    CoachPipelineConfig config = const CoachPipelineConfig(),
  }) : _dependencies = dependencies,
       _config = config;

  final CoachPipelineDependencies _dependencies;
  final CoachPipelineConfig _config;

  /// Builds the standard Coach v2 orchestration pipeline.
  CoachPipeline build() {
    final deps = _dependencies;
    final runners = <CoachPipelineStage, CoachPipelineStageRunner>{
      CoachPipelineStage.entity: _EntityStageRunner(
        entityExtractor: deps.entityExtractor,
        logger: deps.logger,
      ),
      CoachPipelineStage.intent: _IntentStageRunner(
        intentIntelligenceEngine: deps.intentIntelligenceEngine,
        logger: deps.logger,
      ),
      CoachPipelineStage.state: _StateStageRunner(
        stateIntegration: deps.stateIntegration,
        logger: deps.logger,
      ),
      CoachPipelineStage.memory: _MemoryStageRunner(
        entityMemoryIntegration: deps.entityMemoryIntegration,
        logger: deps.logger,
      ),
      CoachPipelineStage.context: _ContextStageRunner(
        contextEngine: deps.contextEngine,
        logger: deps.logger,
      ),
      CoachPipelineStage.knowledge: _KnowledgeStageRunner(
        coachKnowledgeRuntime: deps.coachKnowledgeRuntime,
        logger: deps.logger,
      ),
      CoachPipelineStage.skill: _SkillStageRunner(
        skillEngine: deps.skillEngine,
        skillExecutor: deps.skillExecutor,
        logger: deps.logger,
      ),
      CoachPipelineStage.entitlement: _EntitlementStageRunner(
        entitlementRuntime: deps.coachEntitlementRuntime,
        logger: deps.logger,
      ),
      CoachPipelineStage.decision: _DecisionStageRunner(
        coachBrain: deps.coachBrain,
        logger: deps.logger,
      ),
      CoachPipelineStage.strategy: _StrategyStageRunner(
        strategyEngine: deps.strategyEngine,
        logger: deps.logger,
      ),
      CoachPipelineStage.stateFinalize: _StateFinalizeStageRunner(
        stateIntegration: deps.stateIntegration,
        logger: deps.logger,
      ),
      CoachPipelineStage.promptPlanning: _PromptPlanningStageRunner(
        promptPlanner: deps.coachPromptPlanner,
        validator: const CoachPromptValidator(),
        logger: deps.logger,
      ),
      CoachPipelineStage.prompt: _PromptStageRunner(
        promptBuilder: deps.promptBuilder,
        logger: deps.logger,
      ),
      CoachPipelineStage.execution: _ExecutionStageRunner(
        executor: deps.executor,
        logger: deps.logger,
      ),
    };

    return CoachPipeline(runners: runners, config: _config);
  }

  /// Clears cached provider fields before a pipeline run.
  void clearFieldCache() {
    _dependencies.contextRepository.clearFieldCache();
  }

  /// Returns the integration logger used by stage runners.
  IntegrationLogger get logger => _dependencies.logger;
}

class _EntityStageRunner extends CoachPipelineStageRunner {
  const _EntityStageRunner({
    required this.entityExtractor,
    required this.logger,
  });

  final EntityExtractor entityExtractor;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.entity;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    if (!context.runsV2Stages) {
      return CoachPipelineStageOutcome(
        context: context,
        success: true,
        skipped: true,
        reason: 'Entity stage disabled because Coach v2 is off.',
      );
    }

    final entities = entityExtractor.extract(context.userMessage).entities;
    final updated = context.copyWith(normalizedEntities: entities);
    if (entities.isNotEmpty) {
      logger.log(
        IntegrationEventType.entitiesExtracted,
        'Entities extracted from user message.',
        metadata: <String, Object?>{
          'entityCount': entities.length,
          'entityTypes': entities
              .map((entity) => entity.type.name)
              .toList(growable: false),
        },
      );
    }

    return CoachPipelineStageOutcome(
      context: updated,
      success: true,
      confidence: entities.isEmpty
          ? null
          : entities.first.confidence,
      reason: entities.isEmpty
          ? 'No entities extracted.'
          : 'Extracted ${entities.length} entity(ies).',
    );
  }
}

class _IntentStageRunner extends CoachPipelineStageRunner {
  const _IntentStageRunner({
    required this.intentIntelligenceEngine,
    required this.logger,
  });

  final IntentIntelligenceEngine intentIntelligenceEngine;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.intent;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final intelligence = intentIntelligenceEngine.detect(
      IntentDetectionRequest(
        message: context.userMessage,
        metadata: context.metadata,
      ),
    );

    logger.log(
      IntegrationEventType.intentDetected,
      'Intent detected: ${intelligence.primaryIntent.name}.',
      metadata: <String, Object?>{
        'confidence': intelligence.primaryConfidence,
        'reason': intelligence.reason,
        'strategy': intelligence.strategy.name,
        'alternativeCount': intelligence.alternatives.length,
      },
    );

    return CoachPipelineStageOutcome(
      context: context.copyWith(intentIntelligence: intelligence),
      success: true,
      confidence: intelligence.primaryConfidence,
      reason: intelligence.reason,
    );
  }
}

class _StateStageRunner extends CoachPipelineStageRunner {
  const _StateStageRunner({
    required this.stateIntegration,
    required this.logger,
  });

  final CoachStateIntegration stateIntegration;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.state;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final intelligence = context.intentIntelligence;
    if (intelligence == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: false,
        reason: 'Intent stage must run before state stage.',
      );
    }

    final statePrepareResult = await stateIntegration.prepareForMessage(
      userId: context.userId,
      intent: intelligence.primaryIntent,
      userMessage: context.userMessage,
      normalizedEntities: context.normalizedEntities,
      metadata: context.metadata,
      dryRun: context.isPreview,
    );

    final entityApplication = statePrepareResult.entityApplication;
    if (entityApplication?.applied ?? false) {
      logger.log(
        IntegrationEventType.entityStateApplied,
        'Pending question resolved from extracted entity.',
        metadata: <String, Object?>{
          'fieldKey': entityApplication!.resolvedFieldKey,
          'value': entityApplication.resolvedValue,
        },
      );
    }

    final conversationState = statePrepareResult.state;
    if (conversationState != null) {
      logger.log(
        IntegrationEventType.conversationStateLoaded,
        'Conversation state loaded.',
        metadata: <String, Object?>{
          'stateId': conversationState.id,
          'flowType': conversationState.flowType.name,
          'phase': conversationState.currentPhase.name,
          'pendingQuestionCount': conversationState.pendingQuestions.length,
          'collectedFieldCount': conversationState.collectedFields.length,
        },
      );
    }

    return CoachPipelineStageOutcome(
      context: context.copyWith(
        statePrepareResult: statePrepareResult,
        conversationState: conversationState,
      ),
      success: true,
      reason: 'Conversation state prepared.',
    );
  }
}

class _MemoryStageRunner extends CoachPipelineStageRunner {
  const _MemoryStageRunner({
    required this.entityMemoryIntegration,
    required this.logger,
  });

  final EntityMemoryIntegration entityMemoryIntegration;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.memory;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    if (!context.runsV2Stages || context.normalizedEntities.isEmpty) {
      return CoachPipelineStageOutcome(
        context: context,
        success: true,
        skipped: true,
        reason: context.normalizedEntities.isEmpty
            ? 'Memory stage skipped because no entities were extracted.'
            : 'Memory stage disabled because Coach v2 is off.',
      );
    }

    final memoryApplication = await entityMemoryIntegration.applyEntities(
      userId: context.userId,
      entities: context.normalizedEntities,
      dryRun: context.isPreview,
    );

    if (memoryApplication.mappedCount > 0) {
      logger.log(
        IntegrationEventType.entityMemoryMapped,
        'Entities mapped to memory update requests.',
        metadata: <String, Object?>{
          'mappedCount': memoryApplication.mappedCount,
          'skippedCount': memoryApplication.skippedCount,
          'memoryKeys': memoryApplication.memoryKeys,
        },
      );
    }
    if (memoryApplication.persistedCount > 0) {
      logger.log(
        IntegrationEventType.entityMemoryPersisted,
        'Entity memories persisted.',
        metadata: <String, Object?>{
          'persistedCount': memoryApplication.persistedCount,
          'duplicateCount': memoryApplication.duplicateCount,
          'conflictCount': memoryApplication.conflictCount,
          'memoryKeys': memoryApplication.memoryKeys,
        },
      );
    }

    return CoachPipelineStageOutcome(
      context: context.copyWith(memoryApplication: memoryApplication),
      success: true,
      confidence: memoryApplication.persistedCount > 0 ? 0.8 : null,
      reason: context.isPreview
          ? memoryApplication.mappedCount > 0
              ? 'Mapped ${memoryApplication.mappedCount} memory item(s) without persisting.'
              : 'No persistable memory entities found.'
          : memoryApplication.persistedCount > 0
          ? 'Persisted ${memoryApplication.persistedCount} memory item(s).'
          : 'No persistable memory entities found.',
    );
  }
}

class _ContextStageRunner extends CoachPipelineStageRunner {
  const _ContextStageRunner({
    required this.contextEngine,
    required this.logger,
  });

  final AIContextEngine contextEngine;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.context;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final intelligence = context.intentIntelligence;
    if (intelligence == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: false,
        reason: 'Intent stage must run before context stage.',
      );
    }

    final request = AIContextRequest(
      userId: context.userId,
      intent: intelligence.primaryIntent,
      currentQuestion: context.userMessage,
      source: context.isPreview ? 'preview' : 'chat',
      metadata: context.metadata,
      memorySnapshot: context.memoryApplication.memorySnapshot.isEmpty
          ? null
          : context.memoryApplication.memorySnapshot,
    );

    var coachContext = context.isPreview && context.seedCoachContext != null
        ? _seedCoachContext(
            seed: context.seedCoachContext!,
            userMessage: context.userMessage,
            intent: intelligence.primaryIntent,
          )
        : await contextEngine.buildCoachContextForQuestion(
            request: request,
            intent: intelligence.primaryIntent,
            buildTime: context.startedAt,
          );

    final conversationState = context.conversationState;
    if (conversationState != null &&
        conversationState.collectedFields.isNotEmpty) {
      coachContext = coachContext.withCollectedFields(
        conversationState.collectedFields,
      );
    }

    logger.log(
      IntegrationEventType.coachContextBuilt,
      'CoachContext assembled.',
      metadata: <String, Object?>{
        'sourceCount': coachContext.metadata.sourceCount,
        'contextVersion': coachContext.metadata.contextVersion,
        'confidence': coachContext.metadata.confidence,
        'conversationStateApplied': conversationState != null,
      },
    );

    return CoachPipelineStageOutcome(
      context: context.copyWith(coachContext: coachContext),
      success: true,
      confidence: coachContext.metadata.confidence,
      reason: 'CoachContext assembled.',
    );
  }
}

class _EntitlementStageRunner extends CoachPipelineStageRunner {
  const _EntitlementStageRunner({
    required this.entitlementRuntime,
    required this.logger,
  });

  final CoachEntitlementRuntime entitlementRuntime;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.entitlement;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final coachContext = context.coachContext;
    final knowledgeResult = context.knowledgeResult;
    if (coachContext == null || knowledgeResult == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: false,
        reason:
            'Context and knowledge result are required before entitlement.',
      );
    }

    final entitlementResult = await entitlementRuntime.resolve(
      userId: context.userId,
      coachContext: coachContext,
      knowledgeResult: knowledgeResult,
      skillResult: context.skillResult,
      metadata: context.metadata,
      pipelineMode: context.mode,
    );

    if (entitlementResult == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: true,
        skipped: true,
        reason: 'Entitlement runtime skipped because Coach v2 is disabled.',
      );
    }

    logger.log(
      IntegrationEventType.providersSelected,
      entitlementResult.allowed
          ? 'Entitlement runtime allowed coach capabilities.'
          : 'Entitlement runtime blocked coach capabilities.',
      metadata: <String, Object?>{
        'allowed': entitlementResult.allowed,
        'status': entitlementResult.status.name,
        'checkedCapabilities': entitlementResult.checkedCapabilities
            .map((capability) => capability.name)
            .toList(growable: false),
        'missingCapabilities': entitlementResult.missingCapabilities
            .map((capability) => capability.name)
            .toList(growable: false),
        'remainingUsage': entitlementResult.remainingUsage,
        'upgradeSuggestion': entitlementResult.upgradeSuggestion,
      },
    );

    return CoachPipelineStageOutcome(
      context: context.copyWith(entitlementResult: entitlementResult),
      success: true,
      reason: entitlementResult.allowed
          ? 'Entitlement allowed coach capabilities.'
          : 'Entitlement blocked coach capabilities: ${entitlementResult.status.name}.',
      metadata: <String, Object?>{
        'checkedCapabilities': entitlementResult.checkedCapabilities
            .map((capability) => capability.name)
            .toList(growable: false),
        'missingCapabilities': entitlementResult.missingCapabilities
            .map((capability) => capability.name)
            .toList(growable: false),
        'remainingUsage': entitlementResult.remainingUsage,
        'upgradeSuggestion': entitlementResult.upgradeSuggestion,
        'executionTimeMs':
            entitlementResult.trace.executionTime.inMilliseconds,
      },
    );
  }
}

class _KnowledgeStageRunner extends CoachPipelineStageRunner {
  const _KnowledgeStageRunner({
    required this.coachKnowledgeRuntime,
    required this.logger,
  });

  final CoachKnowledgeRuntime coachKnowledgeRuntime;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.knowledge;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final coachContext = context.coachContext;
    final intelligence = context.intentIntelligence;
    if (coachContext == null || intelligence == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: false,
        reason: 'Context and intent are required before knowledge runtime.',
      );
    }

    final knowledgeResult = coachKnowledgeRuntime.resolve(
      intent: intelligence.primaryIntent,
      coachContext: coachContext,
      entities: context.normalizedEntities,
      memories: context.memoryApplication.memorySnapshot,
      conversationState: context.conversationState,
      pipelineMode: context.mode,
    );

    if (knowledgeResult == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: true,
        skipped: true,
        reason: 'Knowledge runtime skipped because Coach v2 is disabled.',
      );
    }

    logger.log(
      IntegrationEventType.providersSelected,
      'Knowledge runtime selected ${knowledgeResult.selectedNode.id}.',
      metadata: <String, Object?>{
        'selectedNodeId': knowledgeResult.selectedNode.id,
        'confidence': knowledgeResult.confidence,
        'usedFallback': knowledgeResult.usedFallback,
        'candidateCount': knowledgeResult.candidateNodes.length,
        'reasonCount': knowledgeResult.reasons.length,
      },
    );

    return CoachPipelineStageOutcome(
      context: context.copyWith(knowledgeResult: knowledgeResult),
      success: true,
      confidence: knowledgeResult.confidence,
      reason: knowledgeResult.reasons.join(' '),
    );
  }
}

class _SkillStageRunner extends CoachPipelineStageRunner {
  const _SkillStageRunner({
    required this.skillEngine,
    required this.skillExecutor,
    required this.logger,
  });

  final CoachSkillEngine skillEngine;
  final CoachSkillExecutor skillExecutor;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.skill;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final coachContext = context.coachContext;
    final intelligence = context.intentIntelligence;
    if (coachContext == null || intelligence == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: false,
        reason: 'Context and intent are required before skill evaluation.',
      );
    }

    var skillResult = skillEngine.evaluate(
      context: coachContext,
      intent: intelligence.primaryIntent,
    );
    CoachSkillExecutionResult? skillExecution;

    if (!skillResult.shouldInvokeAI) {
      skillExecution = skillExecutor.execute(
        context: coachContext,
        intent: intelligence.primaryIntent,
        skillResult: skillResult,
        pipelineMode: context.mode,
      );
      if (skillExecution != null && !skillExecution.handledLocally) {
        skillResult = SkillResult(
          intent: skillResult.intent,
          candidates: skillResult.candidates,
          selectedSkill: skillResult.selectedSkill,
          shouldInvokeAI: true,
          reason: 'Skill runtime requested AI fallback.',
        );
        skillExecution = null;
      }
    }

    logger.log(
      IntegrationEventType.providersSelected,
      skillExecution?.handledLocally ?? false
          ? 'Skill runtime produced a local response.'
          : 'Skill engine evaluated local routing candidates.',
      metadata: <String, Object?>{
        'shouldInvokeAI': skillResult.shouldInvokeAI,
        'candidateCount': skillResult.candidates.length,
        'selectedSkill': skillResult.selectedSkill?.skill.id,
        'executedSkill': skillExecution?.skillId,
        'executionTimeMs': skillExecution?.executionTime.inMilliseconds,
        'localResponse': skillExecution?.response.message,
        'requiresAI': skillExecution?.response.requiresAI ??
            skillResult.shouldInvokeAI,
        'skillConfidence': skillExecution?.response.confidence,
        'reasonCount': skillExecution?.response.reasons.length,
        'warningCount': skillExecution?.response.warnings.length,
      },
    );

    final reason = skillExecution?.handledLocally ?? false
        ? 'Executed ${skillExecution!.skillId} locally. requiresAI=false'
        : skillResult.reason;

    return CoachPipelineStageOutcome(
      context: context.copyWith(
        skillResult: skillResult,
        skillExecutionResult: skillExecution,
      ),
      success: true,
      confidence: skillExecution?.response.confidence ??
          skillResult.selectedSkill?.evaluation.confidence,
      reason: reason,
    );
  }
}

class _DecisionStageRunner extends CoachPipelineStageRunner {
  const _DecisionStageRunner({
    required this.coachBrain,
    required this.logger,
  });

  final CoachBrain coachBrain;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.decision;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final coachContext = context.coachContext;
    final knowledgeResult = context.knowledgeResult;
    if (coachContext == null || knowledgeResult == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: false,
        reason: 'Context and knowledge result are required before coach decision.',
      );
    }

    final decision = coachBrain.decide(
      context: coachContext,
      knowledgeResult: knowledgeResult,
      entitlementResult: context.entitlementResult,
    );
    logger.log(
      IntegrationEventType.decisionCreated,
      'Coach decision created.',
      metadata: <String, Object?>{
        'shouldCallAI': decision.shouldCallAI,
        'status': decision.status.name,
        'missingData': decision.missingData,
        'confidence': decision.confidence,
        'knowledgeNodeId': decision.selectedKnowledgeId,
        'entitlementAllowed': context.entitlementResult?.allowed,
      },
    );

    final responsePlan = coachBrain.plan(
      context: coachContext,
      knowledgeResult: knowledgeResult,
      entitlementResult: context.entitlementResult,
    );
    logger.log(
      IntegrationEventType.responsePlanCreated,
      'Response plan created: ${responsePlan.action.wireName}.',
      metadata: <String, Object?>{
        'estimatedCost': responsePlan.estimatedCost,
        'estimatedTokens': responsePlan.estimatedTokens,
        'estimatedLatencyMs': responsePlan.estimatedLatency.inMilliseconds,
        'confidence': responsePlan.confidence,
      },
    );

    return CoachPipelineStageOutcome(
      context: context.copyWith(
        decision: decision,
        responsePlan: responsePlan,
      ),
      success: true,
      confidence: decision.confidence,
      reason: 'Coach decision and response plan created.',
    );
  }
}

class _StrategyStageRunner extends CoachPipelineStageRunner {
  const _StrategyStageRunner({
    required this.strategyEngine,
    required this.logger,
  });

  final CoachStrategyEngine strategyEngine;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.strategy;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final coachContext = context.coachContext;
    final decision = context.decision;
    final knowledgeResult = context.knowledgeResult;
    if (coachContext == null || decision == null || knowledgeResult == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: false,
        reason:
            'Context, decision, and knowledge result are required before strategy assembly.',
      );
    }

    final strategyResult = strategyEngine.buildStrategy(
      context: coachContext,
      knowledgeResult: knowledgeResult,
      decision: decision,
    );

    logger.log(
      IntegrationEventType.responsePlanCreated,
      'Strategy engine assembled intelligence package.',
      metadata: <String, Object?>{
        'strategyType': strategyResult.strategy.strategyType.name,
        'strategyValid': strategyResult.isValid,
        'knowledgeNodeId': knowledgeResult.selectedNode.id,
        'knowledgeConfidence': knowledgeResult.confidence,
      },
    );

    return CoachPipelineStageOutcome(
      context: context.copyWith(strategyResult: strategyResult),
      success: strategyResult.isValid,
      confidence: strategyResult.strategy.confidence,
      reason: strategyResult.isValid
          ? 'Strategy assembled from knowledge runtime.'
          : 'Strategy validation failed.',
    );
  }
}

class _StateFinalizeStageRunner extends CoachPipelineStageRunner {
  const _StateFinalizeStageRunner({
    required this.stateIntegration,
    required this.logger,
  });

  final CoachStateIntegration stateIntegration;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.stateFinalize;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final intelligence = context.intentIntelligence;
    final decision = context.decision;
    if (intelligence == null || decision == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: false,
        reason: 'Intent and decision are required before state finalization.',
      );
    }

    final conversationState = await stateIntegration.finalizeAfterDecision(
      userId: context.userId,
      intent: intelligence.primaryIntent,
      decision: decision,
      state: context.conversationState,
      metadata: context.metadata,
      dryRun: context.isPreview,
    );

    if (conversationState != null) {
      logger.log(
        IntegrationEventType.conversationStateUpdated,
        'Conversation state updated.',
        metadata: <String, Object?>{
          'stateId': conversationState.id,
          'phase': conversationState.currentPhase.name,
          'status': conversationState.status.name,
          'pendingQuestionCount': conversationState.pendingQuestions.length,
          'collectedFieldCount': conversationState.collectedFields.length,
        },
      );
    }

    return CoachPipelineStageOutcome(
      context: context.copyWith(conversationState: conversationState),
      success: true,
      reason: 'Conversation state finalized.',
    );
  }
}

class _PromptPlanningStageRunner extends CoachPipelineStageRunner {
  const _PromptPlanningStageRunner({
    required this.promptPlanner,
    required this.validator,
    required this.logger,
  });

  final CoachPromptPlanner promptPlanner;
  final CoachPromptValidator validator;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.promptPlanning;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final coachContext = context.coachContext;
    final responsePlan = context.responsePlan;
    if (coachContext == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: false,
        reason: 'CoachContext is required before prompt planning.',
      );
    }
    if (responsePlan != null && !responsePlan.requiresAI) {
      return CoachPipelineStageOutcome(
        context: context,
        success: true,
        skipped: true,
        confidence: context.decision?.confidence,
        reason: 'Prompt planning skipped because decision does not require AI.',
      );
    }

    final plan = promptPlanner.plan(
      CoachPromptPlanningRequest(
        coachContext: coachContext,
        knowledgeResult: context.knowledgeResult,
        strategyResult: context.strategyResult,
        conversationState: context.conversationState,
        createdAt: coachContext.metadata.buildTime,
      ),
    );
    final validation = validator.validate(plan);
    if (!validation.isValid) {
      return CoachPipelineStageOutcome(
        context: context.copyWith(promptPlan: plan),
        success: false,
        reason: validation.issues.join(' '),
        metadata: <String, Object?>{
          'warnings': plan.warnings,
          'issues': validation.issues,
        },
      );
    }

    logger.log(
      IntegrationEventType.promptPackageCreated,
      'Prompt plan created.',
      metadata: <String, Object?>{
        'sectionCount': plan.sections.length,
        'estimatedTokens': plan.estimatedTokens,
        'remainingTokens': plan.budget.remainingTokens,
        'removedSections': plan.removedSections.map((s) => s.id).toList(),
        'compressedSections':
            plan.compressedSections.map((s) => s.id).toList(),
        'warnings': plan.warnings,
      },
    );

    return CoachPipelineStageOutcome(
      context: context.copyWith(promptPlan: plan),
      success: true,
      confidence: context.decision?.confidence,
      reason: 'Prompt plan created.',
      metadata: <String, Object?>{
        'estimatedTokens': plan.estimatedTokens,
        'remainingTokens': plan.budget.remainingTokens,
        'removedSections': plan.removedSections.map((s) => s.id).toList(),
        'compressedSections':
            plan.compressedSections.map((s) => s.id).toList(),
        'warnings': plan.warnings,
      },
    );
  }
}

class _PromptStageRunner extends CoachPipelineStageRunner {
  const _PromptStageRunner({
    required this.promptBuilder,
    required this.logger,
  });

  final PromptBuilder promptBuilder;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.prompt;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final responsePlan = context.responsePlan;
    final promptPlan = context.promptPlan;
    if (responsePlan != null && !responsePlan.requiresAI) {
      return CoachPipelineStageOutcome(
        context: context,
        success: true,
        skipped: true,
        confidence: context.decision?.confidence,
        reason: 'Prompt skipped because decision does not require AI.',
      );
    }
    if (promptPlan == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: false,
        reason: 'CoachPromptPlan is required before prompt assembly.',
      );
    }

    final promptPackage = promptBuilder.buildFromPlan(promptPlan);

    logger.log(
      IntegrationEventType.promptPackageCreated,
      'Prompt package created.',
      metadata: <String, Object?>{
        'packageId': promptPackage.id,
        'sectionCount': promptPackage.sections.length,
        'estimatedTokens': promptPackage.metadata.estimatedTokens,
      },
    );

    return CoachPipelineStageOutcome(
      context: context.copyWith(promptPackage: promptPackage),
      success: true,
      confidence: context.decision?.confidence,
      reason: 'Prompt package created.',
    );
  }
}

class _ExecutionStageRunner extends CoachPipelineStageRunner {
  const _ExecutionStageRunner({
    required this.executor,
    required this.logger,
  });

  final CoachExecutor executor;
  final IntegrationLogger logger;

  @override
  CoachPipelineStage get stage => CoachPipelineStage.execution;

  @override
  Future<CoachPipelineStageOutcome> run(CoachPipelineContext context) async {
    final responsePlan = context.responsePlan;
    if (responsePlan == null) {
      return CoachPipelineStageOutcome(
        context: context,
        success: false,
        reason: 'Response plan is required before execution preview.',
      );
    }

    final executorPreview = executor.preview(responsePlan);
    logger
      ..log(
        IntegrationEventType.executorPreviewCreated,
        'Executor preview created.',
        metadata: <String, Object?>{
          'executionType': executorPreview.target.name,
          'wouldExecute': executorPreview.wouldExecute,
        },
      )
      ..log(
        IntegrationEventType.pipelineCompleted,
        context.isPreview
            ? 'Coach v2 preview pipeline completed.'
            : 'Coach v2 pipeline completed.',
        metadata: <String, Object?>{
          'processingTimeMs': DateTime.now()
              .difference(context.startedAt)
              .inMilliseconds,
          'mode': context.mode.name,
        },
      );

    return CoachPipelineStageOutcome(
      context: context.copyWith(executorPreview: executorPreview),
      success: true,
      reason: 'Execution preview created.',
    );
  }
}

CoachContext _seedCoachContext({
  required CoachContext seed,
  required String userMessage,
  required AIIntent intent,
}) {
  final currentQuestion =
      seed.currentQuestion != null && seed.currentQuestion!.trim().isNotEmpty
      ? seed.currentQuestion!
      : userMessage;

  return CoachContext(
    intent: intent,
    metadata: seed.metadata,
    profile: seed.profile,
    goals: seed.goals,
    restrictions: seed.restrictions,
    equipment: seed.equipment,
    preferences: seed.preferences,
    activeProgram: seed.activeProgram,
    workoutHistory: seed.workoutHistory,
    weeklyHeatmap: seed.weeklyHeatmap,
    memories: seed.memories,
    apiUsage: seed.apiUsage,
    currentQuestion: currentQuestion,
    conversationSummary: seed.conversationSummary,
  );
}
