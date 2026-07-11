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
  integration_event.dart
  integration_logger.dart
```

## Pipeline Diagram

```text
User Message
  -> CoachIntegrationService.previewMessage()
  -> AIIntentDetector.detect()
  -> KnowledgeGraph / KnowledgeRegistry (future source of truth)
  -> AIContextEngine.selectProviders()
  -> CoachBrain.decideForSelection()
  -> CoachValidator.validate()
  -> CoachRouter.route()
  -> CoachBrain.planForSelection()
  -> CoachResponsePlan.fromDecision()
  -> CoachExecutor.preview()
  -> CoachIntegrationResult
```

The pipeline is preview-only. `CoachExecutor.preview()` always returns a dry-run
preview and never executes OpenAI, local UI responses, navigation, APIs, or
workout generation.

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
- Provides `KnowledgeRegistry` as the future single source of truth for
  `CoachBrain`, validators, context selection, and response planning.
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

- Builds structured `PromptPackage` data from intent, context, memory,
  knowledge, personality, and budget inputs.
- Selects only context and memory sections relevant to the intent knowledge
  node.
- Provides prompt budget, metadata, version, validation, and compressor
  contracts.
- Does not render final prompt text and is not connected to existing OpenAI
  prompts or services.

### Coach Brain

- Validates intent readiness.
- Produces `CoachDecision`.
- Routes between future local, AI, follow-up, or error paths.
- Converts decisions into `CoachResponsePlan` through a planner adapter.

### Planner

- Models an integration-ready response plan.
- Defines future actions such as `CALL_OPENAI`, `LOCAL_RESPONSE`,
  `FOLLOW_UP`, and navigation-oriented actions.
- Provides a dry-run `CoachExecutor` that classifies execution type but does not
  execute anything.

### Integration

- Runs the first real end-to-end dry-run pipeline.
- Logs each step in memory through `IntegrationLogger`.
- Returns `CoachIntegrationResult` for diagnostics and future tests.
- Is not connected to ChatScreen, AIHub, WorkoutGenerator, ProgressAnalysis, or
  navigation.

## Dependency Graph

```text
integration
  -> planner
  -> coach
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

## Pending Phases

- Unit tests for intent definitions, provider selection, coach decisions,
  response plans, and dry-run integration results.
- Migrate CoachBrain validation and context selection to `KnowledgeRegistry`.
- Connect memory reads through a dedicated `MemoryContextProvider`.
- Add tests for rule-based memory extraction, confidence, deduplication, and
  conflict resolution.
- Real rule/keyword/regex intent resolvers.
- Dedicated providers still pending for memory, nutrition, app help,
  diagnostics, and typed recovery readiness.
- Feature-flagged integration with ChatScreen in preview-only mode.
- Prompt template registry that does not mutate existing OpenAI prompts.
- Tests for PromptBuilder package selection, budget behavior, and validation.
- Optional telemetry boundary after product approval.

## Future TODO

- Keep broad context providers available until all dry-run consumers migrate to
  granular providers.
- Keep `KnowledgeRegistry` and `AIIntentDefinitions` synchronized until
  CoachBrain fully migrates to the knowledge layer.
- Make active-program reads user-id scoped instead of relying on current auth
  user only.
- Persist questionnaire answers into profile consistently so equipment and
  injury fields do not depend on local-only fallbacks.
- Add a read-only subscription entitlement snapshot; subscription services may
  mutate expired rows during reads.
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
