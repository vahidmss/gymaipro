import 'package:gymaipro/ai/coach/coach_brain.dart';
import 'package:gymaipro/ai/context/context_builder.dart';
import 'package:gymaipro/ai/context/context_engine.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/entity/entity_extractor.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_runtime.dart';
import 'package:gymaipro/ai/integration/coach_state_integration.dart';
import 'package:gymaipro/ai/integration/entity_memory_integration.dart';
import 'package:gymaipro/ai/integration/integration_logger.dart';
import 'package:gymaipro/ai/intent/intent_intelligence_engine.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_runtime.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_dependencies.dart';
import 'package:gymaipro/ai/planner/coach_executor.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_planner.dart';
import 'package:gymaipro/ai/prompt/prompt_builder.dart';
import 'package:gymaipro/ai/skills/coach_skill_engine.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_executor.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_engine.dart';

/// Creates default Coach v2 pipeline dependencies for integration wiring.
///
/// Concrete construction stays outside the pipeline orchestrator layer.
class CoachPipelineDependenciesFactory {
  const CoachPipelineDependenciesFactory._();

  /// Builds the standard dependency graph used by CoachIntegrationService.
  static CoachPipelineDependencies standard({
    AIContextRepository? contextRepository,
    AIContextEngine? contextEngine,
    CoachBrain? coachBrain,
    CoachExecutor executor = const CoachExecutor(),
    PromptBuilder? promptBuilder,
    IntegrationLogger? logger,
    CoachStateIntegration? stateIntegration,
    EntityExtractor? entityExtractor,
    EntityMemoryIntegration? entityMemoryIntegration,
    IntentIntelligenceEngine? intentIntelligenceEngine,
    CoachSkillEngine? skillEngine,
    CoachSkillExecutor? skillExecutor,
    CoachStrategyEngine? strategyEngine,
    CoachKnowledgeRuntime? coachKnowledgeRuntime,
    CoachEntitlementRuntime? coachEntitlementRuntime,
    CoachPromptPlanner? coachPromptPlanner,
  }) {
    final resolvedRepository = contextRepository ?? AIContextRepository();
    final resolvedContextEngine =
        contextEngine ??
        AIContextEngine(
          contextBuilder: AIContextBuilder.standard(
            repository: resolvedRepository,
          ),
        );
    final resolvedCoachBrain = coachBrain ?? const CoachBrain();

    return CoachPipelineDependencies(
      contextRepository: resolvedRepository,
      contextEngine: resolvedContextEngine,
      coachBrain: resolvedCoachBrain,
      executor: executor,
      promptBuilder: promptBuilder ?? const PromptBuilder(),
      logger: logger ?? IntegrationLogger(),
      stateIntegration: stateIntegration ?? CoachStateIntegration(),
      entityExtractor: entityExtractor ?? const EntityExtractor(),
      entityMemoryIntegration:
          entityMemoryIntegration ?? EntityMemoryIntegration(),
      intentIntelligenceEngine:
          intentIntelligenceEngine ?? IntentIntelligenceEngine(),
      skillEngine: skillEngine ?? CoachSkillEngine(),
      skillExecutor: skillExecutor ?? const CoachSkillExecutor(),
      strategyEngine: strategyEngine ?? CoachStrategyEngine(),
      coachKnowledgeRuntime:
          coachKnowledgeRuntime ?? const CoachKnowledgeRuntime(),
      coachEntitlementRuntime:
          coachEntitlementRuntime ?? const CoachEntitlementRuntime(),
      coachPromptPlanner: coachPromptPlanner ?? const CoachPromptPlanner(),
    );
  }
}
