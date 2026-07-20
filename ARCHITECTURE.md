# GymAI Coach v2 Architecture

This document is the source of truth for the staged GymAI Coach v2
architecture. The current implementation is intentionally dry-run only: it does
not change screens, widgets, OpenAI prompts, APIs, navigation, or workout
generation behavior.

## Folder Structure

```text
lib/ai/context/
  context_engine.dart
  context_builder.dart
  context_models.dart
  context_repository.dart
  intent_detector.dart
  intent_definitions.dart
  prompt_context.dart
  coach_context.dart
  coach_context_metadata.dart
  coach_conversation_summary.dart
  coach_context_assembler.dart
  adapters/
    context_field_reader.dart
    profile_context_adapter.dart
    confidential_context_adapter.dart
    questionnaire_context_adapter.dart
    user_fields_context_adapter.dart
    workout_context_adapter.dart
    heatmap_context_adapter.dart
    api_usage_context_adapter.dart
    memory_context_adapter.dart
  providers/
    base_context_provider.dart
    profile_context_provider.dart
    goals_context_provider.dart
    equipment_context_provider.dart
    restrictions_context_provider.dart
    preferences_context_provider.dart
    active_program_context_provider.dart
    workout_history_context_provider.dart
    heatmap_context_provider.dart
    api_usage_context_provider.dart
    workout_context_provider.dart
    progress_context_provider.dart
    recovery_context_provider.dart
    chat_context_provider.dart

lib/ai/knowledge/
  knowledge_graph.dart
  knowledge_node.dart
  knowledge_requirement.dart
  knowledge_category.dart
  knowledge_registry.dart
  runtime/
    coach_knowledge_runtime.dart
    coach_knowledge_ranker.dart
    coach_knowledge_selector.dart
    coach_knowledge_result.dart
    coach_knowledge_trace.dart
    coach_knowledge_validator.dart

lib/ai/entitlement/
  runtime/
    coach_entitlement_runtime.dart
    coach_entitlement_snapshot.dart
    coach_entitlement_provider.dart
    coach_entitlement_trace.dart
    coach_entitlement_validator.dart

lib/ai/memory/
  coach_memory.dart
  memory_category.dart
  memory_importance.dart
  memory_source.dart
  memory_repository.dart
  memory_manager.dart
  memory_updater.dart
  memory_merger.dart
  memory_validator.dart
  intelligence/
    memory_extractor.dart
    memory_classifier.dart
    memory_deduplicator.dart
    memory_confidence_engine.dart
    memory_rule.dart
    memory_extraction_result.dart
    memory_extraction_reason.dart
    memory_namespace.dart
    memory_conflict_resolver.dart

lib/ai/prompt/
  prompt_builder.dart
  prompt_package.dart
  prompt_section.dart
  prompt_budget.dart
  prompt_compressor.dart
  prompt_personality.dart
  prompt_version.dart
  prompt_metadata.dart
  prompt_validator.dart
  planner/
    coach_prompt_plan.dart
    coach_prompt_budget.dart
    coach_prompt_section.dart
    coach_prompt_priority.dart
    coach_prompt_planner.dart
    coach_prompt_optimizer.dart
    coach_prompt_trace.dart
    coach_prompt_validator.dart

lib/ai/coach/
  coach_brain.dart
  coach_decision.dart
  coach_validator.dart
  coach_rules.dart
  coach_reason.dart
  coach_router.dart

lib/ai/planner/
  coach_response_plan.dart
  coach_action.dart
  coach_executor.dart
  response_step.dart
  response_priority.dart

lib/ai/integration/
  coach_integration_service.dart
  coach_integration_result.dart
  coach_context_state_bridge.dart
  coach_entity_state_integration.dart
  coach_state_integration.dart
  entity_integration_registry.dart
  entity_memory_mapper.dart
  entity_memory_integration.dart
  integration_event.dart
  integration_logger.dart

lib/ai/pipeline/
  coach_pipeline.dart
  coach_pipeline_stage.dart
  coach_pipeline_context.dart
  coach_pipeline_result.dart
  coach_pipeline_trace.dart
  coach_pipeline_validator.dart
  coach_pipeline_builder.dart
  coach_pipeline_dependencies.dart

lib/ai/strategy/
  coach_strategy.dart
  coach_strategy_builder.dart
  coach_strategy_engine.dart
  coach_strategy_reason.dart
  coach_strategy_type.dart
  coach_strategy_validator.dart

lib/ai/state/
  coach_conversation_state.dart
  conversation_phase.dart
  pending_question.dart
  conversation_checkpoint.dart
  state_transition.dart
  coach_state_engine.dart
  coach_state_validator.dart
  coach_state_repository.dart

lib/ai/skills/
  coach_skill.dart
  coach_skill_type.dart
  coach_skill_registry.dart
  coach_skill_engine.dart
  skill_result.dart
  skill_capability.dart

lib/ai/skills/runtime/
  coach_skill_executor.dart
  coach_skill_response.dart
  coach_skill_execution_result.dart
  coach_skill_renderer.dart
  coach_skill_context.dart

lib/ai/skills/intelligence/
  skill_reason.dart
  skill_reason_type.dart
  skill_recommendation.dart
  skill_explanation.dart
  skill_response_builder.dart
  skill_data_validator.dart

lib/ai/intent/
  intent_rule_type.dart
  intent_keyword_dictionary.dart
  intent_rule_definition.dart
  intent_rule_registry.dart
  intent_detection_trace.dart
  intent_regex_matcher.dart
  intent_rule_engine.dart
  intent_scoring_engine.dart
  intent_confidence_calculator.dart
  intent_intelligence_result.dart
  intent_intelligence_engine.dart
  rule_based_intent_resolver.dart

lib/ai/entitlement/
  coach_capability.dart
  coach_subscription_plan.dart
  coach_entitlement.dart
  entitlement_registry.dart
  entitlement_engine.dart
  entitlement_result.dart
  entitlement_validator.dart
  subscription_capability_map.dart
  entitlement_reason.dart
  feature_gate.dart

lib/ai/entity/
  entity_type.dart
  entity_definition.dart
  entity_registry.dart
  entity_match.dart
  entity_extractor.dart
  entity_rule.dart
  entity_rule_engine.dart
  entity_normalizer.dart
  entity_validator.dart
  entity_result.dart
  entity_confidence.dart
  entity_trace.dart

lib/ai/memory/
  memory_context_projector.dart
```

## Pipeline Diagram

```text
User Message
  -> CoachIntegrationService.processMessage()  (flag-gated)
  -> CoachPipeline.run()
       Entity Stage        -> EntityExtractor
       Intent Stage        -> AIIntentDetector + IntentIntelligenceEngine
       State Stage         -> CoachStateIntegration.prepareForMessage()
       Memory Stage        -> EntityMemoryIntegration.applyEntities()
       Context Stage       -> AIContextEngine + CoachContextStateBridge
       Knowledge Stage     -> CoachKnowledgeRuntime.resolve()
       Skill Stage         -> CoachSkillEngine.evaluate() + CoachSkillExecutor
       Entitlement Stage   -> CoachEntitlementRuntime.resolve()
       (local handled)     -> short-circuit decision/strategy/prompt/execution
       Decision Stage      -> CoachBrain.decide/plan from CoachKnowledgeResult
       Strategy Stage      -> CoachStrategyEngine.buildStrategy()
       State Finalize      -> CoachStateIntegration.finalizeAfterDecision()
       Prompt Planning     -> CoachPromptPlanner.plan()
       Prompt Stage        -> PromptBuilder.buildFromPlan()
       Execution Stage     -> CoachExecutor.preview()
  -> CoachIntegrationResult (+ CoachPipelineTrace)
```

`CoachPipeline` is orchestration-only. Stage business rules live in existing
engines and integration helpers. `CoachPipelineConfig.disabledStages` can skip
individual stages in future without changing runtime defaults.

When a runnable skill produces `requiresAI=false` and entitlement is allowed,
the pipeline skips decision, strategy, state finalization, prompt planning,
prompt, and execution stages. If entitlement blocks the local skill, decision
runs and returns an upgrade, usage, disabled, or temporary-lock status without
building a prompt.
`CoachIntegrationService` returns `CoachIntegrationResult.local()` and chat
consumes `decision.localResponse` without building a prompt or calling OpenAI.

The pipeline is feature-flagged for chat. `CoachExecutor.preview()` always
returns a dry-run preview and never executes OpenAI, local UI responses,
navigation, APIs, or workout generation. Strategy and skill stages run for trace
and intelligence assembly; their outputs do not change chat routing yet.

## Module Responsibilities

### Context Engine

- Defines supported intents and context provider requirements.
- Selects providers based on intent definitions.
- Models future prompt context without changing current prompts.
- Adapts existing app services through read-only adapters in `lib/ai/context/adapters/`.
- `AIContextRepository` is the unified facade over profile, confidential,
  questionnaire, workout, heatmap, and local usage adapters.
- `AIContextEngine.buildCoachContext()` assembles immutable `CoachContext`
  packages as the unified output boundary.
- `CoachContextAssembler` maps provider output and read-only memory into
  `CoachContext`.
- `PromptBuilder.buildFromCoachContext()` builds the v2 prompt package when
  `CoachV2Config.coachV2Enabled` is true in chat.
- `CoachV2Config.coachV2Enabled` gates the chat-only Coach v2 pipeline. When
  disabled, legacy chat prompt assembly remains unchanged.
- Registers specialized single-responsibility providers for profile, goals,
  equipment, restrictions, preferences, active program, workout history,
  heatmap, and API usage.
- Keeps older broad providers deprecated but available for migration.

### Knowledge Layer

- Defines the central knowledge graph for Coach intent requirements.
- Maps each intent id to required knowledge, optional knowledge, missing
  behavior, recommended follow-up, default action, and AI requirement.
- `CoachKnowledgeRuntime` ranks and selects knowledge nodes from context
  signals; pipeline stages consume `CoachKnowledgeResult` instead of reading
  `KnowledgeRegistry` directly.
- Provides `KnowledgeRegistry` as the future single source of truth for
  validators, context selection, and response planning.
- Includes planned intent nodes such as `program_review` and
  `heatmap_explanation` without changing current runtime intent detection.

### Memory Engine

- Models persistent and temporary coach memory through `CoachMemory`.
- Supports confidence, importance, source, editability, AI-generated status,
  expiration, and user-editable flags.
- Provides repository, manager, updater, merger, and validator infrastructure.
- Detects memory conflicts during merge without changing current app behavior.
- Is not connected to prompts, OpenAI, screens, widgets, or navigation yet.

### Memory Intelligence Layer

- Extracts memory candidates from user text using deterministic rules only.
- Classifies memory-worthy text, assigns namespaces, and calculates confidence.
- Deduplicates extracted candidates against existing memories.
- Resolves conflicts without calling NLP, LLM, OpenAI, prompts, APIs, or UI.
- Remains infrastructure-only and is not connected to the current runtime.

### Prompt Builder Architecture

- `CoachPromptPlanner` builds a token-aware `CoachPromptPlan` from
  `CoachContext`, selected knowledge, state, memory, and strategy.
- `CoachPromptOptimizer` sorts sections by priority, compresses conversation
  and workout context, removes low-priority heatmap/context when needed, and
  keeps critical system/current-question sections.
- `CoachPromptValidator` enforces critical prompt invariants and records budget
  fallback warnings without using AI summarization.
- `PromptBuilder.buildFromPlan()` renders an optimized plan into
  `PromptPackage`; legacy builder entry points stay available for non-pipeline
  callers.
- Provides prompt budget, metadata, version, validation, trace, and compressor
  contracts.
- Does not render final prompt text and is not connected to existing OpenAI
  prompts or services.

### Coach Brain

- Produces `CoachDecision` from `CoachKnowledgeResult` in the Coach v2 pipeline.
- Records selected knowledge id, confidence, knowledge reasons, and
  entitlement-aware decision status.
- Routes between local, AI, follow-up, upgrade, usage, disabled, temporary-lock,
  or error paths without reading `KnowledgeRegistry` or `AIIntentDefinitions`.
- Legacy provider-selection routing is isolated in
  `CoachLegacyIntegrationService` for flag-off compatibility only.

### Planner

- Models an integration-ready response plan.
- Defines future actions such as `CALL_OPENAI`, `LOCAL_RESPONSE`,
  `FOLLOW_UP`, and navigation-oriented actions.
- Provides a dry-run `CoachExecutor` that classifies execution type but does not
  execute anything.

### Integration

- Runs the Coach v2 chat pipeline behind `CoachV2Config.coachV2Enabled`.
- `CoachIntegrationService` delegates orchestration to `CoachPipeline` when the
  flag is enabled and maps `CoachPipelineResult` to `CoachIntegrationResult`.
- `previewMessage()` runs the same `CoachPipeline` in `CoachPipelineMode.preview`
  (dry-run: no state/memory persistence, no session creation).
- `CoachStateIntegration` loads, resumes, creates, persists, cancels, and
  restarts multi-step conversation state for chat.
- `CoachContextStateBridge` merges `collectedFields` into `CoachContext` before
  brain validation without changing PromptBuilder code.
- Logs each step in memory through `IntegrationLogger`.
- Returns `CoachIntegrationResult` with decision, plan, prompt package, optional
  `conversationState`, and optional `pipelineTrace`.
- Chat uses this service only when `CoachV2Config.coachV2Enabled` is true.
- Is not connected to ChatScreen UI, AIHub, WorkoutGenerator, ProgressAnalysis, or
  navigation beyond the flag-gated chat service hook.

### Unified Decision Pipeline

- `CoachPipeline` executes configured stages in order without embedding
  business rules.
- `CoachPipelineBuilder` wires stage runners to injected
  `CoachPipelineDependencies`; it does not construct concrete services.
- `CoachPipelineDependenciesFactory` in the integration layer creates default
  dependency graphs for `CoachIntegrationService`.
- `CoachPipelineContext` carries mutable cross-stage state; `CoachPipelineTrace`
  records per-stage execution time, success, skipped, confidence, and reason.
- `CoachPipelineConfig` supports `disabledStages` for future feature toggles
  (skill, strategy, memory, intent).
- `CoachKnowledgeRuntime` resolves the best knowledge node after context
  assembly; decision, strategy, and prompt consume `CoachKnowledgeResult`.
- Strategy runs after decision because the strategy engine requires a coach
  decision input; reordering is deferred.

### Skill Runtime

- `CoachRunnableSkill` extends evaluation with `execute()` for local responses.
- `CoachSkillExecutor` runs runnable skills when `CoachV2Config.coachV2Enabled`
  is true and evaluation selected a local candidate.
- `SkillResponseBuilder` produces intelligent responses from `CoachContext`
  with explainability via `SkillReason`, `SkillExplanation`, and
  `SkillRecommendation`.
- `SkillDataValidator` computes dynamic confidence and `requiresAI` fallback.
- Runnable skills: `WorkoutTodaySkill`, `HeatmapSkill`, `MotivationSkill`,
  `AppHelpSkill`. Recovery and progress summary skills remain evaluate-only.

### Strategy Engine

- First layer of Coach Intelligence infrastructure.
- `CoachStrategyEngine` transforms `CoachDecision` into richer `CoachStrategy`
  objects using `CoachContext` and `KnowledgeNode`.
- `CoachStrategyBuilder` performs deterministic, data-only assembly.
- `CoachStrategyValidator` validates inputs and outputs without side effects.
- Wired into the strategy pipeline stage behind `CoachV2Config.coachV2Enabled`;
  strategy output is traced but does not change chat routing yet.
- Overlaps conceptually with `CoachResponsePlan` and `CoachReason`; both layers
  remain until a future migration consolidates planning and intelligence.

### Conversation State Engine

- Models multi-step coach flows such as workout generation, progress analysis,
  and onboarding.
- `CoachStateEngine` manages phases, pending questions, checkpoints, collected
  fields, transition history, resume, expiration, cancellation, and restart.
- `CoachStateRepository` provides optional in-memory and SharedPreferences
  persistence without touching existing chat session storage.
- `CoachStateValidator` validates state snapshots and transitions.
- Wired into `CoachIntegrationService.processMessage()` when
  `CoachV2Config.coachV2Enabled` is true.
- Overlaps conceptually with `CoachConversationSummary`, `CoachDecision`
  follow-up fields, and trainer chat `conversationId` storage.

### Skill Engine

- Determines whether a coach request can be answered locally before OpenAI.
- `CoachSkillEngine` evaluates registered skills against `CoachContext` and
  `AIIntent`, returning `SkillResult` with confidence and fallback guidance.
- Includes local-capable skills such as workout today, heatmap, recovery,
  progress summary, motivation, and app help.
- Infrastructure-only; not connected to `CoachIntegrationService`, prompts,
  OpenAI, UI, navigation, or workout generation yet.
- Overlaps conceptually with `CoachRouter` local routing and
  `CoachRules.localCapableIntents`.

### Intent Intelligence Engine

- Replaces the placeholder intent detector with a data-driven rule-based engine.
- `IntentIntelligenceEngine` uses keyword dictionaries, regex matchers,
  metadata rules, weighted scoring, and confidence calculation.
- Returns immutable `IntentIntelligenceResult` with primary intent, secondary
  alternatives, and per-rule debug trace entries.
- `RuleBasedIntentDetectionResolver` adapts results to legacy
  `IntentDetectionResult` for future flag-gated wiring.
- `AIIntentDetector` remains unchanged by default; no rules are hardcoded inside
  the detector class.
- Infrastructure-only until explicitly injected behind `CoachV2Config`.

### Entitlement Engine

- Models AI access as capabilities, not subscription checks.
- `CoachCapability` is the stable contract future skills, strategies, prompts,
  and services should declare.
- `CoachSubscriptionPlan` is only a bundle of capabilities through
  `SubscriptionCapabilityMap`.
- `EntitlementEngine` evaluates `FeatureGate` plus `CoachEntitlement` snapshots
  and returns immutable `EntitlementResult` values.
- `CoachEntitlementRuntime` is the only Coach pipeline dependency that adapts
  subscription snapshots into capability checks.
- `CurrentSubscriptionAdapter` is read-only; it consumes metadata/current
  subscription objects already in memory and does not call payment services.
- Entitlement stage trace records checked capabilities, missing capabilities,
  remaining usage, upgrade suggestion, and execution time.
- Supports future trial, gift, promo code, enterprise, lifetime, temporary
  unlock, daily, monthly, token, and skill-limit policies without UI/API access.
- Pipeline wiring is gated behind `CoachV2Config.coachV2Enabled`; no existing
  subscription, prompt, OpenAI, UI, navigation, workout generation, or business
  logic paths are changed when the flag is off.

### Entity Intelligence Engine

- Extracts structured entities from user messages before prompt construction.
- `EntityExtractor` runs rule-based keyword and regex extraction without LLMs.
- `EntityRegistry` stores data-driven definitions, synonym dictionaries, and
  extraction rules for FA/EN matching.
- `EntityNormalizer` normalizes units such as kg, cm, hour, liter, and ml.
- `EntityExtractionResult` returns raw matches, normalized entities,
  alternatives, confidence, and per-rule debug trace.
- `CoachEntityStateIntegration` maps `NormalizedEntity` values to pending
  `fieldKey` entries, picks the highest-confidence candidate, and delegates
  answer validation to `CoachStateValidator` through `CoachStateEngine`.
- `CoachStateEngine` receives resolved field values only; it has no dependency
  on `EntityExtractor`.
- When no entity matches a pending question, the integration layer falls back
  to the existing full-message answer behavior.
- `EntityNormalizer` normalizes Persian/Arabic digits and message text before
  rule matching inside `EntityExtractor`.

### Entity → Memory Integration

- `EntityMemoryMapper` converts persistable `NormalizedEntity` values into
  `MemoryUpdateRequest` entries without parsing or extraction.
- Persistable entity types: profile facts, goals, equipment, experience,
  injuries, and medical conditions.
- Ephemeral entity types such as workout-day, time expressions, recovery
  signals, nutrition mentions, and session context are not stored permanently.
- `EntityMemoryIntegration` deduplicates candidates with `MemoryDeduplicator`,
  resolves conflicts through `MemoryConflictResolver`, merges with
  `MemoryMerger`, and persists the resolved snapshot through `MemoryManager`.
- `MemoryManager` has no dependency on `EntityExtractor`; integration wiring
  lives in `CoachIntegrationService` behind `CoachV2Config.coachV2Enabled`.
- `MemoryExtractor` remains infrastructure-only and is not used in the v2 runtime
  path; `EntityExtractor` is the single extraction source.
- `EntityIntegrationRegistry` is the shared mapping source for entity-to-state
  and entity-to-memory integrations.
- `MemoryContextProjector` projects request-scoped memory snapshots into
  `CoachContext` field buckets during context assembly.
- When `EntityMemoryIntegration` writes memories, it returns the resolved memory
  snapshot to `AIContextRequest`; `CoachContextAssembler` consumes that snapshot
  instead of loading memory again from storage in the same request.

## Dependency Graph

```text
integration
  -> planner
  -> coach
  -> strategy (future intelligence)
  -> prompt (future)
  -> memory (future)
  -> knowledge
  -> context
  -> existing read services through AIContextRepository

prompt
  -> context models
  -> knowledge graph
  -> memory models

memory
  -> SharedPreferences persistence only when explicitly called

knowledge
  -> context provider keys
  -> planner action ids

planner
  -> coach decision models
  -> context models

coach
  -> context engine
  -> prompt context models

strategy
  -> coach decision models
  -> coach knowledge result
  -> coach context models

state
  -> coach conversation models
  -> optional SharedPreferences persistence

skills
  -> coach context models
  -> intent definitions

intent
  -> intent detector contracts
  -> keyword dictionary
  -> rule registry

entitlement
  -> capability definitions
  -> plan capability map
  -> immutable entitlement snapshots

entity
  -> rule registry
  -> normalizer
  -> immutable extraction result

integration (entity path)
  -> entity extractor
  -> coach entity state integration
  -> coach state engine (NormalizedEntity values only)

integration (entity memory path)
  -> entity memory mapper
  -> entity memory integration
  -> memory deduplicator
  -> memory manager
  -> memory repository

context
  -> existing services only through adapter/repository boundaries
```

No dependency points from existing screens, widgets, prompts, OpenAI services,
or workout generation flows back into Coach v2 yet.

## Completed Phases

1. **Phase 1: AI Context Engine**
   - Added context models, repository, context builder, intent detector skeleton,
     prompt context, and provider interfaces.

2. **Phase 2: Intent Definitions and Context Selection**
   - Added intent definitions, provider keys, provider metadata, context
     priority, and intent-based provider selection.

3. **Phase 3: Coach Brain**
   - Added coach decision model, reasons, rules, validator, router, and brain.
   - Validation is local and deterministic.

4. **Phase 4: Coach Response Planner**
   - Added response plan, actions, response steps, priorities, and dry-run
     executor preview.

5. **Phase 5: Dry-Run Integration**
   - Added integration service, result DTO, in-memory events, and logger.
   - The full pipeline can be previewed without behavior changes.

6. **EPIC 2 - Task 1: Knowledge Graph**
   - Added a central knowledge layer with categories, requirements, nodes,
     graph access, and registry.
   - Intent knowledge needs are now modeled independently of CoachBrain runtime
     behavior.

7. **EPIC 2 - Task 2: Coach Memory Engine**
   - Added persistent coach memory models, categories, importance, source,
     repository, manager, updater, merger, and validator.
   - Memory infrastructure supports merge, conflict detection, confidence,
     expiration, and permanent/temporary separation.

8. **EPIC 2 - Task 3: Memory Intelligence Layer**
   - Added rule-based memory extraction, classification, deduplication,
     confidence calculation, namespaces, extraction reasons, and conflict
     resolution.
   - No NLP, LLM, OpenAI, prompt, screen, widget, or runtime integration was
     added.

9. **EPIC 2 - Task 4: Prompt Builder Architecture**
   - Added structured prompt package models, sections, budget, compressor,
     personality, version, metadata, validator, and builder.
   - Prompt packages are data-only and are not connected to existing prompts,
     OpenAI, services, screens, widgets, or runtime behavior.

10. **EPIC 2 - Task 5: Specialized Context Providers**
    - Added granular provider classes for profile, goals, equipment,
      restrictions, preferences, active program, workout history, heatmap, and
      API usage.
    - Updated `AIContextBuilder.standard()` so `AIContextEngine` can select the
      granular providers in dry-run flows.
    - Added `AIEquipmentContext` and an equipment provider key so equipment is
      no longer mapped through restrictions.
    - Deprecated broad providers and documented migration paths without
      deleting them.

11. **EPIC 3 - Task 1: Real Data Source Adapters**
    - Added read-only context adapters for profile, confidential info,
      questionnaire, unified user fields, workout, heatmap, and local API usage.
    - Connected goals, equipment, restrictions, and preferences to real project
      sources without adding business logic or new Supabase queries.
    - Added `AIContextEngine.buildCoachContext()` and
      `buildCoachContextForQuestion()` for real dry-run context assembly.
    - Kept Chat, Prompt, OpenAI, navigation, and workout generator runtime
      paths unchanged.

12. **EPIC 3 - Task 2: Unified CoachContext**
    - Added immutable `CoachContext`, metadata, conversation summary placeholder,
      assembler, and read-only memory adapter.
    - Made `AIContextEngine` produce `CoachContext` as its unified output.
    - Added `PromptBuilder.buildFromCoachContext()` as the future prompt entry
      point without connecting existing runtime paths.

13. **EPIC 4 - Task 1: Coach v2 Chat Integration**
    - Added `CoachV2Config.coachV2Enabled` feature flag (default: false).
    - Connected `CoachIntegrationService.processMessage()` to the full pipeline:
      CoachContext -> CoachBrain -> CoachResponsePlan -> PromptBuilder ->
      PromptPackage.
    - Wired chat-only integration behind the feature flag in `AIChatService`.
    - Migrated `CoachBrain` and validation rules to consume `CoachContext` only.
    - Added `PromptPackageRenderer` for v2 system prompt rendering without
      changing `OpenAIService`.

14. **EPIC 5 - Task 1: Coach Strategy Engine**
    - Added `lib/ai/strategy/` with `CoachStrategy`, builder, engine, validator,
      reasons, and strategy types.
    - `CoachStrategyEngine` transforms `CoachDecision` into richer
      `CoachStrategy` using `CoachContext` and `KnowledgeNode`.
    - Infrastructure-only; no runtime, prompt, OpenAI, UI, or navigation wiring.

15. **EPIC 5 - Task 2: Coach Conversation State Engine**
    - Added `lib/ai/state/` with conversation state, phases, pending questions,
      checkpoints, transitions, engine, validator, and repository.
    - `CoachStateEngine` models multi-step flows with resume, expiration,
      cancellation, restart, and collected-field tracking.
    - Infrastructure-only; no runtime, Chat, prompt, OpenAI, UI, or navigation
      wiring.

16. **EPIC 6 - Task 1: State Engine Integration**
    - Wired `CoachStateIntegration` into `CoachIntegrationService.processMessage()`.
    - Added `CoachContextStateBridge` to merge `collectedFields` into
      `CoachContext` before CoachBrain validation.
    - Chat v2 now loads, resumes, persists, cancels, and restarts conversation
      state behind `CoachV2Config.coachV2Enabled`.
    - `AIChatService` passes `sessionId` metadata for resumable chat sessions.

17. **EPIC 6 - Task 2: Coach Skill Engine**
    - Added `lib/ai/skills/` with skill contracts, registry, engine, capabilities,
      and six local-capable skills.
    - `CoachSkillEngine` evaluates whether a request can be answered locally
      before OpenAI using confidence and fallback metadata.
    - Infrastructure-only; no runtime, prompt, OpenAI, UI, or navigation wiring.

18. **EPIC 7 - Task 1: Real Intent Intelligence**
    - Added `lib/ai/intent/` with data-driven keyword dictionary, regex matcher,
      rule registry, weighted scoring, confidence calculation, and debug trace.
    - `IntentIntelligenceEngine` returns primary + secondary intents through
      immutable `IntentIntelligenceResult`.
    - `RuleBasedIntentDetectionResolver` provided for future flag-gated wiring.
    - `AIIntentDetector` default behavior unchanged.

19. **EPIC 7 - Task 2: Entitlement Engine**
    - Added `lib/ai/entitlement/` with capability definitions, subscription plan
      bundles, entitlement snapshots, feature gates, validator, registry, and
      engine.
    - `EntitlementEngine` evaluates immutable `FeatureGate` plus
      `CoachEntitlement` snapshots without touching runtime subscription logic.
    - Capability-first design supports future trial, gift, promo, enterprise,
      lifetime, temporary unlock, daily, monthly, token, and skill limits.

20. **EPIC 8 - Task 1: Entity Intelligence Engine**
    - Added `lib/ai/entity/` with entity definitions, registry, rules, matcher,
      normalizer, confidence calculator, trace, validator, and extractor.
    - `EntityExtractor` extracts height, weight, age, gender, goals, equipment,
      injuries, medical conditions, muscles, exercises, time, supplements,
      food, sleep, and water intake from user messages.
    - Rule-based and data-driven only; no LLM, runtime, prompt, OpenAI, UI, or
      navigation integration.

21. **EPIC 9 - Task 1: Entity → State Integration**
    - Added `CoachEntityStateIntegration` to map `NormalizedEntity` values to
      pending `fieldKey` entries and resolve questions into
      `collectedFields`.
    - Wired entity extraction into `CoachIntegrationService.processMessage()`
      behind `CoachV2Config.coachV2Enabled`.
    - `CoachStateIntegration.prepareForMessage()` tries entity resolution first,
      then falls back to full-message answers when no matching entity is found.
    - Integration consumes entity output only; normalization and entity
      validation stay in the entity module, answer validation stays in
      `CoachStateValidator`.
    - `CoachStateEngine` has no direct dependency on `EntityExtractor`.

22. **EPIC 9 - Task 2: Entity → Memory Integration**
    - Added `EntityMemoryMapper` and `EntityMemoryIntegration` to persist
      persistable `NormalizedEntity` values into coach memory.
    - Wired memory writes into `CoachIntegrationService.processMessage()`
      behind `CoachV2Config.coachV2Enabled`.
    - Uses `MemoryDeduplicator`, `MemoryMerger`, and `MemoryConflictResolver`
      before persisting through `MemoryManager`.
    - `MemoryExtractor` is not used in runtime; `EntityExtractor` remains the
      only extraction source.

23. **EPIC 9 - Task 3: Memory → Context Integration + Runtime Cleanup**
    - Added request-scoped memory snapshots to `AIContextRequest` so context
      assembly can use memories written in the same message without a second
      repository fetch.
    - Added `MemoryContextProjector` to project memory keys into
      `CoachContext` profile, goals, restrictions, equipment, and preferences.
    - Added `EntityIntegrationRegistry` and migrated state/memory integrations
      to the shared entity mapping source.
    - Removed runtime double merge from the entity-memory path:
      `MemoryDeduplicator` is the merge/conflict source of truth and
      `MemoryManager.saveResolvedMemories()` persists the resolved snapshot.
    - Added focused integration test coverage for same-request memory snapshot
      projection into context and prompt package memory keys.

24. **EPIC 10 - Task 1: Unified Decision Pipeline**
    - Added `lib/ai/pipeline/` orchestrator: `CoachPipeline`, stage enum,
      context, result, trace, validator, and builder with per-stage runners.
    - `CoachIntegrationService.processMessage()` delegates to `CoachPipeline`
      when `CoachV2Config.coachV2Enabled` is true; runtime behavior preserved.
    - `CoachIntegrationResult` now optionally includes `pipelineTrace`.
    - Each stage records execution time, success, skipped, confidence, and
      reason for future observability and configuration-based disabling.
    - `previewMessage()` orchestration migration deferred; legacy path kept with
      TODO.
    - Added unit tests for stage order, skipped stages, failed stages, and trace
      generation.

25. **EPIC 10 - Task 2: Skill Runtime & Pipeline DI**
    - Added `lib/ai/skills/runtime/` with executor, response, renderer, and
      execution result types.
    - `CoachRunnableSkill` adds `execute()` for `WorkoutTodaySkill`,
      `HeatmapSkill`, `MotivationSkill`, and `AppHelpSkill`.
    - Local skill responses short-circuit decision/strategy/prompt/execution
      stages; `CoachIntegrationResult.local()` maps to chat without OpenAI.
    - `CoachPipelineDependencies` + `CoachPipelineDependenciesFactory` move
      concrete construction out of `CoachPipelineBuilder`.
    - Skill stage trace records executed skill, execution time, local response,
      and `requiresAI` metadata.
    - Added unit tests for local execution, AI fallback, DI source checks, and
      pipeline short-circuit behavior.

26. **EPIC 11 - Task 1: Real Skill Intelligence**
    - Added `lib/ai/skills/intelligence/` with reasons, recommendations,
      explanations, data validator, and `SkillResponseBuilder`.
    - Extended `CoachSkillResponse` with explainability fields: `reasons`,
      `explanation`, `recommendations`, `warnings`, `nextActions`.
    - WorkoutToday, Heatmap, Motivation, and AppHelp skills now produce
      data-driven responses and dynamic confidence from `CoachContext` only.
    - Reuses `WeeklyMuscleHeatmapResult` / `MuscleHeatmapInsights` outputs;
      no new prompts, APIs, or queries.
    - Insufficient data returns `requiresAI=true` and preserves AI fallback.
    - Added focused unit tests for all four skills, explainability, confidence,
      and AI fallback.

27. **EPIC 12 - Task 1: Knowledge Runtime Pipeline Integration**
    - Added `lib/ai/knowledge/runtime/` with ranker, selector, validator,
      trace, result, and `CoachKnowledgeRuntime` orchestrator.
    - New `CoachPipelineStage.knowledge` runs after context assembly and before
      skill/decision; stages consume `CoachKnowledgeResult` instead of reading
      `KnowledgeRegistry` directly.
    - Weighted ranking uses intent, entity, goal, restriction, equipment,
      active program, conversation state, memory relevance, and priority signals.
    - Validator falls back to `general_chat` without exceptions when no node
      meets the minimum score.
    - `CoachBrain`, strategy, and prompt stages consume resolved knowledge;
      behavior gated behind `CoachV2Config.coachV2Enabled`.
    - Added unit tests for ranking, fallback, priority, trace overlap signals,
      and flag-off runtime skip.

28. **EPIC 13 - Task 1: Knowledge Decisions + Entitlement Runtime**
    - `CoachBrain` now makes Coach v2 decisions from `CoachKnowledgeResult`
      instead of `AIIntentDefinitions` provider routing.
    - Added `CoachDecisionStatus`, selected knowledge id, knowledge confidence,
      and knowledge reasons to `CoachDecision`.
    - Moved legacy provider-selection routing behind `CoachLegacyDecisionAdapter`
      for flag-off and preview paths.
    - Added `lib/ai/entitlement/runtime/` with runtime, provider, snapshot,
      validator, result, and trace models.
    - Pipeline order is now `knowledge -> skill -> entitlement -> decision`;
      entitlement can block local skills before any prompt/execution path.
    - `CoachStrategyEngine` consumes `CoachKnowledgeResult`; prompt stage passes
      only `selectedNode` to `PromptBuilder`.
    - Added tests for knowledge-driven decisions, allowed/blocked entitlement,
      usage exhaustion, disabled features, upgrade suggestions, trace, stage
      order, and flag-off runtime skip.

29. **EPIC 14 - Task 1: Prompt Planning Engine**
    - Added `lib/ai/prompt/planner/` with prompt plan, budget, section,
      priority, planner, optimizer, trace, and validator models.
    - `CoachPromptPlanner` produces `CoachPromptPlan` before prompt package
      rendering; `PromptBuilder.buildFromPlan()` only renders selected sections.
    - Prompt planning supports critical/high/medium/low priorities, token budget
      accounting, removed sections, compressed sections, warnings, and trace.
    - Rule-based optimizer compresses conversation first, removes heatmap,
      compresses workout history, trims memory, and keeps system/current
      question sections.
    - Added `CoachPipelineStage.promptPlanning` before prompt assembly; pipeline
      prompt stage now consumes `CoachPromptPlan`.
    - Added tests for budget, priority sorting, compression, removals, critical
      retention, trace, validator, and pipeline stage order.

30. **EPIC 15 - Task 1: Preview Pipeline Migration**
    - Added `CoachPipelineMode` (`runtime`, `preview`) on pipeline context,
      result, and trace.
    - `previewMessage()` delegates to `CoachPipeline.run()` in preview mode;
      legacy preview orchestration removed.
    - State, memory, and state-finalize stages accept `dryRun` when
      `mode == preview`; knowledge, entitlement, and skill run via
      `coachPipelineV2Active()` even when the feature flag is off.
    - `CoachIntegrationResult.pipelineMode` unifies runtime and preview results.
    - `CoachLegacyDecisionAdapter` deprecated; retained only for flag-off
      `processMessage()` fallback.
    - Added `test/ai/integration/coach_preview_pipeline_test.dart` (9 tests).

31. **EPIC 16 - Legacy Retirement Phase 1**
    - Extracted flag-off path to `CoachLegacyIntegrationService`; v2
      `CoachIntegrationService` no longer imports `CoachLegacyDecisionAdapter`.
    - Production entry: `AIChatService` gates v2; flag-off uses OpenAI directly.
    - `CoachPipeline` verified free of legacy decision imports.
    - Full audit documented below: intent, prompt, context, pipeline boundary,
      dead infrastructure, dependency graph. No runtime behavior change.

32. **EPIC 17 - Runtime Stabilization & Intent Unification**
    - Pipeline intent stage calls `IntentIntelligenceEngine` only; removed dual
      `AIIntentDetector` shadow path and `intentDetection` context field.
    - All downstream stages read `intentIntelligence` / `context.intent`.
    - Removed forward-read of `strategyResult` in entitlement stage.
    - Removed unused `intentConfidence` / `intentReason` getters.
    - Deleted runtime-dead: `MemoryExtractor` tree, `WorkoutContextProvider`,
      `ProgressContextProvider`.
    - Migrated `memory_context_integration_test` to `buildFromPlan`.
    - Simplified preview tests (no custom `AIIntentDetector` injection).
    - `flutter test`: 105/105 passed. Full audit below.

33. **EPIC 18 - Legacy Removal & Runtime Finalization**
    - Deleted: `CoachLegacyDecisionAdapter`, `CoachLegacyIntegrationService`,
      `CoachValidator`, `CoachRouter`, `RuleBasedIntentDetectionResolver`,
      `CoachContextStateBridge`, `PromptContext`, `PromptContextPatch`,
      `AI*Context` typed models, `PromptBuilder.build()` / `buildFromCoachContext()`,
      `PromptCompressor`, `AIIntentDetector`.
    - `CoachContext` is the sole context package; providers emit
      `CoachContextPatch`; `withCollectedFields()` inlined state merge.
    - `PromptBuilder` exposes only `buildFromPlan()`.
    - `CoachIntegrationService` is the single integration entry; flag-off
      `processMessage()` throws `UnsupportedError`.
    - Removed `providerSelection` from pipeline/integration results.
    - `flutter test`: 105/105 passed. Final audit below.

## EPIC 18 — Legacy Removal & Runtime Finalization Audit

Architecture score: **8/10 → 9/10** (legacy paths removed; single context model;
single prompt builder; single pipeline; clear result boundaries).

### Final Counts (target: canonical runtime = 1 each)

| Category | Count | Canonical type | Notes |
|----------|------:|----------------|-------|
| Legacy classes | **0** | — | All migration legacy removed |
| Migration bridges | **0** | — | `CoachContextStateBridge`, `toPromptContext()` gone |
| Migration adapters | **0** | — | `CoachLegacyDecisionAdapter` etc. deleted |
| Runtime entry points | **1** | `CoachIntegrationService` | Production gates at `AIChatService` |
| Context models (runtime) | **1** | `CoachContext` | `CoachContextPatch` is provider merge only (not a second runtime model) |
| Prompt builders | **1** | `PromptBuilder.buildFromPlan()` | Planner owns section selection |
| Pipelines | **1** | `CoachPipeline` | Single orchestrator |

### Deleted Legacy & Bridges

| Removed | Was |
|---------|-----|
| `CoachLegacyDecisionAdapter` | Flag-off provider-selection decisions |
| `CoachLegacyIntegrationService` | Flag-off integration path |
| `CoachValidator`, `CoachRouter` | Legacy decision only |
| `RuleBasedIntentDetectionResolver` | `AIIntentDetector` bridge |
| `AIIntentDetector`, `IntentDetectionResult` | Replaced by `IntentIntelligenceEngine` everywhere |
| `PromptContext`, `PromptContextPatch`, `AI*Context` types | Replaced by `CoachContext` / `CoachContextPatch` |
| `toPromptContext()` | Legacy prompt bridge |
| `PromptBuilder.build()`, `buildFromCoachContext()` | Legacy prompt assembly |
| `PromptCompressor` | Superseded by `CoachPromptOptimizer` |
| `CoachContextStateBridge` | Inlined as `CoachContext.withCollectedFields()` |
| `CoachResponsePlan.fromDecision()` | Legacy adapter factory |

### Context Unification

```text
Providers → CoachContextPatch → AIContextBuilder.merge()
         → CoachContextAssembler → CoachContext
         → (+ withCollectedFields from conversation state)
         → Pipeline stages → CoachPromptPlanner → buildFromPlan()
```

No `PromptContext` remains. Data-layer adapters under `lib/ai/context/adapters/`
(9 files) are **repository readers**, not migration adapters — they stay.

### Result Boundaries (reviewed, kept intentionally)

| Type | Layer | Role |
|------|-------|------|
| `CoachPipelineResult` | Pipeline (internal) | Stage context + trace; not exposed to UI |
| `CoachIntegrationResult` | Integration (public) | Facade for `AIChatService` / preview |
| `CoachExecutionPreview` | Planner (embedded) | Dry-run execution contract inside integration result |

Three types remain by design: pipeline internals vs public integration API vs
executor preview contract. Fields are not duplicated at the same boundary.

### Flag-Off Behavior

- `AIChatService` (production chat): OpenAI direct — unchanged.
- `CoachIntegrationService.processMessage()` when flag off: **`UnsupportedError`**
  (no legacy fallback).
- `CoachIntegrationService.previewMessage()`: still runs pipeline in preview mode.

### Verification

```text
flutter test  → 105/105 passed
```

### Remaining (non-migration, acceptable)

| Item | Count | Classification |
|------|------:|----------------|
| Data adapters (`context/adapters/`) | 9 | Infrastructure — reads Supabase/repos |
| `AIIntentDefinitions` | 1 | Provider selection for `AIContextEngine` |
| `CoachContextPatch` | 1 | Provider merge artifact (not runtime boundary) |
| Deprecated providers (`Chat`, `Recovery`) | 2 | Registered but return minimal patches |

## EPIC 17 — Runtime Stabilization & Intent Unification Audit

Architecture score: **7.5/10 → 8/10** (intent runtime unified; shadow path
removed; dead infrastructure deleted; pipeline forward-dependency fixed;
legacy bridges narrowed).

### Task 1 — Real Intent Runtime (implemented)

**Before:** `_IntentStageRunner` called both `AIIntentDetector` and
`IntentIntelligenceEngine`; only `intentDetection` was stored and read
downstream (factory used empty resolvers → always `generalChat`).

**After:**

```text
CoachPipeline → _IntentStageRunner → IntentIntelligenceEngine.detect()
                → IntentIntelligenceResult → all downstream stages
```

| Component | Consumers | Runtime? | Classification |
|-----------|-----------|----------|----------------|
| `IntentIntelligenceEngine` | `_IntentStageRunner`, factory default, `RuleBasedIntentDetectionResolver` (internal) | **Yes — authoritative v2** | **Runtime** |
| `AIIntentDetector` | `CoachLegacyIntegrationService` (1), `AIContextEngine._detectIntent` (1, only when intent omitted), factory wiring to `AIContextEngine` (pass-through) | Legacy flag-off + context-engine fallback | **Legacy** |
| `RuleBasedIntentDetectionResolver` | 0 callers | No | **Legacy bridge — keep for optional `AIIntentDetector` wiring** |

`CoachPipelineDependencies` no longer carries `intentDetector`.
`AIIntentDetector` remains for flag-off `CoachLegacyIntegrationService` and
`AIContextEngine` paths where intent is not pre-supplied.

### Task 2 — Remove Dual Intent (implemented)

| Model | Pipeline v2 | Legacy |
|-------|-------------|--------|
| `IntentIntelligenceResult` | **Single source** on `CoachPipelineContext` | — |
| `IntentDetectionResult` | Not used | `AIIntentDetector`, `RuleBasedIntentDetectionResolver.toDetectionResult()` |

Removed `intentDetection` field from `CoachPipelineContext`. Adapter
`toDetectionResult()` retained for legacy bridge only.

### Task 3 — Unused Pipeline Fields (implemented)

| Field / getter | Action |
|----------------|--------|
| `intentDetection` | **Removed** — zero consumers after unification |
| `intentConfidence`, `intentReason` getters | **Removed** — zero consumers |
| `intentIntelligence` | **Kept** — all intent stages consume it |
| `providerSelection` on context | **Kept** — unset in v2; legacy adapter only (not removed — risk) |

No duplicate confidence fields removed from stage traces (trace confidence is
per-stage metadata, not duplicate intent storage).

### Task 4 — Pipeline Order (analyzed + safe fix)

**Constraint analysis (no reorder — would change business logic):**

- `CoachStrategyEngine.buildStrategy()` requires `CoachDecision` → strategy
  must run **after** decision.
- `CoachBrain.decide()` reads `entitlementResult` for blocking → entitlement
  must run **before** decision.
- Therefore `knowledge → skill → strategy → entitlement → decision` is **invalid**.

**Safe fix applied:** `_EntitlementStageRunner` no longer passes
`strategyResult` (was always `null` — forward dependency removed). Order
unchanged:

```text
entity → intent → state → memory → context → knowledge → skill
→ entitlement → decision → strategy → stateFinalize → promptPlanning
→ prompt → execution
```

### Task 5 — Dead Runtime Removal (implemented)

| Deleted | Runtime consumers before delete |
|---------|--------------------------------|
| `memory_extractor.dart` | 0 |
| `memory_classifier.dart` | 1 (extractor only) |
| `memory_extraction_result.dart` | 1 (extractor only) |
| `workout_context_provider.dart` | 0 (not in `AIContextBuilder.standard()`) |
| `progress_context_provider.dart` | 0 (not in `AIContextBuilder.standard()`) |

**Kept (have consumers):** `memory_rule.dart`, `memory_confidence_engine.dart`
(used by conflict resolver / deduplicator).

### Task 6 — Prompt Test Migration (implemented)

| Test | Before | After |
|------|--------|-------|
| `memory_context_integration_test.dart` | `buildFromCoachContext()` | `CoachPromptPlanner.plan()` → `buildFromPlan()` |

No remaining test callers of `buildFromCoachContext()` or `PromptBuilder.build()`.

### Task 7 — Runtime Consumer Matrix

| Class | Consumer count | Consumers | Runtime | Test | Legacy | Dead |
|-------|----------------|-----------|---------|------|--------|------|
| `AIIntentDetector` | 3 | `CoachLegacyIntegrationService`, `AIContextEngine`, factory→`AIContextEngine` | — | — | **Yes** | — |
| `RuleBasedIntentDetectionResolver` | 0 | — | — | — | Bridge only | — |
| `IntentIntelligenceEngine` | 2 | `_IntentStageRunner`, `RuleBasedIntentDetectionResolver` (internal) | **Yes** | — | — | — |
| `MemoryExtractor` | 0 | — | — | — | — | **Deleted** |
| `CoachLegacyDecisionAdapter` | 1 | `CoachLegacyIntegrationService` | — | — | **Yes** | — |
| `PromptBuilder.build()` | 1 | `buildFromCoachContext()` (internal) | — | — | **Yes** | — |
| `PromptBuilder.buildFromCoachContext()` | 0 | — | — | — | **Yes** (no callers) | Remove candidate |

### Dead Code (runtime zero consumers)

| Item | Status |
|------|--------|
| `MemoryExtractor` tree | **Deleted** |
| `WorkoutContextProvider`, `ProgressContextProvider` | **Deleted** |
| `RuleBasedIntentDetectionResolver` | Kept — legacy bridge, 0 callers (remove candidate) |
| `PromptBuilder.buildFromCoachContext()` | Kept — 0 callers post-migration (remove candidate) |
| `PromptBuilder.build()` | Kept — internal legacy only |
| `providerSelection` on `CoachPipelineContext` | Kept — legacy field, unset in v2 |

### Duplicate Models / Mapping / Validation / Bridges

Unchanged from EPIC 16 audit (see sections below). EPIC 17 did not merge
`AIIntentDefinitions` / `IntentRuleRegistry` or `CoachContext` / `PromptContext`
— high-risk, no behavior change requested.

**Bridges remaining:**

- `RuleBasedIntentDetectionResolver` → `AIIntentDetector` (unwired)
- `IntentIntelligenceResult.toDetectionResult()` → `IntentDetectionResult`
- `CoachLegacyDecisionAdapter` → `AIIntentDefinitions` provider selection
- `CoachContext.toPromptContext()` → legacy `PromptBuilder.build()`
- `CoachLegacyIntegrationService` → flag-off compat entry

### Remove Candidates (post-EPIC 17)

| Item | Risk | Notes |
|------|------|-------|
| `RuleBasedIntentDetectionResolver` | Low | Wire into legacy `AIIntentDetector` or delete |
| `PromptBuilder.build()` + `buildFromCoachContext()` | Medium | No callers; keep until explicit legacy retirement EPIC |
| `CoachLegacyIntegrationService` + adapter | High | Flag-off compat |
| `providerSelection` pipeline field | Low | Unset in v2 |
| `AIIntentDefinitions` | High | Legacy provider routing |

### Verification

```text
flutter test   → 105/105 passed
flutter analyze lib/ai/pipeline lib/ai/integration lib/ai/intent test/ai
               → 0 errors (info-level comment/style only)
```

## EPIC 16 — Legacy Retirement Phase 1 Audit

Architecture score: **7/10 → 7.5/10** (legacy decision isolated; pipeline boundary
cleaner; intent/context/prompt duplicates remain).

### Task 1 — Legacy Decision Layer (implemented)

| Consumer | Path | Status after EPIC 16 |
|----------|------|----------------------|
| `CoachPipeline` / `coach_pipeline_builder.dart` | — | **No import** of `CoachLegacyDecisionAdapter` |
| `CoachIntegrationService.processMessage` (flag on) | `CoachPipeline` → `CoachBrain` | **v2 only** |
| `CoachIntegrationService.processMessage` (flag off) | Delegates to `CoachLegacyIntegrationService` | **Compatibility entry** |
| `AIChatService.sendMessage` (flag off) | OpenAI + `_buildSystemPrompt` | **Never hits legacy adapter** |
| `CoachLegacyIntegrationService` | `CoachLegacyDecisionAdapter` | **Only remaining consumer** |

`CoachLegacyDecisionAdapter` remains `@Deprecated`; delete candidate after
`CoachLegacyIntegrationService` is removed in a future EPIC.

### Task 2 — Intent Unification Audit (report only)

| Component | Role | Runtime? |
|-----------|------|----------|
| `AIIntentDetector` (factory: empty resolvers) | Writes `intentDetection` | **Authoritative in prod** (always `generalChat`) |
| `IntentIntelligenceEngine` | Writes `intentIntelligence` | **Shadow** — logged, never read downstream |
| `RuleBasedIntentDetectionResolver` | Bridges intelligence → detector | **Test/preview inject only** |
| `AIIntentDefinitions` | Provider requirements per intent | **Legacy path** + `AIContextEngine.selectProviders` |
| `IntentRuleRegistry` + `IntentKeywordDictionary` | Detection rules | **Active infra, unwired in prod** |

**Duplicate mappings:** Two registries per `AIIntent` — `AIIntentDefinitions`
(routing/providers) vs `IntentRuleRegistry` (detection keywords/regex).

**Merge candidate (EPIC 17):** Wire `RuleBasedIntentDetectionResolver` in factory
or drop dual-call in `_IntentStageRunner`.

### Task 3 — PromptBuilder Cleanup (report only)

| Entry point | Callers | Classification |
|-------------|---------|----------------|
| `buildFromPlan(CoachPromptPlan)` | `_PromptStageRunner` | **Runtime v2 + preview** |
| `buildFromCoachContext()` | `memory_context_integration_test.dart` | **Legacy bridge / test** |
| `build(PromptBuildRequest)` | Internal via `buildFromCoachContext` | **Legacy** (uses `KnowledgeGraph` directly) |

**Removable later:** `build()` + `buildFromCoachContext()` after test migration.

### Task 4 — Context Stack Audit (report only)

| Field | CoachContext | PromptContext / Patch | Duplicate | Consumer |
|-------|--------------|----------------------|-----------|----------|
| Profile | `profile: Map` | `userProfile` patch | Yes | Assembler, planner, legacy builder |
| Goals | `goals: List` | `goal` patch | Yes | Same |
| Restrictions | `restrictions` | `restrictions` patch | Yes | Same |
| Equipment | `equipment` | `equipment` patch | Yes | Same |
| Preferences | `preferences` | `preferences` patch | Yes | Same |
| Workout | `activeProgram`, `workoutHistory` | `workout` patch | Yes | Same |
| Heatmap | `weeklyHeatmap` | `heatmap` patch | Yes | Same |
| Memory | `memories: List<CoachMemory>` | `memory` key map | Partial | Assembler, planner |
| API usage | `apiUsage` | `apiUsage` patch | Yes | Providers |
| Question | `currentQuestion` | `currentQuestion` patch | Yes | Pipeline input |
| Recovery | — | `recovery` patch only | Gap | Deprecated provider only |
| Chat/history | `conversationSummary` (placeholder) | `chat`, `history` | Partial | Not in `toPromptContext()` |
| Intent | `intent` | — | Coach-only | All stages |
| Metadata | `CoachContextMetadata` | — | Coach-only | Entitlement, trace |

**Migration-only:** `toPromptContext()`, `PromptContext`, `PromptContextPatch`.

### Task 5 — Pipeline Boundary Audit (report only)

Execution order: `entity → intent → state → memory → context → knowledge →
skill → entitlement → decision → strategy → stateFinalize → promptPlanning →
prompt → execution`.

| Stage | Writes (persist) | Direct registry? | Violation |
|-------|----------------|------------------|-----------|
| entity | No | `EntityRegistry` via extractor | None |
| intent | No | Via resolvers/engine | **Dual detect; intelligence unused** |
| state | `CoachStateRepository` (dryRun in preview) | No | None |
| memory | `MemoryRepository` (dryRun in preview) | No | None |
| context | No | Via providers/adapters | None |
| knowledge | No | `CoachKnowledgeRuntime` only | None |
| skill | No | `CoachSkillRegistry` | None |
| entitlement | No | Entitlement registry via runtime | Reads `strategyResult` **before strategy runs** |
| decision | No | No | Bundles `decide()` + `plan()` |
| strategy | No | No | None |
| stateFinalize | State repo (dryRun in preview) | No | None |
| promptPlanning | No | No | None |
| prompt | No | No | `buildFromPlan` only |
| execution | No | No | Dry-run preview only |

No stage calls a later stage directly. `providerSelection` on pipeline context
is never set in v2 (legacy-only field).

### Task 6 — Dead Infrastructure Scan (report only)

| Item | Classification |
|------|----------------|
| `pipeline/`, `coach_brain.dart`, planner runtime | **Active** |
| `CoachLegacyDecisionAdapter`, `CoachLegacyIntegrationService` | **Compatibility** |
| `ChatContextProvider`, `RecoveryContextProvider` | **Deprecated / compatibility** |
| `WorkoutContextProvider`, `ProgressContextProvider` | **Remove candidate** |
| `MemoryExtractor` tree | **Runtime dead** |
| `RuleBasedIntentDetectionResolver` (unwired) | **Remove or wire** |
| `intentIntelligence` pipeline field | **Runtime dead field** |
| `CoachSkill.previewMessage` field | **Runtime dead** |
| `PromptBuilder.build` / `buildFromCoachContext` | **Legacy / test** |
| `previewMessage()` service API | **Active API; test-only callers** |

### Task 7 — Dependency Graph (EPIC 16)

```text
AIChatService
  ├─ coachV2Enabled → CoachIntegrationService.processMessage → CoachPipeline
  │                     entity → intent → state → memory → context
  │                     → knowledge → skill → entitlement → decision
  │                     → strategy → stateFinalize → promptPlanning
  │                     → prompt (buildFromPlan) → execution (preview)
  │                     → PromptPackageRenderer → OpenAI
  └─ !coachV2Enabled → OpenAIService (no CoachPipeline)

CoachIntegrationService (!flag, compat only)
  → CoachLegacyIntegrationService → CoachLegacyDecisionAdapter

CoachPipeline
  → integration helpers (state, memory) — layering coupling, no import cycle
  → NO CoachLegacyDecisionAdapter
```

No module import cycle. Soft issues: entitlement reads `strategyResult` before
strategy stage; integration helpers imported by pipeline builder.

## Pending Phases

- Unit tests for intent definitions, provider selection, coach decisions,
  response plans, strategy assembly, conversation state transitions, skill
  evaluation, intent rule scoring, entitlement decisions, entity extraction,
  and dry-run integration results.
- Expand knowledge-driven validation coverage for all node-specific missing-data
  rules now that CoachBrain routing no longer uses intent definitions.
- Connect memory reads through a dedicated `MemoryContextProvider`.
- Add tests for rule-based memory extraction, confidence, deduplication, and
  conflict resolution.
- Real rule/keyword/regex intent resolvers.
- Dedicated providers still pending for memory, nutrition, app help,
  diagnostics, and typed recovery readiness.
- Feature-flagged integration with ChatScreen in preview-only mode.
- Prompt template registry that consumes `CoachPromptPlan` without mutating
  existing OpenAI prompts.
- Broader integration tests for PromptBuilder plan rendering and renderer output.
- Optional telemetry boundary after product approval.

## Current Technical Debt

EPIC 14.5 audit scope: `lib/ai/`. No low-risk runtime code removal was found:
all temporary bridges still have active consumers in flag-off, preview, or v2
pipeline paths. Cleanup in this pass is documentation-only.

### Duplicate Models

- Location: `lib/ai/context/coach_context.dart`,
  `lib/ai/context/prompt_context.dart`, `lib/ai/context/context_models.dart`
  - Reason: `CoachContext` is the v2 boundary, while `PromptContext` and
    `AI*Context` models still power legacy prompt/context provider assembly.
  - Current consumers: `AIContextBuilder`, `CoachContextAssembler`,
    `PromptBuilder.build()`, `PromptBuilder.buildFromCoachContext()`.
  - Safe to remove: No.
  - Migration needed: Move all legacy prompt package builders to
    `CoachPromptPlan` and make context providers emit `CoachContext` patches.
  - Suggested replacement: `CoachContext` plus `CoachPromptPlanner`.
  - Risk level: High.

- Location: `lib/ai/planner/coach_executor.dart`,
  `lib/ai/pipeline/coach_pipeline_result.dart`,
  `lib/ai/integration/coach_integration_result.dart`
  - Reason: execution preview, pipeline result, and integration result repeat
    intent, timing, confidence, and routing metadata at different boundaries.
  - Current consumers: `CoachIntegrationService`, `AIChatService`, pipeline
    tests, local skill result mapping.
  - Safe to remove: No.
  - Migration needed: Introduce a single read model after Chat v2 no longer
    needs legacy dry-run preview compatibility.
  - Suggested replacement: Keep `CoachPipelineResult` internal; expose a smaller
    `CoachIntegrationResult` facade.
  - Risk level: Medium.

### Duplicate Mapping

- Location: `lib/ai/context/intent_definitions.dart`,
  `lib/ai/knowledge/knowledge_registry.dart`
  - Reason: intent-to-provider requirements are duplicated with
    knowledge-node requirements.
  - Current consumers: `AIContextEngine.selectProviders()`,
    `CoachLegacyDecisionAdapter`, `CoachValidator`, `CoachRouter`,
    `CoachResponsePlan.fromDecision()`.
  - Safe to remove: No.
  - Migration needed: Remove preview/flag-off dependency on provider selection,
    or create a compatibility adapter from `KnowledgeNode` to provider
    selection.
  - Suggested replacement: `KnowledgeRegistry` through `CoachKnowledgeRuntime`.
  - Risk level: High.

- Location: `lib/ai/integration/entity_integration_registry.dart`,
  `lib/ai/integration/entity_memory_mapper.dart`,
  `lib/ai/integration/coach_entity_state_integration.dart`
  - Reason: entity-to-memory and entity-to-state mapping share a registry but
    still have separate integration flows.
  - Current consumers: `EntityMemoryIntegration`, `CoachStateIntegration`.
  - Safe to remove: No.
  - Migration needed: Unify application results only after memory/state
    persistence behavior is fully covered.
  - Suggested replacement: Keep shared registry; merge result shapes later.
  - Risk level: Medium.

### Duplicate Validation

- Location: `lib/ai/coach/coach_validator.dart`,
  `lib/ai/knowledge/runtime/coach_knowledge_validator.dart`,
  `lib/ai/entitlement/runtime/coach_entitlement_validator.dart`,
  `lib/ai/prompt/planner/coach_prompt_validator.dart`,
  `lib/ai/strategy/coach_strategy_validator.dart`
  - Reason: validators are intentionally boundary-specific but some missing-data
    validation overlaps between `CoachValidator` and knowledge requirements.
  - Current consumers: legacy decision adapter, knowledge runtime, entitlement
    runtime, prompt planning, strategy engine.
  - Safe to remove: No.
  - Migration needed: Delete `CoachValidator` only after legacy decision paths
    are retired.
  - Suggested replacement: Boundary validators remain; missing-data checks move
    to knowledge runtime.
  - Risk level: Medium.

### Duplicate Strategy And Decision

- Location: `lib/ai/coach/coach_decision.dart`,
  `lib/ai/planner/coach_response_plan.dart`,
  `lib/ai/strategy/coach_strategy.dart`
  - Reason: decision, plan, and strategy all carry action, confidence, AI/local
    routing, notes, and next-step metadata.
  - Current consumers: pipeline decision, strategy, prompt planning, execution
    preview, integration result.
  - Safe to remove: No.
  - Migration needed: Define a stable public boundary before merging fields.
  - Suggested replacement: Keep `CoachDecision` as routing source,
    `CoachStrategy` as reasoning package, and `CoachResponsePlan` as executor
    contract until executor is replaced.
  - Risk level: Medium.

### Dead Infrastructure

- Location: `lib/ai/intent/rule_based_intent_resolver.dart`
  - Reason: adapter exists for future resolver injection, while current
    `AIIntentDetector` still runs the legacy detector.
  - Current consumers: no runtime consumer found in `lib/ai/`.
  - Safe to remove: Not yet.
  - Migration needed: Either wire through `AIIntentDetector` behind a flag or
    delete after intent runtime strategy is finalized.
  - Suggested replacement: `IntentIntelligenceEngine` directly in intent stage.
  - Risk level: Low-to-medium.

- Location: `lib/ai/prompt/prompt_compressor.dart`
  - Reason: structural placeholder is superseded by
    `CoachPromptOptimizer` in Coach v2 pipeline.
  - Current consumers: legacy `PromptBuilder.build()`.
  - Safe to remove: No.
  - Migration needed: Remove legacy `PromptBuilder.build()` first.
  - Suggested replacement: `CoachPromptOptimizer`.
  - Risk level: Medium.

## Temporary Bridges

- Location: `CoachContext.toPromptContext()`
  - Use status: Used by `PromptBuilder.buildFromCoachContext()`.
  - Legacy only: Yes; v2 pipeline prompt path uses `CoachPromptPlan`.
  - Can remove now: No.
  - Replaced by: `CoachPromptPlanner` and `PromptBuilder.buildFromPlan()`.
  - Risk level: Medium.

- Location: `CoachLegacyDecisionAdapter`
  - Use status: Used only by `CoachLegacyIntegrationService` (flag-off compat).
  - Legacy only: Yes.
  - Can remove now: No — delete with `CoachLegacyIntegrationService` in EPIC 17.
  - Replaced by: `CoachBrain` + `CoachKnowledgeResult` via `CoachPipeline`.
  - Risk level: Low (isolated).

- Location: `PromptContext` and `PromptContextPatch`
  - Use status: Used by context providers, `AIContextBuilder`,
    `CoachContextAssembler`, and legacy prompt builder entry points.
  - Legacy only: Mostly; still part of context assembly.
  - Can remove now: No.
  - Replaced by: `CoachContext` plus future typed context patches.
  - Risk level: High.

- Location: `KnowledgeGraph` fallback in `PromptBuilder`
  - Use status: Used by legacy `PromptBuilder.build()` and
    `buildFromCoachContext()` when no node is supplied.
  - Legacy only: Yes for pipeline; not for all callers.
  - Can remove now: No.
  - Replaced by: `CoachKnowledgeRuntime`.
  - Risk level: Medium.

- Location: `CoachIntegrationService.previewMessage()`
  - Use status: Runs `CoachPipeline` in `CoachPipelineMode.preview` (EPIC 15).
  - Legacy only: No.
  - Can remove now: N/A — canonical preview entry point.
  - Replaced by: N/A (migration complete).
  - Risk level: Low.

- Location: `CurrentSubscriptionAdapter`
  - Use status: Default provider for `CoachEntitlementRuntime`.
  - Legacy only: Temporary adapter, not legacy runtime.
  - Can remove now: No.
  - Replaced by: approved side-effect-free subscription snapshot provider.
  - Risk level: Medium.

- Location: `CoachContextStateBridge`
  - Use status: Used by context stage to apply `collectedFields`.
  - Legacy only: No; active v2 bridge.
  - Can remove now: No.
  - Replaced by: native `CoachContextAssembler` support for collected fields.
  - Risk level: Medium.

## Pipeline Audit

- Stage dependency direction: One-way through `CoachPipelineContext`.
- Direct registry reads by stages: None found. Knowledge registry access is
  isolated behind `CoachKnowledgeRuntime`; prompt fallback stays inside
  legacy `PromptBuilder`.
- Direct subscription/payment reads by stages: None found. Entitlement checks go
  through `CoachEntitlementRuntime`.
- Pipeline bypasses: `AIChatService` uses `CoachIntegrationService` only when
  `CoachV2Config.coachV2Enabled` is true; flag-off chat keeps legacy
  `OpenAIService` path. Preview uses the same pipeline stages in dry-run mode.
- Service-to-stage calls: No service calls a later stage directly. The
  integration service constructs and runs the pipeline only through
  `CoachPipelineBuilder`/`CoachPipeline`.
- Dependency issues: No module cycle identified in the Coach v2 runtime path.
  Legacy context/prompt modules still have compatibility dependencies through
  `PromptContext` and intent definitions.
- Intent stage wiring (EPIC 14.5 audit): `_IntentStageRunner` runs both
  `IntentIntelligenceEngine` and `AIIntentDetector`, but only stores
  `intentIntelligence`; all downstream stages read `intentDetection`. The
  factory wires `AIIntentDetector` with no resolvers, so detection always
  falls back to `AIIntent.generalChat`. Fix in a dedicated PR (register
  `RuleBasedIntentDetectionResolver` or map `intentIntelligence` into
  `intentDetection`); not changed in the doc-only 14.5 pass.

## Dependency Graph

```text
AIChatService
  -> CoachIntegrationService (flag on)
  -> OpenAIService (flag off legacy)

CoachIntegrationService
  -> CoachPipelineBuilder (flag on)
  -> CoachLegacyIntegrationService (flag off compat only)

CoachLegacyIntegrationService
  -> CoachLegacyDecisionAdapter (flag off only)

CoachPipeline
  -> entity
  -> intent
  -> state
  -> memory
  -> context
  -> knowledge runtime
  -> skills runtime
  -> entitlement runtime
  -> coach brain
  -> strategy
  -> prompt planner
  -> prompt builder
  -> executor preview

knowledge runtime
  -> KnowledgeGraph / KnowledgeRegistry

entitlement runtime
  -> EntitlementEngine
  -> CoachEntitlementProvider

prompt planner
  -> CoachContext
  -> CoachKnowledgeResult
  -> CoachStrategyResult

legacy prompt builder
  -> PromptContext
  -> KnowledgeGraph fallback
```

## Future Removal Candidates

- Remove `CoachLegacyIntegrationService` and `CoachLegacyDecisionAdapter` after
  flag-off compat callers are retired.
- Remove `AIIntentDefinitions` after provider selection can be derived from
  `KnowledgeNode` or retired from legacy preview.
- Remove `PromptContext`, `PromptContextPatch`, and
  `CoachContext.toPromptContext()` after context providers assemble
  `CoachContext` directly.
- Remove legacy `PromptBuilder.build()` / `buildFromCoachContext()` after all
  prompt package callers use `CoachPromptPlan`.
- Remove `PromptCompressor` after legacy prompt builder entry points are gone.
- Replace `CurrentSubscriptionAdapter` with a side-effect-free subscription
  snapshot source.
- Move `CoachContextStateBridge` logic into `CoachContextAssembler` once state
  collected fields are a first-class context input.

## Future TODO

- Keep broad context providers available until all dry-run consumers migrate to
  granular providers.
- Keep `KnowledgeRegistry` and `AIIntentDefinitions` synchronized only for
  legacy preview/flag-off paths until they are retired.
- Make active-program reads user-id scoped instead of relying on current auth
  user only.
- Persist questionnaire answers into profile consistently so equipment and
  injury fields do not depend on local-only fallbacks.
- Replace the temporary metadata/current-subscription adapter with an approved
  read-only subscription snapshot source when payment reads are side-effect free.
- Add `MemoryContextProvider` and a clear memory retention policy.
- Decide whether long-term memory should remain local-first or sync through a
  backend table after privacy review.
- Define a product-approved memory namespace catalog before enabling write
  paths in runtime.
- Add `NutritionContextProvider` only after nutrition data has a stable source
  of truth.
- Add `CoachResponsePlan` serialization if plans need to be inspected in tests
  or developer tools.
- Add a future prompt renderer only after existing prompt behavior has a
  feature-flagged migration path. (`PromptPackageRenderer` now covers chat v2.)
- Keep all future runtime integration behind a feature flag until Coach v2 is
  validated with tests.

---

## EPIC 19 — Intelligent Workout Generator V1

### Scope

Rule-based, **offline** workout program generation. No new pipeline stages,
context models, or bridges. Consumes existing Coach artifacts:

`CoachContext`, Memory, State, Knowledge, Skill, Intent, Entity, Entitlement.

OpenAI is **not** used to build programs — only for future explanation/motivation
text. Output is fully typed (`WorkoutProgram` → `WorkoutWeek` → `WorkoutDay` →
`WorkoutExercise` → `WorkoutSet` + `WorkoutProgression` + `WorkoutNote`).

### Module layout (`lib/ai/workout/`)

| Path | Role |
|------|------|
| `models/` | DB-ready typed domain models + `WorkoutGeneratorInput/Result` |
| `planner/` | `WorkoutSplitPlanner` — weekly split from goal, knowledge, recovery |
| `exercise_selector/` | `WorkoutExerciseSelector` — goal/equipment/restriction/heatmap scoring |
| `progression/` | `WorkoutProgressionEngine` — sets + overload strategies |
| `validator/` | `WorkoutProgramValidator` — pre-output safety checks |
| `generator/` | `CoachWorkoutGenerator` — orchestrator |
| `runtime/` | `WorkoutContextExtractor`, `CoachWorkoutGeneratorRuntime`, `WorkoutGenerationSkill` |

### Generator Flow

```
CoachContext + Knowledge + Entitlement + State + Memory
  → WorkoutContextExtractor.extract()
  → WorkoutGeneratorInput
  → CoachWorkoutGenerator.generate(catalog)
      1. entitlement / missing-field gates → needsFollowUp (no partial program)
      2. WorkoutSplitPlanner.plan() → WorkoutDayPlan[]
      3. per day: WorkoutExerciseSelector.selectForDay()
      4. per exercise: WorkoutProgressionEngine.buildSets()
      5. assemble WorkoutProgram (UUID ids, version, status, JSON)
      6. WorkoutProgramValidator.validate()
  → WorkoutGeneratorResult (success | needsFollowUp | entitlementBlocked | validationFailed)
```

Entry points:

- **Tests / direct**: `CoachWorkoutGenerator` or `CoachWorkoutGeneratorRuntime`
- **Skill**: `WorkoutGenerationSkill` (inject `InMemoryWorkoutExerciseCatalog` or
  production catalog adapter). Not in `CoachSkillRegistry.defaultSkills` until
  catalog injection is wired from `AIExerciseReadService`.

### Selection Flow

For each `WorkoutDayPlan`:

1. Filter catalog: avoid list (memory/preferences), equipment, restrictions,
   experience difficulty, muscle bucket match.
2. Score: goal alignment, compound priority, heatmap low-frequency boost,
   recovery penalty on compounds when `recoveryScore < 0.5`.
3. Pick top N per day with bucket de-duplication.
4. Attach `WorkoutGeneratorReason` per candidate (`subject` + `because[]`).

Progression (`WorkoutProgressionEngine`):

- Strategies: `increaseWeight`, `increaseReps`, `increaseVolume`, `deload`,
  `maintenance` — chosen from goal + experience + recovery.

### Validation Flow

`WorkoutProgramValidator` before returning success:

- Non-empty weeks/days/exercises
- No duplicate exercises across program or within a day
- Beginner volume cap / advanced minimum volume
- Low recovery → leg volume cap
- Avoid-list enforcement (memory: e.g. user hates squat)

### Explainability

Every split day, exercise candidate, and program-level decision carries
`WorkoutGeneratorReason` (`code`, `subject`, `because[]`). Examples:

- `split.selected` — Goal, DaysPerWeek, Knowledge node, Recovery=Low
- `exercise.candidate` — Goal, Equipment, Experience, Muscle, Compound priority

Skill layer maps reasons to `SkillReason` for Coach skill responses.

### Knowledge & Memory

- **Knowledge**: `knowledgeNodeId` / description influence split priority buckets
  via `WorkoutSplitPlanner`.
- **Memory**: `WorkoutContextExtractor` builds `avoidExerciseNames` from dislike/
  avoid/hate keys and squat-specific memory.
- **State**: collected fields (days, experience) merged in extractor; incomplete
  profile → `WorkoutGeneratorResult.needsFollowUp` (never partial program).

### Tests

`test/ai/workout/coach_workout_generator_test.dart` — 11 scenarios:

beginner / intermediate / advanced, muscle gain, fat loss, home, gym, injury,
low recovery, missing data, entitlement blocked, skill payload, JSON persistence.

Fixture catalog: `test/ai/workout/fixtures/workout_exercise_catalog_fixture.dart`.

### Remaining TODO (EPIC 19+)

- Register `WorkoutGenerationSkill` in pipeline with `AIExerciseReadService`
  catalog adapter (Supabase `ai_exercises`).
- Mapper from typed `lib/ai/workout/models/workout_program.dart` → legacy
  `workout_plan_builder` model for `WorkoutProgramService.createProgram()`.
- Wire generator into skill executor for `AIIntent.workoutGeneration` when
  entitlement allows (replace AI-only path for program structure).
- Reuse `CoachWorkoutGenerator` from `WorkoutTodaySkill` for day-level
  suggestions without duplicating selection logic.
- LLM explanation layer: narrate `WorkoutGeneratorReason` list (motivation only).
- UI: drag-and-drop editor bound to typed models (ids stable for sync/versioning).
- Validator: equipment presence vs user list, medical condition rule expansion.
- Multi-week periodization and active-program merge (progression from history).

---

## EPIC 20 — Workout Blueprint Engine (Task 1)

### Scope

High-level **planning layer** before `CoachWorkoutGenerator`. The generator no
longer makes split/frequency/volume/intensity decisions — it only executes a
pre-built `WorkoutBlueprint`.

Not wired to `CoachPipeline` yet. Prepared path:

```
CoachContext
  → WorkoutBlueprintBuilder (+ Knowledge, Strategy, Entitlement snapshot)
  → WorkoutBlueprint (+ WorkoutBlueprintValidator)
  → CoachWorkoutGenerator
```

Orchestrated by `WorkoutGenerationPipelinePath` (runtime adapter only).

### Module layout (`lib/ai/workout/blueprint/`)

| File | Role |
|------|------|
| `workout_blueprint.dart` | Immutable data model + `WorkoutBlueprintResult` |
| `workout_blueprint_builder.dart` | All planning decisions |
| `workout_blueprint_validator.dart` | Completeness validation |
| `workout_split_strategy.dart` | Split enum (upperLower, PPL, fullBody, …) |
| `workout_frequency_strategy.dart` | 2–6 days/week |
| `workout_volume_strategy.dart` | low / medium / high / veryHigh |
| `workout_intensity_strategy.dart` | light / moderate / hard / maximum |
| `workout_periodization_type.dart` | linear / undulating / block / maintenance / deload |
| `workout_recovery_strategy.dart` | normal / conservative / aggressive |
| `workout_blueprint_reason.dart` | Explainability per decision |
| `workout_blueprint_trace.dart` | Build trace (steps, recoveryScore, knowledge) |

### Planning vs execution

| Concern | Owner |
|---------|--------|
| Goal, experience, equipment, limitations | `WorkoutBlueprintBuilder` |
| Split / frequency / volume / intensity / periodization / recovery | `WorkoutBlueprintBuilder` |
| Entitlement + follow-up gates | `WorkoutBlueprintBuilder` |
| Split → day muscle buckets | `WorkoutSplitPlanner.planFromBlueprint()` (mapping only) |
| Exercise selection, sets, program assembly | `CoachWorkoutGenerator` |

### Tests

`test/ai/workout/blueprint/workout_blueprint_builder_test.dart` — 11 scenarios.

Generator tests now build blueprints first via `WorkoutBlueprintBuilder`.

---

## EPIC 20.5 — Blueprint Finalization & Generator Decoupling

### Scope

Finalize the workout planning architecture before Exercise Intelligence. No UI,
prompt, OpenAI, navigation, or existing business-logic paths changed. All work
remains behind `CoachV2Config.coachV2Enabled`.

### Task 1 — Remove `WorkoutGeneratorInput`

| Item | Consumer | Action |
|------|----------|--------|
| `WorkoutGeneratorInput` | None | **Removed** |
| `WorkoutContextExtractor` | None | **Removed** |
| `WorkoutFollowUpField` | `WorkoutGeneratorResult`, `WorkoutGenerationPipelinePath` | **Kept** (`lib/ai/workout/models/workout_follow_up_field.dart`) |
| `WorkoutGenerationRequest` | None | **Not created** (no consumers remained) |

Planning getters (`trainingGoal`, `isBeginner`, `isHomeGym`,
`missingRequiredFields()`) are gone. All decisions live in
`WorkoutBlueprintBuilder`.

### Task 2 — Blueprint completeness (single source of truth)

`WorkoutBlueprint` now owns executor-facing planning fields:

| Field | Role |
|-------|------|
| `weeklySetsTarget` | Total weekly set budget (replaces `estimatedWeeklyVolume`) |
| `maxSessionMinutes` | Session cap (replaces `estimatedSessionDuration`) |
| `minRecoveryHours` | Minimum rest between sessions |
| `preferredExerciseComplexity` | `basic` / `moderate` / `advanced` |
| `exerciseReplacementPolicy` | `substitute` / `skip` / `fail` |
| `deloadFrequencyWeeks` | Deload cadence |
| `progressionStrategy` | `WorkoutProgressionStrategy` from models |
| `trainingStyle` | `strength` / `hypertrophy` / `fatLoss` / `general` |
| `exercisesPerSession` | Computed in builder for split planner |

New enums: `workout_exercise_complexity.dart`,
`workout_exercise_replacement_policy.dart`, `workout_training_style.dart`.

`fromJson` still accepts legacy keys `estimatedWeeklyVolume` /
`estimatedSessionDuration` for migration only.

### Task 3 — Explainability

`WorkoutBlueprintTrace` extended with `decisions[]` and `memorySignals[]`.
`WorkoutBlueprintDecisionStep` records decision chains (split, frequency,
volume, intensity, progression) with factor lists: Goal, Experience, Recovery,
Knowledge, Memory — not only outcomes.

### Task 4 — Versioning

`workout_blueprint_versions.dart` defines:

- `schemaVersion` (`1.1`)
- `builderVersion`
- `createdBy`
- `planningEngineVersion`

Defaults applied on `WorkoutBlueprint` construction and `fromJson`.

### Task 5 — Immutable audit

All blueprint models are `const`-friendly with `final` fields only (no setters):

- `WorkoutBlueprint`, `WorkoutBlueprintResult`
- `WorkoutBlueprintReason`, `WorkoutBlueprintTrace`, `WorkoutBlueprintDecisionStep`

Each exposes `copyWith` for safe updates.

### Task 6 — Generator runtime audit

`WorkoutBlueprintFidelityValidator` runs before generation. Conflicts return
`WorkoutGeneratorStatus.blueprintInvalid` — the generator does **not** override
goal, split, intensity, frequency, or recovery.

| Removed from generator / executor | Now blueprint-only |
|--------------------------------|--------------------|
| Goal-based `_strategyFor()` in progression | `blueprint.progressionStrategy` |
| `WorkoutScience.setCountForExercise()` in progression | `weeklySetsTarget` formula |
| Internal volume/session guessing in split planner | `blueprint.exercisesPerSession` |
| Context extraction / input shaping | `WorkoutBlueprintBuilder` |

Generator still **reads** blueprint fields for labels, reps, and rest guidance
(execution metadata, not replanning).

### Task 7 — Tests

`test/ai/workout/blueprint/workout_blueprint_finalization_test.dart` — 9 scenarios:

- Blueprint versioning
- Immutability via `copyWith`
- Trace decision chains
- Generator cannot override invalid blueprint
- Missing / invalid blueprint fields
- Recovery, frequency, and split conflicts

### New files (EPIC 20.5)

| File | Role |
|------|------|
| `models/workout_follow_up_field.dart` | Follow-up enum extracted from removed input |
| `blueprint/workout_blueprint_versions.dart` | Schema / builder versioning |
| `blueprint/workout_blueprint_decision_step.dart` | Decision-chain trace step |
| `blueprint/workout_blueprint_fidelity_validator.dart` | Pre-generation fidelity gate |
| `blueprint/workout_exercise_complexity.dart` | Complexity enum |
| `blueprint/workout_exercise_replacement_policy.dart` | Replacement policy enum |
| `blueprint/workout_training_style.dart` | Training style enum |
| `test/.../workout_blueprint_finalization_test.dart` | EPIC 20.5 test suite |

### Deleted files (EPIC 20.5)

- `lib/ai/workout/models/workout_generator_input.dart`
- `lib/ai/workout/runtime/workout_context_extractor.dart`

### Remove candidates (technical debt)

| Item | Notes |
|------|-------|
| `WorkoutScience.setCountForExercise()` | Still used by legacy `rule_based_workout_program_engine.dart`; removed from Coach V2 progression |
| `WorkoutScience.bucketsPerDay()` etc. | Kept for split → bucket **mapping** only |
| Legacy JSON keys `estimatedWeeklyVolume` / `estimatedSessionDuration` | Migration compat in `fromJson`; remove after persisted blueprint migration |
| `WorkoutGenerationPipelinePath` wiring to `CoachPipeline` | Prepared but not connected (EPIC 21+) |

### Verification

- `flutter test test/ai/workout` — **31 passed**
- `flutter analyze lib/ai/workout` — **No issues found**

---

## EPIC 21 — Exercise Intelligence Engine (Phase 1)

### Scope

Standalone **exercise intelligence layer** that enriches catalog exercises with
scoring, compatibility, safety, fatigue, and replacement logic. Prepared for
future integration — **not wired** to `CoachWorkoutGenerator`,
`WorkoutExerciseSelector`, or `CoachPipeline`.

All entry points gate on `CoachV2Config.coachV2Enabled`. No UI, prompt,
OpenAI, navigation, or existing runtime paths changed.

### Architecture

```
ExerciseProfile (+ ExerciseProfileMapper from catalog Exercise)
  → ExerciseIntelligenceQuery (standalone context)
  → ExerciseIntelligenceRuntime (orchestrator only)
      → ExerciseScoringEngine
      → ExerciseCompatibilityEngine
      → ExerciseSafetyEngine
      → ExerciseFatigueEngine
      → ExerciseReplacementEngine
  → ExerciseIntelligenceEvaluation (+ reasons)
```

### Module layout (`lib/ai/exercise/`)

| Folder | Role |
|--------|------|
| `models/` | `ExerciseProfile`, enums, query, mapper, versions, reasons |
| `scoring/` | `ExerciseScoringEngine` — goal/equipment/muscle fit |
| `compatibility/` | `ExerciseCompatibilityEngine` — session constraints |
| `safety/` | `ExerciseSafetyEngine` — injury / joint load screening |
| `fatigue/` | `ExerciseFatigueEngine` — recovery budget assessment |
| `replacement/` | `ExerciseReplacementEngine` — safer alternatives |
| `intelligence/` | `ExerciseIntelligenceEvaluation` — combined result |
| `runtime/` | `ExerciseIntelligenceRuntime` — orchestrator only |

### ExerciseProfile fields

Immutable catalog intelligence record with: `id`, `slug`, `canonicalName`,
`aliases`, `primaryMuscles`, `secondaryMuscles`, `movementPattern`,
`movementType`, `equipment`, `difficulty`, `fatigueScore`, `stimulusScore`,
`injuryRisk`, `stabilityRequirement`, `executionComplexity`, `recoveryCost`,
`preferredGoals`, `experienceLevel`, `jointStress`, per-joint loads
(`spineLoad`, `shoulderLoad`, `kneeLoad`, `hipLoad`, `elbowLoad`, `wristLoad`),
`gripType`, `unilateral`, `compound`, `isolation`, `warmupRecommended`,
`defaultTempo`, `notes`, `version`.

`ExerciseProfileMapper` derives profiles from `Exercise` + `ExerciseRichMeta`
(heuristic Phase 1; full `ai_exercises` meta consumption in Phase 2).

### Explainability

`ExerciseIntelligenceReason` — `code` + `subject` + `because[]`.

Reason codes include: `goal.match`, `equipment.match`, `safety.injury_safe`,
`fatigue.too_high`, `fatigue.recovery_friendly`, `replacement.better`,
`compatibility.pass`, `runtime.disabled`.

### Services (no WorkoutGenerator dependency)

| Service | Responsibility |
|---------|----------------|
| `ExerciseScoringEngine` | Rank fit for goal, equipment, muscles, experience |
| `ExerciseCompatibilityEngine` | Equipment, experience, muscle, avoid-list gates |
| `ExerciseSafetyEngine` | Limitation vs joint-load and injury risk |
| `ExerciseFatigueEngine` | Fatigue budget vs recovery score |
| `ExerciseReplacementEngine` | Same-pattern/muscle safer alternatives |
| `ExerciseIntelligenceRuntime` | Orchestrates all engines; rank + replace APIs |

### Integration status

**Prepared only.** No changes to:

- `CoachWorkoutGenerator`
- `WorkoutExerciseSelector`
- `CoachPipeline` / `WorkoutGenerationPipelinePath`
- `AIExerciseReadService` production wiring

Future EPIC: replace selector heuristics with `ExerciseIntelligenceRuntime.rankCatalog()`.

### Remove candidates (audit — nothing deleted in Phase 1)

| Duplicated today | Migrate to Exercise Engine later |
|------------------|----------------------------------|
| `WorkoutScience.isCompoundExercise()` | `ExerciseProfile.compound` from catalog meta |
| `WorkoutExerciseSelector` equipment/restriction/experience filters | `ExerciseCompatibilityEngine` + `ExerciseSafetyEngine` |
| `WorkoutExerciseSelector` scoring heuristics | `ExerciseScoringEngine` |
| `AIExerciseReadService` partial mapper vs `ExerciseService` full mapper | Unified catalog adapter → `ExerciseProfileMapper` |
| Name-substring injury rules in selector | `ExerciseProfile` joint loads + `exercise_extended_json.safety` |
| `muscle_targets_json` unused by selector | Fatigue/stimulus scoring input |
| `RuleBasedWorkoutProgramEngine` | Deprecated when pipeline wired |

### Tests

`test/ai/exercise/exercise_intelligence_test.dart` — 13 scenarios:

- Immutable models + JSON round-trip
- Profile mapper
- Scoring, compatibility, safety, fatigue, replacement
- Explainability reason aggregation
- Runtime CoachV2 gate + engine version

### Verification

- `flutter test test/ai/exercise` — **13 passed**
- `flutter analyze lib/ai/exercise` — **No issues found**

---

## EPIC 22 — Exercise Intelligence Runtime Integration

### Scope

Wire `ExerciseIntelligenceRuntime` into `CoachWorkoutGenerator` via
`WorkoutExerciseSelector`. Generator remains orchestrator only — no selection
business logic. No UI, OpenAI, or `CoachPipeline` changes.

### Architecture

```
ExerciseCatalogAdapter (ListExerciseCatalogAdapter)
  → ExerciseProfile + Exercise
  → WorkoutExerciseIntelligenceQueryBuilder (blueprint → query)
  → WorkoutExerciseSelector
      → ExerciseIntelligenceRuntime.evaluate()
      → ExerciseIntelligenceRuntime.findReplacement() on reject
      → sort + bucket balance (orchestration only)
  → CoachWorkoutGenerator (assemble program + trace)
  → WorkoutExercise.selectionReasons (intelligence.* codes)
```

### Task 1 — Unified catalog adapter

`ExerciseCatalogAdapter` + `ListExerciseCatalogAdapter` in
`lib/ai/exercise/runtime/exercise_catalog_adapter.dart`.

Generator accepts `ExerciseCatalogAdapter` only (not raw `List<Exercise>`).
`WorkoutGenerationPipelinePath` wraps `WorkoutExerciseCatalog` via
`ListExerciseCatalogAdapter`.

Mappers **not merged**: `ExerciseProfileMapper`, `AIExerciseReadService`,
`ExerciseService` remain separate — adapter is the single generator entry.

### Task 2–6 — Selector migration

Removed from `WorkoutExerciseSelector`:

- Manual score calculation (`+0.35 compound`, recovery boost, etc.)
- `_matchesEquipment`, `_matchesRestrictions`, `_matchesExperience`
- `_isAvoidedByName` (now `avoidExerciseNames` in query)
- `_recoveryBoost` fatigue heuristics

Now uses:

| Engine | Role |
|--------|------|
| `ExerciseScoringEngine` | Rank fit |
| `ExerciseCompatibilityEngine` | Equipment / experience / avoid gates |
| `ExerciseSafetyEngine` | Injury + joint load |
| `ExerciseFatigueEngine` | Recovery budget from blueprint |
| `ExerciseReplacementEngine` | Substitute on reject |

### Task 7 — Selection trace

`WorkoutGeneratorSelectionTrace` on `WorkoutGeneratorResult`:

`catalogCount → filtered → rejected → replaced → selected → final`

### Explainability

`ExerciseIntelligenceReasonMapper` maps to `WorkoutGeneratorReason` with
`intelligence.*` prefix. Replacement adds `Chosen Instead Of <name>`.

### Audit table (removed vs kept)

| Item | Consumer | Action |
|------|----------|--------|
| Selector scoring heuristics | Was `WorkoutExerciseSelector` | **Removed** → `ExerciseScoringEngine` |
| Injury name-substring filters | Was selector | **Removed** → `ExerciseSafetyEngine` |
| Equipment string filters | Was selector | **Removed** → `ExerciseCompatibilityEngine` |
| Fatigue `_recoveryBoost` | Was selector | **Removed** → `ExerciseFatigueEngine` + query builder |
| `WorkoutScience.isCompoundExercise` in selector | Generator output | **Removed** → `ExerciseProfile.compound` |
| Muscle bucket day gate | Selector orchestration | **Kept** (day-plan mapping only) |
| Bucket balance pick | Selector orchestration | **Kept** (sort/pick only) |
| `ExerciseProfileMapper` | Adapter | **Kept** |
| `AIExerciseReadService` mapper | Legacy AI path | **Keep** — future adapter impl |
| `ExerciseService` mapper | UI catalog | **Keep** — Remove candidate |

### Tests

- `test/ai/workout/exercise_selector/workout_exercise_selector_integration_test.dart` — 9 scenarios
- Updated generator + finalization tests for `ExerciseCatalogAdapter`

### Verification

- `flutter test test/ai/workout test/ai/exercise` — **53 passed**
- `flutter analyze lib/ai/workout lib/ai/exercise` — **No issues found**

---

## EPIC 23 — Workout Review AI Engine (Phase 1)

### Scope

Analysis-only engine under `lib/ai/workout_review/`. Reviews existing
`WorkoutProgram` instances — **does not generate programs**. No UI, OpenAI,
Navigation, or `CoachPipeline` changes. Gated on `CoachV2Config.coachV2Enabled`.

### Architecture

```
WorkoutProgram + CoachContext + ExerciseProfile catalog + CoachKnowledgeResult?
  → WorkoutProgramAnalyzer (metrics: volume, joint stress, push/pull, equipment)
      → ExerciseIntelligenceRuntime.evaluate() per exercise (safety/compatibility)
  → WorkoutReviewScoringEngine (10 dimension scores 0–100)
  → WorkoutReviewIssueDetector (structural/load issues)
  → WorkoutReviewRecommendationBuilder (actions + reason chains)
  → WorkoutReviewTrace (exercise count → volume → issues → recommendations)
  → WorkoutReviewResult
```

`WorkoutReviewRuntime.review(program)` — prepared entry point, **not wired**
to `CoachPipeline`.

### Models (`lib/ai/workout_review/models/`)

| Model | Role |
|-------|------|
| `WorkoutReviewRequest` | Program + context + catalog profiles + optional knowledge |
| `WorkoutReviewResult` | Scores, issues, recommendations, trace, summary |
| `WorkoutReviewScore` | 10 dimension scores + overall (0–100) |
| `WorkoutReviewIssue` | Detected problem with severity + reason chain |
| `WorkoutReviewRecommendation` | Actionable fix with explainability |
| `WorkoutReviewReason` | `code` + `subject` + `because[]` |
| `WorkoutReviewTrace` | Full analysis audit trail |

All models: immutable, `copyWith`, `fromJson`/`toJson`.

### Scores (0–100)

| Score | Inputs |
|-------|--------|
| Volume | Weekly sets vs `WorkoutScience.weeklySetsForGoal` per major muscle |
| Recovery | Fatigue cost, leg-day frequency, knee stress |
| Balance | Push/pull ratio, chest/back ratio, compound ratio |
| Goal Alignment | Average reps vs goal-specific target |
| Safety | `ExerciseIntelligenceRuntime` safety ratio + joint stress |
| Progression | Progression metadata, deload presence |
| Equipment Compatibility | Equipment match + conflict penalty |
| Experience Match | Exercise difficulty vs experience level |
| Weekly Distribution | Set variance across training days |
| Muscle Coverage | Major buckets with ≥4 weekly sets |

### Issues detected

`chestOverloaded`, `noPosteriorChain`, `tooMuchKneeStress`, `recoveryTooLow`,
`tooManyCompoundExercises`, `missingDeload`, `weakShoulderBalance`,
`noPullingVolume`, `excessiveIsolation`, `equipmentConflict`,
`beginnerVolumeTooHigh`, `advancedVolumeTooLow`, `goalMismatch`, `emptyProgram`

### Recommendations + explainability

Each recommendation carries a `WorkoutReviewReason` chain, e.g.:

```
addFacePull → Rear delts undertrained → Shoulder Balance Low → Weekly pull volume = N
```

Recommendation codes: `reduceLegDayVolume`, `replaceSquatWithHackSquat`,
`addFacePull`, `addHamstringExercise`, `increaseRest`, `reduceChestVolume`,
`addBackExercise`, `addDeloadWeek`, `swapToHomeEquipment`, `reduceCompoundCount`,
`addIsolationBalance`, `lowerSessionIntensity`

### Audit table

| Candidate | Future |
|-----------|--------|
| `WorkoutProgramValidator` | **Merge** — overlap with `WorkoutReviewIssueDetector`; unify in Phase 2 |
| Heatmap Insight (`WeeklyMuscleHeatmapResult`) | **Reuse** — recovery input in analyzer |
| Exercise Intelligence | **Reuse** — safety/compatibility per exercise |
| Blueprint | **Reuse** — future: compare program vs blueprint targets |
| `WorkoutScience` helpers | **Remove candidate** — volume/rep heuristics partially duplicated by review scoring |

### Remove candidates (nothing deleted in Phase 1)

| Item | Notes |
|------|-------|
| `WorkoutProgramValidator` | Merge candidate with review issue detector |
| `WorkoutScience.setCountForExercise()` | Legacy rule-based engine only |
| `WorkoutScience.isCompoundExercise()` | Superseded by `ExerciseProfile.compound` in review path |
| `WorkoutGenerationPipelinePath` | Still not connected to `CoachPipeline` |

### Tests

`test/ai/workout_review/workout_review_test.dart` — 13 scenarios:

- Immutable models + JSON round-trip
- Balanced program
- Bad program
- High knee stress
- Chest dominant
- Missing back
- Equipment conflict
- Beginner volume
- Advanced volume
- Goal match / mismatch
- Explainability chains
- Runtime `review(program)`
- CoachV2 gate

### Verification

- `flutter test test/ai/workout_review` — **13 passed**
- `flutter analyze lib/ai/workout_review` — **No issues found**

---

## EPIC 24 — Workout Modify AI Engine (Phase 1)

### Scope

Modification-only engine under `lib/ai/workout_modify/`. Mutates existing
`WorkoutProgram` instances — **does not generate new programs**. No UI,
OpenAI, Navigation, or `CoachPipeline` changes. Gated on
`CoachV2Config.coachV2Enabled`.

### Architecture

```
WorkoutProgram + CoachContext + ModificationRequest + ExerciseProfile catalog
  → WorkoutProgramMutator (clone + exercise/day mutations)
  → WorkoutModifyRules (per-type handlers)
      → ExerciseReplacementEngine (all replaces — mandatory)
      → ExerciseSafetyEngine (all safety gates — mandatory)
  → WorkoutModifyValidator
  → WorkoutModifyImpactCalculator (before/after deltas)
  → WorkoutModificationTrace (requested → applied → skipped → rejected → final)
  → WorkoutModificationResult
```

`WorkoutModifyRuntime.modify(program, modifications)` — prepared entry point,
**not wired** to `CoachPipeline`.

### Models (`lib/ai/workout_modify/models/`)

| Model | Role |
|-------|------|
| `WorkoutModificationRequest` | Program + context + modification types + catalog |
| `WorkoutModificationResult` | Original + modified program, modifications, impact, trace |
| `WorkoutModification` | Single change (applied/skipped/rejected) with reason chain |
| `WorkoutModificationReason` | `code` + `subject` + `because[]` |
| `WorkoutModificationImpact` | Volume/Fatigue/Recovery/JointStress/GoalAlignment Δ |
| `WorkoutModificationTrace` | Requested → Applied → Skipped → Rejected → Final |

### Supported modifications

`replaceExercise`, `removeExercise`, `addExercise`, `reduceVolume`,
`increaseVolume`, `reduceIntensity`, `increaseIntensity`, `shortenSession`,
`homeVersion`, `gymVersion`, `injuryAdaptation`, `equipmentAdaptation`,
`recoveryAdaptation`

### Explainability

Each modification carries a reason chain, e.g.:

```
Bench Press → Replace → Machine Chest Press → Shoulder Pain → Joint Load Reduced
```

### Impact deltas

| Delta | Source |
|-------|--------|
| Volume Δ | Total set count before vs after |
| Fatigue Δ | Σ fatigueScore × sets |
| Recovery Δ | Σ recoveryCost × sets |
| Joint Stress Δ | Σ (knee + shoulder + spine) load × sets |
| Goal Alignment Δ | Avg reps vs goal-specific target |

### Audit table

| Candidate | Future |
|-----------|--------|
| `CoachWorkoutGenerator` | **Reuse** — modify engine consumes generator output; does not replace it |
| `ExerciseReplacementEngine` | **Reuse** — sole path for all exercise replacements |
| `ExerciseSafetyEngine` | **Reuse** — sole path for injury/safety gating |
| `WorkoutReviewEngine` | **Reuse** — future: review modified program before persist |
| `WorkoutProgramValidator` | **Merge** — overlap with `WorkoutModifyValidator` |
| `WorkoutProgramMutator` UI drag-drop | **Future** — shared mutation primitives for UI edits |

### Remove candidates (nothing deleted in Phase 1)

| Item | Notes |
|------|-------|
| Manual exercise swap in UI | Future: route through `WorkoutModifyEngine` |
| `WorkoutScience` volume heuristics | Partially duplicated by impact calculator |
| `WorkoutGenerationPipelinePath` | Still not connected to `CoachPipeline` |

### Tests

`test/ai/workout_modify/workout_modify_test.dart` — 13 scenarios:

- Immutable models + JSON round-trip
- Shoulder injury adaptation
- Knee injury adaptation
- Home conversion
- Gym conversion
- Session shortening
- Recovery adaptation
- Volume reduction
- Explicit replacement (ExerciseReplacementEngine)
- Explainability chains
- Trace (requested/applied/skipped/rejected/final)
- Runtime `modify(program)`
- CoachV2 gate

### Verification

- `flutter test test/ai/workout_modify` — **13 passed**
- `flutter analyze lib/ai/workout_modify` — **No issues found**

---

## EPIC 25 — Coach Experience v1

### Scope

Coach-only presentation feature under `lib/features/coach/`. Existing screens,
routes, OpenAI, prompts, pipelines, and engines remain unchanged. The page is
behind `CoachV2Config.coachV2Enabled`; tests can disable the gate explicitly.

### Folder structure

```
lib/features/coach/
├── presentation/
│   ├── screens/coach_home_screen.dart
│   ├── widgets/coach_fade_in.dart
│   ├── cards/coach_home_cards.dart
│   └── state/coach_home_state.dart
├── view_models/coach_home_view_model.dart
├── navigation/coach_home_route.dart
└── domain/
```

### Architecture

```
CoachHomeScreen
  → CoachHomeViewModel
  → CoachHomeState
  → Mock Data
  → later Pipeline
```

No Engine, OpenAI, prompt, query, or runtime is called from the UI or
ViewModel in Phase 1.

### Layout

Vertical scroll of independent cards with black/gold/white styling, large
radius, soft shadows, consistent padding, and fade-in animation:

- Greeting Card
- Today's Focus
- Recovery Card
- Coach Memory
- Quick Actions
- Recent Conversations
- Insights
- Explainability

### State

`CoachHomeState` contains:

- `greeting`
- `todayWorkout`
- `recovery`
- `memories`
- `insights`
- `quickActions`
- `recentConversations`
- `explainability`

### Navigation

`CoachHomeRoute.routeName = '/coach'` is registered in `RouteService`.
No previous route is removed.

### Technical debt

| Item | Future |
|------|--------|
| Mock `CoachHomeViewModel` | Replace with read-only Coach state provider |
| Quick actions `modify/review` | Wire to future feature routes, not engines directly |
| Golden tests | Add once baseline/golden infra exists |
| Coach bottom-nav placement | Future product decision; currently route-only |

### Remove candidates

| Candidate | Future |
|-----------|--------|
| Legacy AI hub entry | Keep until Coach route is production-ready |
| Dashboard workout cards | Potential reuse after Coach v1 stabilizes |
| Ad hoc coach summaries | Replace with `CoachHomeState` provider later |

### Tests

`test/features/coach/coach_home_screen_test.dart`:

- Widget renders mock state cards
- CoachV2 gate hides mock UI when disabled
- `CoachHomeRoute` is registered in `RouteService`

Golden tests were not added because no golden baseline/tooling exists in the
current test suite.

### Verification

- `flutter test test/features/coach` — **3 passed**
- `flutter analyze lib/features/coach` — **No issues found**

---

## EPIC 26 — Workout Today Experience v1

### Scope

Workout Today presentation feature under `lib/features/workout_today/`.
Phase 1 is **UI/UX + State only**. It does not call `CoachPipeline`,
`WorkoutGenerator`, OpenAI, prompts, runtimes, repositories, or engines. All
data is mock and isolated inside `WorkoutTodayViewModel`.

### Folder structure

```
lib/features/workout_today/
├── presentation/
│   ├── screens/workout_today_screen.dart
│   ├── widgets/
│   │   ├── workout_today_fade_in.dart
│   │   └── workout_today_skeleton.dart
│   └── cards/
│       ├── workout_today_base_card.dart
│       ├── workout_hero_card.dart
│       ├── start_workout_card.dart
│       ├── workout_summary_card.dart
│       ├── muscle_card.dart
│       ├── exercise_timeline_card.dart
│       ├── coach_notes_card.dart
│       └── quick_actions_card.dart
├── view_models/workout_today_view_model.dart
├── state/workout_today_state.dart
├── domain/workout_today_domain_model.dart
└── navigation/workout_today_route.dart
```

### Architecture

```
WorkoutTodayScreen
  → WorkoutTodayViewModel
  → WorkoutTodayState
  → Mock
  → Later Pipeline
```

Cards consume only models/state. No business logic is placed inside widgets.

### Layout

Vertical scroll with independent black/gold/white cards, large radius, soft
shadow, consistent padding, fade animation, and a bottom sticky start button:

- Hero Header: greeting, recovery, duration, exercise count
- Start Workout Card / Empty Card
- Workout Summary
- Mock Muscle Visualization
- Exercise Timeline (7 exercises)
- Coach Notes
- Explainability
- Quick Actions

### State

`WorkoutTodayState` supports:

- `loading`
- `loaded`
- `error`
- `empty`

`WorkoutTodayData` includes a complete mock 65-minute upper-body workout with
7 exercises, recovery, coach notes, reasons, and quick actions.

### Navigation

`WorkoutTodayRoute.routeName = '/workout-today'` is registered in
`RouteService`. No previous route is removed.

### Technical debt

| Item | Future |
|------|--------|
| Mock `WorkoutTodayViewModel` | Replace source with pipeline-backed state later |
| Start workout action | Wire to real workout session flow |
| Muscle visualization | Replace mock body painter with real heatmap/body map |
| Quick actions | Wire to future modify/review/replacement routes, not engines directly |
| Golden tests | Add after golden baseline/tooling exists |

### Remove candidates

| Candidate | Future |
|-----------|--------|
| Ad hoc today workout widgets | Consolidate into Workout Today cards |
| Dashboard workout shortcut | Route to `/workout-today` after product rollout |
| Mock muscle painter | Replace with real Heatmap integration |

### Tests

`test/features/workout_today/workout_today_screen_test.dart`:

- State helper test
- Loaded widget test
- Loading skeleton test
- Empty state test
- Error state test
- Navigation route registration test

### Verification

- `flutter test test/features/workout_today` — **6 passed**
- `flutter analyze lib/features/workout_today` — **No issues found**

---

## EPIC 27 — Coach Runtime Integration (Vertical Slice 1)

### Scope

Coach Home and Workout Today now read from Coach Pipeline Preview through
feature-level Facades. No UI widget imports or calls `CoachPipeline`,
`CoachIntegrationService`, Coach runtime, workout generator, OpenAI, prompts,
repositories, or engines directly.

This slice is read-only:

- Uses `CoachIntegrationService.previewMessage(...)`
- Preview sets `CoachPipelineMode.preview`
- `CoachPipelineMode.preview` activates v2 stages without requiring
  `CoachV2Config.coachV2Enabled`
- State/memory stages receive `dryRun: true`
- `CoachExecutor.preview(...)` returns `wouldExecute: false`
- No persist, memory write, state write, session creation, or OpenAI execution
  is introduced by the feature layer

### New application facades

```
lib/features/coach/application/
├── coach_facade.dart
└── coach_facade_result.dart

lib/features/workout_today/application/
├── workout_today_facade.dart
└── workout_today_facade_result.dart
```

### Dependency diagram

```
CoachHomeScreen
  → CoachHomeViewModel
  → CoachFacade
  → CoachIntegrationService.previewMessage
  → CoachPipeline(mode: preview)
  → CoachIntegrationResult
  → CoachHomeState

WorkoutTodayScreen
  → WorkoutTodayViewModel
  → WorkoutTodayFacade
  → CoachIntegrationService.previewMessage
  → CoachPipeline(mode: preview)
  → CoachIntegrationResult / skill structuredData
  → WorkoutTodayState
```

### Sequence diagram

```
Screen.initState
  → ViewModel.load()
  → state = loading
  → Facade.load()
  → previewMessage(userMessage, metadata: { mode: preview })
  → CoachPipeline.run(CoachPipelineContext(mode: preview))
  → CoachIntegrationResult
  → Facade.map(...)
  → state = loaded | empty | error
```

### State diagram

```
loading
  → loaded  (preview result mapped)
  → empty   (Workout Today has no active/today workout)
  → error   (preview throws or mapping fails)
```

Coach Home supports `loading`, `loaded`, `error`.
Workout Today supports `loading`, `loaded`, `empty`, `error`.

### Gap analysis

| Data | Preview source today | Status | Gap handling |
|------|----------------------|--------|--------------|
| CoachContext | `CoachIntegrationResult.coachContext` | Available | Mapped by `CoachFacade` |
| Recovery/Fatigue/Sleep/Readiness | `CoachContext.profile` keys if providers expose them | Partial | Missing values recorded in `CoachFacadeResult.gaps` |
| Today Workout | `CoachContext.activeProgram` | Partial | Missing active program recorded as gap / `todayWorkout = null` |
| Coach Memory | `CoachContext.memories` | Partial | Empty memory recorded as gap |
| Heatmap/Insights | `CoachContext.weeklyHeatmap` + response notes | Partial | Missing insights recorded as gap |
| Explainability | decision notes, response plan notes, logs, skill explanations | Available/partial | Empty explanations recorded as gap |
| WorkoutGenerationSkill payload | `skillExecutionResult.response.structuredData['workoutProgram']` | Gap in default preview path | `WorkoutTodayFacade` records gap and falls back to activeProgram preview payload |
| Workout Today timeline | active program `exercises` / `todayExercises` | Partial | Missing timeline recorded as gap; no UI shortcut |

### Files changed

| File | Change |
|------|--------|
| `CoachHomeViewModel` | Removed mock data; now loads through `CoachFacade` |
| `WorkoutTodayViewModel` | Removed mock data; now loads through `WorkoutTodayFacade` |
| `CoachHomeScreen` | Added loading/error state rendering and lazy load |
| `WorkoutTodayScreen` | Loads through ViewModel on init |
| `RouteService` | Existing EPIC 25/26 routes unchanged |

### Audit

| Question | Result |
|----------|--------|
| Mock data removed from ViewModels? | Yes |
| ViewModel only knows Facade? | Yes |
| Facade only invokes preview + maps result? | Yes |
| UI imports runtime/pipeline/engine? | No |
| Preview write operations introduced by feature? | No |
| Direct Engine access from UI? | No |

### Technical debt

| Item | Future |
|------|--------|
| Recovery provider shape | Normalize recovery/readiness fields in `CoachContext` |
| Today workout activeProgram schema | Introduce typed read-only active workout context |
| WorkoutGenerationSkill in preview | Decide whether Workout Today should use activeProgram skill or generation skill |
| Screenshot automation | Add integration/golden harness before storing screenshots |

### Remove candidates

| Candidate | Future |
|-----------|--------|
| Facade gap fallbacks to generic activeProgram map | Replace with typed preview contracts |
| UI-only quick action routes | Replace with real feature routes once available |
| Mock-focused EPIC 25/26 docs | Superseded by EPIC 27 runtime-read slice |

### Tests

- `test/features/coach/coach_facade_test.dart`
- `test/features/coach/coach_home_screen_test.dart`
- `test/features/workout_today/workout_today_facade_test.dart`
- `test/features/workout_today/workout_today_screen_test.dart`

Coverage includes facade mapping, ViewModel loading, ViewModel error,
widget loaded state, loading, error, empty, and route registration.

### Verification

- `flutter test test/features/coach test/features/workout_today` — **16 passed**
- `flutter analyze lib/features/coach lib/features/workout_today test/features/coach test/features/workout_today` — **No issues found**

---

## EPIC 28 — Live Workout Session Experience (Phase 1)

### Scope

`lib/features/live_workout/` introduces the first read-only workout session UI.
This phase does **not** create engines, pipeline stages, generator logic,
exercise intelligence, prompts, OpenAI calls, memory/state writes, or repository
updates.

The feature consumes Coach Pipeline Preview through `LiveWorkoutFacade`:

```
LiveWorkoutScreen
  → LiveWorkoutViewModel
  → LiveWorkoutFacade
  → CoachIntegrationService.previewMessage(...)
  → CoachPipeline(mode: preview)
  → LiveWorkoutState
```

### Folder structure

```
lib/features/live_workout/
├── application/
│   ├── live_workout_facade.dart
│   └── live_workout_facade_result.dart
├── domain/live_workout_domain_model.dart
├── state/live_workout_state.dart
├── view_models/live_workout_view_model.dart
├── navigation/live_workout_route.dart
└── presentation/
    ├── screens/live_workout_screen.dart
    ├── widgets/live_workout_fade_slide.dart
    ├── cards/live_workout_cards.dart
    └── dialogs/
```

### Layout

Vertical black/gold/white session screen with large-radius cards, soft shadow,
uniform padding, fade/slide animation, and a bottom sticky action button:

- Hero: Workout Today, focus, estimated minutes, exercise count, set count
- Progress Card: current exercise, completed sets, progress bar
- Current Exercise: exercise name, set/reps target, target weight
- Set Tracker: weight/reps/done rows for all sets
- Rest Timer Card: mock `90 sec` timer, no timer logic
- Coach Tips: preview notes or `No coach tips`
- Explainability: preview reasons/trace-derived text when available
- Bottom Sticky Button: `Complete Set`, `Next Exercise`, `Finish Workout`

### State diagram

```
loading
  → loaded
  → empty
  → error

loaded
  → sessionCompleted
```

`LiveWorkoutViewModel` only changes local in-memory UI state for done sets and
current exercise. It does not persist a workout session.

### Sequence diagram

```
WorkoutToday Start Workout
  → Navigator.pushNamed('/live-workout')
  → LiveWorkoutScreen.initState
  → LiveWorkoutViewModel.load()
  → LiveWorkoutFacade.load()
  → CoachPreviewSeedLoader.load(intent: workoutToday)
  → CoachIntegrationService.previewMessage(
       userMessage: 'تمرین امروزم رو شروع کن',
       mode: preview,
       seedCoachContext: context,
     )
  → map activeProgram / skill structuredData / notes / reasons
  → LiveWorkoutState.loaded | empty | error
```

### Data mapping

| UI field | Preview source | Fallback |
|----------|----------------|----------|
| Workout title/focus | `workoutProgram`, `skillData['program']`, `coachContext.activeProgram` | `Workout Today` |
| Exercises/sets | `WorkoutProgram.allDays.first.exercises` or active program maps | `empty` state |
| Coach tips | skill `nextActions`, warnings, response/decision notes | `No coach tips` |
| Explainability | skill explanation/reasons + integration logs | empty list |
| Rest timer | UI placeholder | `90 sec` |

### Navigation

`LiveWorkoutRoute.routeName = '/live-workout'` is registered in
`RouteService`. Workout Today's Start Workout button now opens this route.

### Technical debt

| Item | Future |
|------|--------|
| Mock timer | Replace with a real local timer service when runtime session work starts |
| In-memory set completion | Persist only in a future runtime/session integration |
| Active program map parsing | Replace with typed Today Workout contract |
| Coach tips density | Add dedicated preview mapper when pipeline exposes session tips |

### Remove candidates

| Candidate | Future |
|-----------|--------|
| Active program map fallbacks | Remove after typed active workout/session context exists |
| `No coach tips` placeholder | Remove after preview guarantees tips/notes |
| Session completed placeholder | Replace with real finish flow in future runtime integration |

### Future runtime integration

Future phases may add a write-capable session runtime, workout log persistence,
rest timer behavior, set history, and finish workout flow. Those are explicitly
outside EPIC 28.

### Acceptance criteria

- UI layer only: **yes**
- Facade only access to preview: **yes**
- Preview pipeline only: **yes**
- No mock when preview data exists: **yes**
- Placeholder when preview data is missing: **yes**
- Read-only: **yes**
- No engine/business logic/prompt/OpenAI changes: **yes**
- Widget/ViewModel/Facade/Navigation tests: **yes**

### Verification

- `flutter analyze lib/features/live_workout test/features/live_workout lib/features/workout_today/presentation/screens/workout_today_screen.dart` — **No issues found**
- `flutter test test/features/live_workout test/features/workout_today/workout_today_screen_test.dart` — **13 passed**

---

## EPIC 29 — Coach Chat Experience v2

### Scope

`lib/features/coach_chat/` introduces a product-focused Coach chat experience.
This EPIC is UI/UX + ViewModel + Facade only. It does not create engines or
change `CoachPipeline`, prompt building, workout generation, OpenAI, memory,
strategy, skills, entity/intent, knowledge, runtime, repositories, or current
navigation.

### Folder structure

```
lib/features/coach_chat/
├── application/coach_chat_facade.dart
├── domain/coach_chat_models.dart
├── navigation/coach_chat_route.dart
├── state/coach_chat_state.dart
├── view_models/coach_chat_view_model.dart
└── presentation/
    ├── screens/coach_chat_screen.dart
    ├── widgets/
    ├── cards/coach_chat_cards.dart
    ├── composer/coach_chat_composer.dart
    ├── messages/coach_chat_message_bubble.dart
    └── animations/coach_chat_animations.dart
```

### Dependency diagram

```
CoachChatScreen
  → CoachChatViewModel
  → CoachChatFacade
  → CoachIntegrationService.previewMessage()
  → CoachPipeline Preview
  → CoachIntegrationResult
  → CoachChatMessage / cards
  → UI
```

Presentation and ViewModel do not import pipeline, runtime, engines,
repositories, OpenAI, prompt, or business logic. `CoachChatFacade` is the only
feature layer that talks to `CoachIntegrationService.previewMessage()`.

### Sequence diagram

```
User sends message / taps suggested chip
  → CoachChatViewModel.sendMessage()
  → append user message
  → state.isThinking = true
  → CoachChatFacade.send(prompt)
  → CoachPreviewSeedLoader.load(intent: generalChat)
  → previewMessage(metadata: { feature: coach_chat, mode: preview })
  → map skill response, explanation, reasons, notes, next actions, trace
  → append coach message
  → state.isThinking = false
```

### State diagram

```
empty
  → loaded + thinking
  → loaded
  → error

loading
  → skeleton
```

### Product layout

- Header: Coach, Online, Today's Focus, Recovery, Conversation
- Empty state: hero greeting and quick actions
- Suggested chips: Today's workout, Review my program, Modify my workout,
  Recovery, Nutrition, Supplements, Progress
- Timeline: date separator, fade/slide messages, auto-scroll
- AI message cards: explanation, reasons, coach notes, warnings,
  recommendations, next actions, knowledge insight, follow-up questions, trace
- Thinking state: analyzing/checking/reviewing/building skeleton text
- Bottom composer: attach placeholder, voice placeholder, send

### Message support

The domain model supports:

- Normal
- Explanation
- Warning
- Workout Preview
- Review Result
- Modification Preview
- Memory Update
- Knowledge Insight
- Follow-up Question
- Local Skill Response
- AI Response

### Data mapping

`CoachChatFacade` maps existing `CoachIntegrationResult` data only:

| UI surface | Preview source |
|------------|----------------|
| Main text | skill response message, local message, follow-up question, fallback placeholder |
| Explanation | `skillExecutionResult.response.explanation` |
| Reasons | `skillExecutionResult.response.reasons` |
| Warnings | `skillExecutionResult.response.warnings` |
| Recommendations | `skillExecutionResult.response.recommendations` |
| Next actions | `skillExecutionResult.response.nextActions` |
| Coach notes | `decision.notes` |
| Knowledge insight | `decision.knowledgeReasons` |
| Follow-up | `responsePlan.followUpQuestions` |
| Trace | integration logs |

### Technical debt

| Item | Future |
|------|--------|
| Preview-only responses | Add real execution only in a future runtime EPIC |
| No persisted conversation | Add read/write session storage in a future write-capable EPIC |
| Generic message cards | Add richer typed cards after result contracts stabilize |
| Composer placeholders | Attach/voice are visual placeholders only |
| Route not registered globally | Register only when product navigation rollout is approved |

### Remove candidates

| Candidate | Future |
|-----------|--------|
| Fallback placeholder text | Remove once preview always returns response text |
| Trace card in user UI | Move to diagnostics if product wants less technical output |
| Static suggested chips | Replace with personalized suggestions from preview when available |

### Verification

- `flutter analyze lib/features/coach_chat test/features/coach_chat` — **No issues found**
- `flutter test test/features/coach_chat` — **7 passed**

---

## EPIC 29.5 — Coach Chat Preview Integration (Debug Only)

### Scope

Wire the EPIC 29 Coach Chat UI into the app for **debug-only** preview testing.
No engine, runtime, pipeline, or business logic changes. No database, memory,
or state persistence.

### Changes

| Area | Change |
|------|--------|
| Route | `/coach-chat` registered in `RouteService` via `CoachChatRoute` |
| Debug drawer | "Coach Chat (Preview)" under `kDebugMode` Coach v2 preview section |
| Screen entry | `CoachChatFacade.load()` → empty conversation + suggested chips |
| User actions | Chips and Send call `previewMessage()` only via `CoachChatFacade.send()` |
| Release nav | Unchanged — drawer entry is `kDebugMode` only |

### Sequence diagram

```
Debug drawer → /coach-chat
  → CoachChatScreen(autoLoad)
  → CoachChatViewModel.load()
  → CoachChatFacade.load()
  → CoachChatState.empty (no preview, no persist)

User taps chip / Send
  → CoachChatViewModel.sendMessage()
  → CoachChatFacade.send(prompt)
  → CoachPreviewSeedLoader + previewMessage()
  → append coach message in memory only
```

### Verification

- `flutter analyze lib/features/coach_chat lib/services/route_service.dart lib/dashboard/widgets/dashboard_drawer.dart test/features/coach_chat` — run after changes
- `flutter test test/features/coach_chat` — run after changes
- Confirm: no `CoachPipeline` execution writes, no repository writes, no memory/state persistence from Coach Chat screen

---

## EPIC 30 — GymAI Design System v1

### Scope

`lib/design_system/` introduces a standalone design system for GymAI. This EPIC
is tokens + components + motion + layout only. It does not change coach engine,
workout generator/review/modify, prompt, pipeline, memory, knowledge, entity,
OpenAI, business logic, repositories, database, or navigation.

### Folder structure

```
lib/design_system/
├── theme/
│   ├── gym_colors.dart
│   ├── gym_typography.dart
│   ├── gym_spacing.dart
│   ├── gym_radius.dart
│   ├── gym_shadows.dart
│   ├── gym_motion.dart
│   └── gym_theme.dart
├── components/
│   ├── gym_card.dart
│   ├── gym_button.dart
│   ├── gym_chip.dart
│   ├── gym_badge.dart
│   ├── gym_avatar.dart
│   ├── gym_progress_bar.dart
│   ├── gym_progress_ring.dart
│   ├── gym_metric_tile.dart
│   ├── gym_section_header.dart
│   ├── gym_divider.dart
│   ├── gym_empty_state.dart
│   ├── gym_error_state.dart
│   ├── gym_loading_state.dart
│   └── gym_skeleton.dart
├── icons/gym_icons.dart
├── animations/
│   ├── fade_slide.dart
│   ├── scale_in.dart
│   ├── stagger_column.dart
│   └── shimmer.dart
└── layout/
    ├── page_scaffold.dart
    ├── page_padding.dart
    └── responsive_breakpoints.dart
```

### Design tokens

| Token group | Values |
|-------------|--------|
| Colors | Primary gold, background `#090909`, surface `#151515`, card `#1B1B1B`, semantic success/warning/danger/info, neutral scale |
| Typography | Display, Headline, Title, Body, Caption, Overline — RTL-first, `IRANSans` |
| Spacing | 4, 8, 12, 16, 20, 24, 32, 40, 48 |
| Radius | 12, 16, 20, 24, 32 |
| Shadows | Small, Medium, Large (dark-theme optimized) |
| Motion | Durations (instant → slower), curves (standard, enter, exit, emphasized), stagger step |

### Component library

| Component | Variants / notes |
|-----------|------------------|
| `GymButton` | Primary, Secondary, Ghost, Danger; Compact; Full width; Loading; Disabled |
| `GymCard` | Hero, Metric, Insight, Action, Warning, Timeline, Glass, Compact |
| `GymExpandableCard` | Collapsible insight/action card |
| `GymChip` | Filled, Outline, Ghost; selected state |
| `GymBadge` | Primary, Success, Warning, Danger, Info, Neutral |
| `GymAvatar` | sm/md/lg; image, initials, icon; online indicator |
| `GymProgressBar` | Linear, animated |
| `GymProgressRing` | Circular, animated, optional label |
| `GymMetricTile` | Title, value, subtitle, icon, trend |
| `GymSectionHeader` | Title, subtitle, optional action |
| `GymDivider` | Horizontal, vertical, labeled |
| `GymEmptyState` | Icon, title, message, action |
| `GymErrorState` | Error card with retry |
| `GymLoadingState` | Spinner + optional message |
| `GymSkeleton` | Hero, Card, Timeline, Chat bubble |

### Motion library

- `GymFadeSlide` — fade + vertical slide entrance
- `GymScaleIn` — scale entrance
- `GymStaggerColumn` — staggered list entrance
- `GymShimmer` / `GymShimmerBlock` — loading shimmer overlay

### Theme architecture

- `GymTheme.dark` — Material 3 dark theme with gold primary
- `GymThemeExtension` — semantic colors via `Theme.of(context).extension`
- All components consume `GymColors`, `GymSpacing`, `GymRadius`, `GymTypography` tokens
- No hardcoded colors or ad-hoc padding inside design-system widgets

### Dependency diagram

```
Feature UI (future adoption)
  → lib/design_system/components/*
  → lib/design_system/theme/* (tokens)
  → lib/design_system/animations/*
  → lib/design_system/layout/*
  → lib/design_system/icons/gym_icons.dart

Does NOT depend on:
  CoachPipeline, engines, repositories, OpenAI, features
```

### Component rules

1. No hardcoded colors in design-system widgets — use `GymColors`
2. No magic-number padding — use `GymSpacing`
3. Features should adopt tokens when migrated (not in this EPIC)
4. RTL via `GymTypography.direction` and `GymPageScaffold`

### Technical debt

| Item | Future |
|------|--------|
| Features still use `AppTheme` directly | Gradual migration to `GymTheme` tokens |
| No light theme variant | Add `GymTheme.light` when product needs it |
| Lucide icon subset | Expand `GymIcons` as features adopt design system |
| No Storybook/catalog screen | Add component gallery in debug builds |

### Remove candidates

| Candidate | Future |
|-----------|--------|
| Duplicate card/button styles in features | Replace with `GymCard` / `GymButton` during feature refactors |
| Per-feature shimmer/skeleton widgets | Replace with `GymSkeleton` variants |
| Hardcoded `Color(0xFF...)` in presentation layers | Migrate to `GymColors` |

### Verification

- `flutter analyze lib/design_system` — **No issues found**
- `flutter test test/design_system/gym_design_system_test.dart` — component/token tests

---

## EPIC 31 — Product UX Redesign (Phase 1)

### Scope

Presentation-layer redesign for Coach Home, Workout Today, Coach Chat, and Live
Workout using `lib/design_system/`. No changes to engines, pipeline, prompt,
OpenAI, facades (except `refresh()` UX wiring), repositories, navigation routes,
or business logic.

### Layout diagram

```
GymPageScaffold (RTL, dark, max-width)
├── Pull-to-refresh → ViewModel.refresh()
├── GymStaggerColumn / GymFadeSlide (entry motion)
├── Section cards (GymCard variants)
│   ├── Hero / Metric / Insight / Action / Glass / Timeline
│   ├── GymProgressRing / GymProgressBar
│   ├── GymExpandableCard (explainability)
│   └── GymMetricTile / GymBadge / GymChip
├── GymSkeleton (loading)
├── GymEmptyState / GymErrorState
└── Sticky bottom CTA (GymButton fullWidth)
```

### Feature layouts

| Feature | Sections |
|---------|----------|
| **Coach Home** | Hero, Today's Focus, Recovery Ring, Today's Recommendation, Coach Insight, Coach Memory, Recent Activity, Quick Actions, Explainability, FAB → `/coach-chat` |
| **Workout Today** | Hero, Start Workout, Workout Summary, Muscle Visualization, Exercise Timeline, Coach Notes, Explainability, Quick Actions, sticky Start CTA |
| **Coach Chat** | Header, Today divider, empty hero, suggested chips, message bubbles, expandable explainability cards, thinking + typing, floating composer |
| **Live Workout** | Hero, Progress Ring, Current Exercise, Sets, Rest Timer, Upcoming Exercise, Coach Tips, Explainability, sticky session CTA |

### Design decisions

| Decision | Rationale |
|----------|-----------|
| All colors/spacing/radius from tokens | No hardcoded `Color(0xFF...)` or magic padding in features |
| Removed per-feature fade widgets | Replaced with `GymFadeSlide`, `GymStaggerColumn`, `GymMotion` |
| `ViewModel.refresh()` added | Enables pull-to-refresh without changing facades or pipeline |
| Recovery as ring + bars | Ring for readiness headline; bars for recovery/fatigue/sleep detail |
| Explainability as `GymExpandableCard` | Progressive disclosure for preview reasoning |
| Haptic on primary actions | `HapticFeedback` on send, chips, start workout, set complete |

### Before / After

| Before | After |
|--------|-------|
| `AppTheme` + `#141414` hardcoded cards | `GymCard`, `GymColors`, `GymTypography` |
| `CoachFadeIn` / custom skeletons | `GymStaggerColumn`, `GymSkeleton` variants |
| Manual `EdgeInsets.fromLTRB(20,18,...)` | `GymSpacing.page`, `GymPagePadding` |
| Gold `FilledButton` duplicates | `GymButton` primary/compact/fullWidth |
| Static explainability lists | `GymExpandableCard` |

### Dependency diagram

```
Feature Screen (presentation only)
  → ViewModel (unchanged facade calls + refresh())
  → lib/design_system/components/*
  → lib/design_system/theme/*
  → lib/design_system/animations/*
  → lib/design_system/layout/*

Does NOT import:
  CoachPipeline, engines, repositories, OpenAI, prompt builders
```

### Technical debt

| Item | Future |
|------|--------|
| Rest timer hardcoded "90 sec" | Wire to session/preview when available |
| Voice/attach composer placeholders | Implement in future interaction EPIC |
| Scroll-aware collapsing header | Add `SliverAppBar` polish in Phase 2 |
| Page transition animations | Register custom `PageRoute` when nav rollout approved |
| Light theme features | When `GymTheme.light` lands |

### Remove candidates

| Candidate | Status |
|-----------|--------|
| `coach_fade_in.dart` | **Removed** |
| `workout_today_fade_in.dart` | **Removed** |
| `workout_today_skeleton.dart` | **Removed** |
| `coach_chat_animations.dart` | **Removed** |
| `live_workout_fade_slide.dart` | **Removed** |
| `CoachSectionCard` / `WorkoutTodayBaseCard` wrappers | Kept as thin `GymCard` delegates |

### Verification

- `flutter analyze lib/features/coach lib/features/workout_today lib/features/coach_chat lib/features/live_workout` — no errors
- `flutter test test/features/coach test/features/workout_today test/features/coach_chat test/features/live_workout` — **31 passed**

---

## EPIC 32 — Product Experience Redesign (Phase 2)

### Scope

Transform Coach surfaces from an engineering dashboard into a cohesive AI fitness
product. **UI/UX only** — no changes to CoachPipeline, WorkoutGenerator, AI
engines, Exercise Intelligence, Review/Modify engines, prompt, OpenAI, business
logic, repositories, or facade mapping logic.

### Product copy layer

`lib/features/product_experience/product_copy.dart` centralizes Persian labels,
`buildCoachBrief()` narrative composition, `humanizeReason()` for explainability,
and quick-action chip emoji/labels. Features import this module for presentation
text only.

### Layout changes (dashboard → product)

| Before (EPIC 31) | After (EPIC 32) |
|------------------|-----------------|
| Recovery + Recommendation + Insight + Memory + Activity cards | **Coach Brief** (ring + narrative bubble) |
| English section titles | Persian (`تمرین امروز`, `خلاصه مربی`, `چرا این پیشنهاد؟`) |
| Gold quick-action buttons | Emoji **chips** (`📝 اصلاح برنامه`, `🔥 تمرین امروز`, …) |
| Generic hero greeting | **Real hero**: workout focus + metrics + شروع تمرین |
| Log-style explainability | Humanized reasons via `ProductCopy.humanizeReason()` |
| ChatGPT-style chat chrome | **Messages-style** header, bubbles, chips, Persian composer |

### Feature layouts (Phase 2)

| Feature | Flow |
|---------|------|
| **Coach Home** | Hero → Coach Brief (ring + narrative) → Quick chips → Why expandable |
| **Workout Today** | Hero + recovery ring → Summary → Timeline → Coach notes → Why → Chips |
| **Coach Chat** | Large header (avatar + status) → empty bubble hero → suggestion chips → iMessage bubbles → thinking/typing → composer |
| **Live Workout** | Hero metrics → progress ring → current exercise → sets → rest → upcoming → coach tips → why |

### Design decisions

| Decision | Rationale |
|----------|-----------|
| Fewer, varied sections | User grasps today's workout in under 3s without reading 10 identical cards |
| `ProductCopy` module | Single place for Persian personality + humanized explainability |
| Less gold accent | Chips/surfaces use neutral grays; accent on primary CTA only |
| Larger typography | `GymTypography.display` 36px, body 15px / 1.65 line height |
| Unified motion | `GymStaggerColumn`, `GymFadeSlide`, `GymScaleIn` across features |
| Persian empty states | e.g. «هنوز برنامه‌ای برای امروز نداری. بزن تا برات بسازم.» |

### Acceptance criteria

Within 3 seconds the user knows:

1. What workout is scheduled today
2. Why that workout was chosen
3. Where the start button is

### Verification

- `flutter analyze lib/features/coach lib/features/workout_today lib/features/coach_chat lib/features/live_workout lib/features/product_experience` — no errors
- `flutter test test/features/coach test/features/workout_today test/features/coach_chat test/features/live_workout test/features/product_experience` — all passed
- Golden screenshots: N/A (no golden tests in repo at EPIC 32)

---

## EPIC 33 — Real AI Experience Integration

### Scope

Wire existing Coach engines and context into product UI **without** new pipelines,
prompts, engines, repositories, or business logic. Integration-only.

### Integration layer (`lib/features/product_experience/`)

| Module | Role |
|--------|------|
| `coach_program_resolver.dart` | Loads real `WorkoutProgram` via `active_program_id` + `WorkoutProgramService`, maps sessions/exercises |
| `product_experience_formatter.dart` | Shared recovery, brief, explainability, timeline, quick-action copy |
| `coach_experience_runtime_bridge.dart` | Calls existing `WorkoutReviewRuntime`, `WorkoutModifyRuntime` for quick actions |
| `coach_resolved_program.dart` | Resolved today workout DTO shared by facades |
| `product_copy.dart` | Persian labels only (formatting delegates to formatter) |

### Facade changes

All feature facades now: `previewMessage` → `CoachProgramResolver` → `ProductExperienceFormatter` → view state.

- **Coach Home**: real recovery ring, `coachBrief` from context/memory/knowledge, review-powered explainability, quick actions call review/modify runtimes
- **Workout Today**: real exercise timeline (sets/reps/rest/notes), muscle map from program muscles, quick actions call review/modify/replace runtimes
- **Live Workout**: session from resolved program, Persian coach tips from skill/plan
- **Coach Chat**: intent detection on send, pipeline trace thinking steps, review/modify cards

### Task mapping

| Task | Integration |
|------|-------------|
| 1 Coach Home | `CoachFacade` reads `CoachContext`, review/generator reasons, `ProductExperienceFormatter` |
| 2 Coach Brief | `ProductExperienceFormatter.coachBrief` from recovery, memory, knowledge, goals, today workout |
| 3 Recovery | `recoverySnapshot` from preferences, heatmap, fatigue, sleep |
| 4 Workout Today | `CoachProgramResolver` → timeline with sets/reps/rest/tempo/notes |
| 5 Muscle viz | `MuscleCard` highlights from resolved `muscleGroups` |
| 6 Coach Notes | `coachNotes` from skill reasons + explainability |
| 7 Quick Actions | `CoachExperienceRuntimeBridge.runQuickActionMessages` → Review/Modify/Replace runtimes |
| 8 Coach Chat chips | `IntentIntelligenceEngine` + `promptForQuickAction` intents |
| 9 Typing | Pipeline trace thinking steps from real preview (no artificial delay) |
| 10 Live Workout | Resolved program → exercise timeline, progress, rest |
| 11–12 Formatter | `ProductExperienceFormatter` + `ProductCopy` labels |
| 13 UI audit | See below |

### UI audit (Task 13)

Scanned `lib/features/{coach,workout_today,coach_chat,live_workout,product_experience}` for placeholder/mock/TODO/hardcoded English product copy.

| Finding | Resolution |
|---------|------------|
| `Preview failed` in Coach Chat error card | Replaced with `ProductCopy.previewLoadFailed` |
| Stale mock comment in `coach_home_domain.dart` | Updated to document facade integration |
| `پیشنهاد من` in `ProductCopy` | Section label only (not mock content) |
| Supabase log noise in tests when resolver falls back | Handled via noop `programLoader` in tests; production uses real loader |

No remaining mock workout copy, placeholder timelines, or hardcoded coach narratives in Coach feature UI.

### Verification

- `flutter analyze lib/features/coach lib/features/workout_today lib/features/coach_chat lib/features/live_workout lib/features/product_experience` — 0 errors (info/warnings only)
- `flutter test test/features/coach test/features/workout_today test/features/coach_chat test/features/live_workout test/features/product_experience` — 36 passed

---

## EPIC 34 — Live Workout Real Session Logging

### Scope

Transform Live Workout from preview-only UI into a full in-app workout logging experience via **integration, session state, persistence, and UX** — no new AI engines, prompts, intents, generators, or exercise intelligence.

### Session models (`lib/features/live_workout/domain/session/`)

| Model | Role |
|-------|------|
| `WorkoutSession` | Typed runtime session (title, exercises, progress) |
| `WorkoutExerciseSession` | Exercise block with muscle + sets |
| `WorkoutSetSession` | Per-set targets + logged weight/reps/RPE/duration/notes |
| `WorkoutSetSessionStatus` | `pending`, `current`, `completed`, `skipped`, `failed` |

### Application layer

| Module | Role |
|--------|------|
| `live_workout_session_factory.dart` | Seeds runtime session from resolved program |
| `live_workout_session_store.dart` | SharedPreferences draft for resume/offline |
| `live_workout_rest_timer.dart` | Real rest timer (pause/resume/skip/extend) |
| `live_workout_session_persistence.dart` | Maps session → `WorkoutDailyLogService` |
| `live_workout_completion_service.dart` | Persist + `MemoryManager` + recovery prefs + coach summary |

### Integration (existing systems)

- **History (Task 13):** `WorkoutDailyLogService` / `workout_daily_logs` (cache-first, offline-safe)
- **Memory (Task 9):** `MemoryManager.addOrUpdateMemory` with `MemoryCategory.workout`
- **Heatmap (Task 10):** Derived from persisted daily logs via existing `WeeklyMuscleHeatmapService`
- **Recovery (Task 11):** Local `recovery_score_{userId}` preference update after completion
- **Coach message (Task 12):** `ProductExperienceFormatter.postWorkoutCoachMessage` compares to prior session volume

### UX

- Editable current set: weight, reps, RPE, duration, notes
- Real progress: *N* of *M* exercises, *X* of *Y* sets
- Auto-advance current set / highlight next exercise
- Completion summary card (no placeholder save message)
- Resume: draft restored on next `load()` if app closed mid-session

### Verification

- `flutter analyze lib/features/live_workout` — 0 errors
- `flutter test test/features/live_workout` — all passed

---

## EPIC 35 — Release Candidate & Product Polish

### Scope

Final polish epic — **no new engines, prompts, intents, generators, or business logic**. Integration, UX, legal, analytics, and release readiness only. **Code freeze after EPIC 35: bug fixes only.**

### Task delivery

| Task | Status | Notes |
|------|--------|-------|
| 1 Code audit | Done (features) | Coach feature dirs clean; legacy `lib/` TODOs ticketed in table below |
| 2 Persian copy | Done | `ProductCopy` + facade gap strings Persianized |
| 3 Motion | Standardized | All coach UI uses `GymMotion` via `GymFadeSlide` / `GymStaggerColumn` |
| 4 Spacing | Done | `GymSpacing.page` + `GymStaggerColumn` on coach screens |
| 5 Typography | Done | `GymTypography` tokens on all coach feature cards |
| 6 Performance | Checklist | Manual DevTools profile on Home/Timeline/Session/Chat (see Beta) |
| 7 Accessibility | Partial | RTL via `GymTypography.direction`; touch targets via `GymButton` |
| 8 Crash audit | Done | Feature try/catch → `GymErrorState` + retry; draft decode guarded |
| 9 Loading states | Done | Skeleton / empty / error / retry on all coach feature screens |
| 10 Release assets | Partial | `pubspec.yaml` points to `images/GymAI.jpg`; regen: `dart run flutter_native_splash:create` + `dart run flutter_launcher_icons` |
| 11 Privacy/Legal | Done | `/privacy-policy`, `/terms-of-service`, `/about-app`, `/open-source-licenses` + Settings links |
| 12 Analytics | Done | `ProductAnalytics` events wired in ViewModels (no AI logic) |
| 13 Real device QA | Manual | Required before store submit |
| 14 Beta checklist | Manual | See below |
| 15 Code freeze | Active | Post-EPIC-35: bug fixes only |

### Analytics events (`product_analytics.dart`)

| Event | Trigger |
|-------|---------|
| `coach_home_opened` | Coach Home load |
| `workout_today_opened` | Workout Today load |
| `workout_started` | Live Workout load (incl. `resumed: true`) |
| `workout_finished` | Session completion |
| `review_used` | Coach quick action review |
| `modify_used` | Coach quick action modify |
| `coach_chat_opened` | Coach Chat load |
| `coach_chat_message_sent` | User sends message |

### Legal routes

- `lib/features/legal/` — Persian privacy, terms, about, OSS licenses
- Linked from `SettingsScreen` → درباره section

### Remaining legacy TODOs (ticketed, out of coach scope)

| File | Note |
|------|------|
| `route_service.dart:119` | Async route interception |
| `notification_service.dart:669` | Image download caching |
| `skill_response_builder.dart:81` | epic11 muscle day gaps |
| `food_service.dart:474` | Food search API |
| `admin_service.dart:1576` | Real notification send |
| `api_usage_context_adapter.dart:38` | Subscription snapshot |

### Beta manual checklist (Task 14)

- [ ] Crash-free cold start on mid-range Android
- [ ] Offline: start live workout → kill app → resume draft
- [ ] Complete workout → summary → history in daily log
- [ ] Coach Chat send/receive without English leaks
- [ ] Quick actions: review + modify return Persian copy
- [ ] Workout Today timeline shows real sets/rest/notes
- [ ] Settings → privacy/terms/licenses open correctly

### Store assets (manual)

- Regenerate splash + launcher from `images/GymAI.jpg`
- Prepare Play Store: banner 1024×500, screenshots, feature graphic

### Verification

- `flutter analyze lib/features/coach lib/features/workout_today lib/features/coach_chat lib/features/live_workout lib/features/product_experience lib/features/legal` — 0 errors
- `flutter test test/features/coach test/features/workout_today test/features/coach_chat test/features/live_workout test/features/product_experience` — all passed

---

## EPIC 36 — GymAI Coach Product Architecture

> **Scope:** Product design and subscription architecture only.  
> **Out of scope:** Runtime changes, new engines, pipeline changes, duplicate models, implementation tasks.  
> This section defines how GymAI presents ONE coach to the user, regardless of how many internal engines exist.

### Product philosophy

GymAI has many internal capabilities — Workout Generator, Exercise Intelligence, Workout Review, Workout Modify, Knowledge Runtime, Pipeline, Blueprint, Memory, Context — but **the user must never need to know they exist**. Those are implementation details.

The entire AI experience must feel like **ONE coach** with different capabilities depending on subscription:

| Principle | Rule |
|-----------|------|
| Single coach identity | One name, one voice, one chat — never “AI Generator” vs “AI Review” as separate products |
| Program-agnostic execution | The coach helps execute **any** `WorkoutProgram` — human coach, AI-generated, manual, imported, or future PDF |
| Single runtime | `WorkoutProgram` → Live Workout → `WorkoutSession` → History → AI Analysis — source of program never changes runtime |
| Capability gating, not product splitting | Subscription unlocks capabilities; it does not create separate apps or runtimes |
| ثبت تمرین vs تمرین زیر نظارت AI | Manual logging (`WorkoutLog`) and AI-supervised execution (`LiveWorkout`) are complementary surfaces sharing **one active program selection** — not competing products |

**What the user should feel:**

> “I always have ONE AI coach. Sometimes it creates a program for me. Sometimes it just helps me execute the program my human coach gave me. The coach never changes — only what it can do.”

---

### Subscription model

Create **ONLY TWO** customer-facing AI plans. Internal entitlement enums may remain granular during migration; product and paywall copy expose only these two tiers.

#### Plan 1 — GymAI Coach

**Purpose:** The AI becomes the user's intelligent workout **partner**. It does **NOT** create workout programs. It works with **any** existing `WorkoutProgram`.

**Supported program sources:**

| Source | Today | Notes |
|--------|-------|-------|
| GymAI-generated program (assigned to user) | Yes | Created elsewhere (Pro or human coach); Coach tier executes only |
| Human coach program | Yes | Primary Journey A |
| Manual / builder program | Yes | `WorkoutProgramService` |
| Imported program | Partial | Same model; import UX TBD |
| Future PDF import | Roadmap | Same `WorkoutProgram` target |

**Capabilities (product surface):**

- Live Workout guidance (AI-supervised session)
- Coach Chat
- Workout Review
- Workout Modify
- Recovery / readiness analysis
- Exercise replacement suggestions
- Heatmap explainability
- Progress analysis
- Memory (coach remembers preferences, injuries, context)
- Explainability (“why this suggestion”)
- Intelligent recommendations during session
- Session summary
- Smart rest timer
- Performance tracking (via session → history)

#### Plan 2 — GymAI Coach Pro

**Everything in GymAI Coach, PLUS:**

- AI Workout Generation (multi-session programs)
- Multi-week planning / periodization (blueprint-level)
- Nutrition Coach
- Future premium AI features (voice, video form, etc.)

**Product rule:** Pro adds **creation and planning** capabilities. Execution, chat, review, and modify remain identical to Coach tier — same Live Workout UX, same `WorkoutSession` runtime.

---

### Capability matrix

| Feature (user-facing) | GymAI Coach | GymAI Coach Pro | Internal capability (implementation) | Notes |
|------------------------|:-----------:|:---------------:|--------------------------------------|-------|
| Live Workout | ✓ | ✓ | — (product surface) | Same runtime for all program sources |
| Coach Chat | ✓ | ✓ | `coachConversation` | Single chat identity |
| Workout Review | ✓ | ✓ | `aiWorkoutReview`, `aiProgramReview` | Never exposed as separate “Review product” |
| Workout Modify | ✓ | ✓ | `modifyWorkout` | Quick actions → chat/runtime bridge |
| Recovery / readiness | ✓ | ✓ | `recoveryAnalysis` | Shown as “آمادگی تمرین” with ℹ️ guide |
| Heatmap | ✓ | ✓ | `explainHeatmap` | Workout log + coach context |
| Progress analysis | ✓ | ✓ | `analyzeProgress` | History + heatmap aggregation |
| Memory | ✓ | ✓ | `advancedMemory` | Surfaced as “یادداشت مربی” / coach notes |
| Explainability | ✓ | ✓ | knowledge + generator reasons | Filtered via `ProductExperienceFormatter` |
| Exercise replacement | ✓ | ✓ | Exercise Intelligence + Modify runtime | User sees “جایگزینی حرکت” only |
| Session summary | ✓ | ✓ | Live Workout completion | Post-session Persian summary |
| Smart rest timer | ✓ | ✓ | `LiveWorkoutRestTimer` | Per-set rest from program |
| Performance tracking | ✓ | ✓ | `WorkoutDailyLog` + completion service | Shared history regardless of log path |
| **Workout generation** | — | ✓ | `generateWorkout` | Pro-only; output is still `WorkoutProgram` |
| Multi-week planning | — | ✓ | Blueprint + generator | Pro-only |
| Nutrition coach | — | ✓ | `nutritionPlanning`, `aiNutritionReview` | Pro-only |
| Periodization | — | ✓ | Blueprint strategies | Pro-only |
| Future premium AI | — | ✓ | TBD | Voice, PDF import coach, etc. |

**Free tier (product):** Limited chat + heatmap preview only — not a third “coach product”; marketing positions upgrade to GymAI Coach.

---

### User journeys

#### Journey A — Human coach program, AI supervision

```
User receives workout from human coach
        ↓
Program stored as WorkoutProgram (trainer_id → human coach)
        ↓
User selects active program (name + creator shown)
        ↓
Workout Today → preview today’s session
        ↓
Live Workout → AI coach guides execution (same runtime as any program)
        ↓
WorkoutSession logged → WorkoutDailyLog / history
        ↓
AI Review + Modify + replacement suggestions
        ↓
Progress + heatmap + memory inform next session
```

**Key invariant:** Human coach remains “creator” in UI; GymAI remains “supervisor” during Live Workout — never a second coach product.

#### Journey B — AI creates program, same execution

```
User (Pro) asks coach to create program
        ↓
GymAI Coach Pro → WorkoutProgram (generated_by / is_self_service_ai)
        ↓
Program activated (same selector as Journey A)
        ↓
Live Workout → identical execution UX to Journey A
        ↓
Same history, review, modify, progress pipeline
```

**Key invariant:** Journey B differs only in **program origin** and **subscription** — not in session runtime or UI chrome.

#### Journey C — Manual logging (complementary)

```
User opens ثبت تمرین (Workout Log)
        ↓
Same active WorkoutProgram + session day selection
        ↓
Manual set entry (weight, reps, RPE) — no AI pipeline required
        ↓
Same WorkoutDailyLog storage
        ↓
Coach tier can still Review / analyze logged data later
```

**Product separation:** Workout Log = manual ledger; Live Workout = AI-supervised execution. Shared: program selection, set model, history.

---

### Runtime invariants

These rules are **non-negotiable** for all future EPICs:

```
WorkoutProgram          ← ONLY workout definition model (stored + AI + human)
       ↓
Live Workout            ← ONLY AI-supervised execution entry (Coach product)
       ↓
WorkoutSession          ← ONLY in-session runtime (lib/features/live_workout/domain/session/)
       ↓
WorkoutDailyLog         ← ONLY persisted history (workout_log models)
       ↓
AI Analysis             ← Review / Modify / Chat / Progress (read history + program)
```

**Forbidden (never introduce):**

| Anti-pattern | Why |
|--------------|-----|
| `HumanWorkoutSession` / `AIWorkoutSession` / `CoachWorkoutSession` | Duplicates runtime; breaks Journey A/B parity |
| Separate pipeline per program source | Source is metadata on `WorkoutProgram`, not a runtime fork |
| Multiple coach personas in UI | One coach; capabilities gated silently |
| “Generator app” vs “Coach app” navigation | Single AI hub → one coach |

**Allowed program metadata (does not fork runtime):**

- `trainer_id`, `user_id`, `generated_by`, `is_self_service_ai`
- `ActiveProgramService.active_program_id` (shared across Workout Today, Live Workout, Workout Log)

---

### Product UX map (surfaces → ONE coach)

| Surface | Route | User sees | Must NOT expose |
|---------|-------|-----------|-----------------|
| AI Hub | `/ai` or tab | “مربی هوش مصنوعی” entry points | Pipeline, skills, engines |
| Coach Home | `/coach` | Greeting, readiness, quick actions | `CoachPipelineTrace` (debug only) |
| Workout Today | `/workout-today` | Today’s session + start | Resolver, context providers |
| Live Workout | `/live-workout` | Guided session | Generator, blueprint |
| Coach Chat | `/coach-chat` | Conversation with coach | Intent names, entitlement IDs |
| Workout Log | `/workout-log` | Manual ثبت تمرین | “Different workout system” |
| My Programs | programs screen | Select/activate program | Internal storage schema |

**Copy rule:** All Persian strings go through `ProductCopy` / `ProductExperienceFormatter` — no engine identifiers in user-visible text (enforced in EPIC 33, 35).

---

### Migration audit — capabilities vs EPICs

Audit of **existing implementation** against product capabilities. Status: **Engine/runtime exists** vs **Product wiring** vs **Gap (wiring only)**.

| Capability | Satisfying EPICs | Engine / integration | Product wiring status | Wiring gap (no new engines) |
|------------|------------------|----------------------|------------------------|----------------------------|
| Unified Coach Pipeline | 10, 15, 17, 18, 27, 33, 36→37 | `CoachPipeline`, `CoachFeatureIntegration` | Runtime default on | None — keep internal |
| Coach Home | 25, 31, 33, 35 | `CoachFacade` + formatter | Live | — |
| Workout Today | 26, 31, 33, 35 | `WorkoutTodayFacade` + resolver | Live | Program selector + readiness guide (post-35 polish) |
| Live Workout session | 28, 34, 35 | `WorkoutSession`, persistence, completion | Live | Program selector bar; RPE guide |
| Coach Chat | 29, 33, 35 | Chat facade + completion service | Live | Single coach voice; hide trace in release |
| Workout Review | 23, 33 | `WorkoutReviewRuntime` | Wired via quick actions | Surface as coach action, not “Review Engine” |
| Workout Modify | 24, 33 | `WorkoutModifyRuntime` | Wired via quick actions | Same |
| Workout Generation | 19, 20, 20.5, 21 | Generator + Blueprint | Engine complete | **Paywall:** Pro-only in product; hide from Coach tier UX |
| Exercise Intelligence | 21, 22 | Replacement/scoring engines | Runtime internal | User label: “جایگزینی حرکت” only |
| Recovery analysis | 2, 13, 33 | Context + `recoverySnapshot` | Live in Hero/cards | ℹ️ explanation copy (`TrainingMetricGuides`) |
| Heatmap | 3, 33 | `HeatmapContextProvider`, log aggregate | Live in log + context | Coach tier explainability |
| Memory | 2, 9, 33 | `MemoryManager`, context projection | Partial in coach notes | More memory in chat/home cards |
| Explainability | 12, 13, 33 | Knowledge + formatter filters | Live (filtered) | Continue stripping technical EN |
| Entitlement | 7, 13 | `EntitlementEngine`, capability map | **Multi-plan enum** | **Product:** collapse to Coach / Coach Pro in paywall |
| Design system | 30, 31, 32 | `lib/design_system/` | Applied to coach features | Extend to Workout Log parity where needed |
| Active program selection | 33, 35, 36 (this doc) | `ActiveProgramService` | Shared selector added | Session-day picker; My Programs deep link |
| Workout Log (manual) | pre-EPIC, 34 bridge | `WorkoutLogViewModel` | Live | RPE parity + shared program bar |
| Nutrition | skills + `nutritionPro` plan | Nutrition capabilities | Engine partial | **Pro product** — single “مربی تغذیه” under same coach |
| Production migration | 36→37 (renamed) | `CoachFeatureIntegration` | Runtime on | — |

**Summary:** Core engines and runtimes from EPICs 2–24 and integration EPICs 25–35 **already satisfy** the capability matrix. Remaining work is **product wiring and subscription simplification** — not new engines or duplicate runtimes.

---

### Entitlement migration (product → existing code)

Current code (`CoachSubscriptionPlan`) defines: `free`, `coachPro`, `nutritionPro`, `recoveryPro`, `ultimateAI`, `enterprise`, `lifetime`.

**Target product mapping (documentation only; implementation in future entitlement EPIC):**

| Product plan | Maps from (interim) | Capability bundle |
|--------------|---------------------|-------------------|
| **GymAI Coach** | `coachPro` minus `generateWorkout` OR new `coach` plan id | Execution + chat + review + modify + recovery + memory |
| **GymAI Coach Pro** | `ultimateAI` / `coachPro` + generation + nutrition | All Coach capabilities + `generateWorkout` + `nutritionPlanning` + planning |

**Rule:** Runtime continues to check `CoachCapability` — never `CoachSubscriptionPlan` in feature code. Paywall copy references two plans only.

---

### Future roadmap (product-only)

| Phase | Theme | Deliverable |
|-------|-------|-------------|
| 36.1 | Subscription UX | Two-plan paywall; capability-based upgrade prompts |
| 36.2 | Program sources | PDF import → `WorkoutProgram`; same selector |
| 36.3 | Coach identity | Unified avatar, name (`AppConfig.gymAiDisplayName`), tone across chat/live/home |
| 36.4 | Journey polish | Session-day picker; resume draft banners; Pro generation entry in chat only |
| 36.5 | Nutrition (Pro) | Nutrition under same coach chat — not separate “Nutrition AI app” |
| 36.6 | Analytics | Funnel: program selected → today viewed → live started → completed → review used |

---

### Explicit non-goals (EPIC 36)

- No new `CoachPipeline` stages
- No new generator, review, or modify engines
- No `AIWorkoutSession` or parallel history models
- No duplicate Live Workout runtime for human vs AI programs
- No user-facing exposure of: Blueprint, Entity Engine, Intent Intelligence, Knowledge Runtime, Prompt Planner
- No implementation tasks in this EPIC — architecture and product rules only

---

### Relationship to EPIC 35 code freeze

EPIC 35 declared **bug fixes only** after release candidate polish. EPIC 36 is a **product architecture document** that guides future wiring EPICs (36.x) without violating the engine freeze: all changes must be integration, copy, paywall, and selector UX — aligned with `lib/features/product_experience/`.

---

## EPIC 37 — Production Migration (Preview → Runtime)

### Goal

Move Coach product features from dry-run `previewMessage` to live `processMessage` while keeping preview as a fallback when `COACH_V2_ENABLED=false`.

### Integration layer

| File | Role |
|------|------|
| `coach_feature_integration.dart` | Routes facade calls to `processMessage` (runtime) or `previewMessage` (fallback) |
| `coach_preview_seed_loader.dart` | Loads authenticated `userId` + `CoachContext` (source: `runtime`) |

### Facade wiring

All feature facades (`coach_facade`, `workout_today_facade`, `live_workout_facade`, `coach_chat_facade`) now default to `CoachFeatureIntegration.defaultLoader()` instead of `CoachIntegrationService().previewMessage`.

Metadata: `{ feature: '<screen>', mode: 'runtime' | 'preview' }` — set by integration, not facades.

### Coach V2 flag

- `CoachV2Config.coachV2Enabled` defaults **true** (override via `COACH_V2_ENABLED` env or `debugOverride` in tests)
- `CoachHomeScreen.enforceCoachV2Gate` defaults **false** — product UI always loads; gate is opt-in for admin/debug

### Navigation replacement

| Legacy | Production |
|--------|------------|
| Bottom-nav AI tab → `AIHubScreen` (hub) | همه ابزارهای مربی از یک نقطه |
| AI Hub quick chat → `ChatScreen` | → `/coach-chat` |
| AI Hub programs → `AIProgramsScreen` | → `/coach` / `/workout-today` |
| Dashboard drawer preview labels | Persian product labels |

### UI polish

- Coach Chat trace card hidden in release (`kDebugMode` only)
- Error copy: «خطا در بارگذاری مربی» (not «پیش‌نمایش»)
- Gap strings genericized (no «از پیش‌نمایش»)

### Preview vs production map

```
Screen → ViewModel → Facade → CoachFeatureIntegration
         → processMessage (runtime) when coachV2Enabled
         → previewMessage (dry-run) when disabled
         → CoachProgramResolver → ProductExperienceFormatter → View State
```

### Verification

- `flutter test test/features/coach test/features/workout_today test/features/coach_chat test/features/live_workout test/features/product_experience`
- Manual: full flow Home → Today → Live → Chat on device with real user session

