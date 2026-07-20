import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/context/context_builder.dart';
import 'package:gymaipro/ai/context/context_engine.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/coach/coach_brain.dart';
import 'package:gymaipro/ai/entity/entity_extractor.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/integration/coach_pipeline_dependencies_factory.dart';
import 'package:gymaipro/ai/integration/coach_state_integration.dart';
import 'package:gymaipro/ai/integration/entity_memory_integration.dart';
import 'package:gymaipro/ai/integration/integration_event.dart';
import 'package:gymaipro/ai/integration/integration_logger.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_builder.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_context.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_dependencies.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_result.dart';
import 'package:gymaipro/ai/planner/coach_executor.dart';
import 'package:gymaipro/ai/prompt/prompt_builder.dart';
import 'package:gymaipro/ai/context/coach_context.dart';

/// Single integration entry point for GymAI Coach v2.
///
/// Production chat uses [CoachChatFacade] and this service for pipeline work.
class CoachIntegrationService {
  CoachIntegrationService({
    AIContextRepository? contextRepository,
    AIContextEngine? contextEngine,
    CoachBrain? coachBrain,
    CoachExecutor executor = const CoachExecutor(),
    PromptBuilder? promptBuilder,
    IntegrationLogger? logger,
    CoachStateIntegration? stateIntegration,
    EntityExtractor? entityExtractor,
    EntityMemoryIntegration? entityMemoryIntegration,
    CoachPipeline? pipeline,
    CoachPipelineDependencies? pipelineDependencies,
  }) : _logger = logger ?? IntegrationLogger(),
       _pipelineDependencies =
           pipelineDependencies ??
           CoachPipelineDependenciesFactory.standard(
             contextRepository: contextRepository,
             contextEngine:
                 contextEngine ??
                 AIContextEngine(
                   contextBuilder: AIContextBuilder.standard(
                     repository: contextRepository ?? AIContextRepository(),
                   ),
                 ),
             coachBrain: coachBrain,
             executor: executor,
             promptBuilder: promptBuilder,
             logger: logger,
             stateIntegration: stateIntegration,
             entityExtractor: entityExtractor,
             entityMemoryIntegration: entityMemoryIntegration,
           ),
       _pipeline = pipeline;

  final IntegrationLogger _logger;
  final CoachPipelineDependencies _pipelineDependencies;
  final CoachPipeline? _pipeline;

  late final CoachPipelineBuilder _pipelineBuilder = CoachPipelineBuilder(
    dependencies: _pipelineDependencies,
  );

  /// Runs the Coach v2 pipeline for a user message.
  ///
  /// Requires [CoachV2Config.coachV2Enabled]. Callers should gate on the flag
  /// before invoking this service.
  Future<CoachIntegrationResult> processMessage({
    required String userId,
    required String userMessage,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    if (!CoachV2Config.coachV2Enabled) {
      throw UnsupportedError(
        'Coach v2 is disabled.',
      );
    }

    _pipelineBuilder.clearFieldCache();
    _logger
      ..clear()
      ..log(
        IntegrationEventType.pipelineStarted,
        'Coach v2 pipeline started.',
        metadata: <String, Object?>{'messageLength': userMessage.length},
      );

    final pipeline = _pipeline ?? _pipelineBuilder.build();
    final result = await pipeline.run(
      CoachPipelineContext.initial(
        userId: userId,
        userMessage: userMessage,
        metadata: metadata,
      ),
    );

    return _mapPipelineResult(result);
  }

  /// Runs a dry-run preview through the same [CoachPipeline] stages as runtime.
  Future<CoachIntegrationResult> previewMessage({
    required String userMessage,
    String userId = 'preview_user',
    CoachContext? context,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    _pipelineBuilder.clearFieldCache();
    _logger
      ..clear()
      ..log(
        IntegrationEventType.pipelineStarted,
        'Coach v2 preview pipeline started.',
        metadata: <String, Object?>{
          'messageLength': userMessage.length,
          'mode': CoachPipelineMode.preview.name,
        },
      );

    final pipeline = _pipeline ?? _pipelineBuilder.build();
    final result = await pipeline.run(
      CoachPipelineContext.initial(
        userId: userId,
        userMessage: userMessage,
        metadata: metadata,
        mode: CoachPipelineMode.preview,
        seedCoachContext: context,
      ),
    );

    return _mapPipelineResult(result);
  }

  CoachIntegrationResult _mapPipelineResult(CoachPipelineResult result) {
    final context = result.context;
    final coachContext = context.coachContext;

    if (coachContext == null) {
      throw StateError('Coach pipeline did not produce coach context.');
    }

    if (context.localSkillHandled && context.skillExecutionResult != null) {
      return CoachIntegrationResult.local(
        intent: context.intent,
        coachContext: coachContext,
        skillExecution: context.skillExecutionResult!,
        conversationState: context.conversationState,
        memoryApplication: context.memoryApplication,
        processingTime: result.trace.totalDuration,
        logs: _logger.events,
        pipelineTrace: result.trace,
        pipelineMode: result.mode,
      );
    }

    final decision = context.decision;
    final responsePlan = context.responsePlan;
    final executorPreview = context.executorPreview;

    if (decision == null ||
        responsePlan == null ||
        executorPreview == null) {
      throw StateError('Coach pipeline did not produce a complete result.');
    }

    return CoachIntegrationResult(
      intent: context.intent,
      coachContext: coachContext,
      decision: decision,
      responsePlan: responsePlan,
      promptPackage: context.promptPackage,
      conversationState: context.conversationState,
      memoryApplication: context.memoryApplication,
      executorPreview: executorPreview,
      processingTime: result.trace.totalDuration,
      missingProviders: responsePlan.missingProviders,
      missingData: decision.missingData,
      confidence: responsePlan.confidence,
      estimatedCost: responsePlan.estimatedCost,
      estimatedTokens: responsePlan.estimatedTokens,
      estimatedLatency: responsePlan.estimatedLatency,
      logs: _logger.events,
      pipelineTrace: result.trace,
      pipelineMode: result.mode,
    );
  }
}
