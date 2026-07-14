import 'package:gymaipro/ai/coach/coach_brain.dart';
import 'package:gymaipro/ai/context/context_engine.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/entity/entity_extractor.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_runtime.dart';
import 'package:gymaipro/ai/integration/coach_state_integration.dart';
import 'package:gymaipro/ai/integration/entity_memory_integration.dart';
import 'package:gymaipro/ai/integration/integration_logger.dart';
import 'package:gymaipro/ai/intent/intent_intelligence_engine.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_runtime.dart';
import 'package:gymaipro/ai/planner/coach_executor.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_planner.dart';
import 'package:gymaipro/ai/prompt/prompt_builder.dart';
import 'package:gymaipro/ai/skills/coach_skill_engine.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_executor.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_engine.dart';

/// Injected dependencies required to build the Coach v2 pipeline.
///
/// The pipeline layer does not construct concrete services. Callers or a factory
/// must provide every dependency explicitly.
class CoachPipelineDependencies {
  const CoachPipelineDependencies({
    required this.contextRepository,
    required this.contextEngine,
    required this.coachBrain,
    required this.executor,
    required this.promptBuilder,
    required this.logger,
    required this.stateIntegration,
    required this.entityExtractor,
    required this.entityMemoryIntegration,
    required this.intentIntelligenceEngine,
    required this.skillEngine,
    required this.skillExecutor,
    required this.strategyEngine,
    required this.coachKnowledgeRuntime,
    required this.coachEntitlementRuntime,
    required this.coachPromptPlanner,
  });

  final AIContextRepository contextRepository;
  final AIContextEngine contextEngine;
  final CoachBrain coachBrain;
  final CoachExecutor executor;
  final PromptBuilder promptBuilder;
  final IntegrationLogger logger;
  final CoachStateIntegration stateIntegration;
  final EntityExtractor entityExtractor;
  final EntityMemoryIntegration entityMemoryIntegration;
  final IntentIntelligenceEngine intentIntelligenceEngine;
  final CoachSkillEngine skillEngine;
  final CoachSkillExecutor skillExecutor;
  final CoachStrategyEngine strategyEngine;
  final CoachKnowledgeRuntime coachKnowledgeRuntime;
  final CoachEntitlementRuntime coachEntitlementRuntime;
  final CoachPromptPlanner coachPromptPlanner;
}
