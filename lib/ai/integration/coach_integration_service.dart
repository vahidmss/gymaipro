import 'package:gymaipro/ai/coach/coach_brain.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_builder.dart';
import 'package:gymaipro/ai/context/context_engine.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/integration/integration_event.dart';
import 'package:gymaipro/ai/integration/integration_logger.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/planner/coach_executor.dart';
import 'package:gymaipro/ai/prompt/prompt_builder.dart';

/// Integration service for GymAI Coach v2.
///
/// When the feature flag is enabled, chat uses the full pipeline:
/// user message -> CoachContext -> CoachBrain -> CoachResponsePlan ->
/// PromptBuilder -> PromptPackage -> existing OpenAIService.
class CoachIntegrationService {
  CoachIntegrationService({
    AIIntentDetector intentDetector = const AIIntentDetector(),
    AIContextRepository? contextRepository,
    AIContextEngine? contextEngine,
    CoachBrain? coachBrain,
    CoachExecutor executor = const CoachExecutor(),
    PromptBuilder? promptBuilder,
    IntegrationLogger? logger,
  }) : _contextRepository = contextRepository ?? AIContextRepository(),
       _intentDetector = intentDetector,
       _contextEngine =
           contextEngine ??
           AIContextEngine(
             intentDetector: intentDetector,
             contextBuilder: AIContextBuilder.standard(
               repository: contextRepository ?? AIContextRepository(),
             ),
           ),
       _coachBrain =
           coachBrain ??
           CoachBrain(
             contextEngine:
                 contextEngine ??
                 AIContextEngine(intentDetector: intentDetector),
           ),
       _executor = executor,
       _promptBuilder = promptBuilder ?? const PromptBuilder(),
       _logger = logger ?? IntegrationLogger();

  final AIContextRepository _contextRepository;
  final AIIntentDetector _intentDetector;
  final AIContextEngine _contextEngine;
  final CoachBrain _coachBrain;
  final CoachExecutor _executor;
  final PromptBuilder _promptBuilder;
  final IntegrationLogger _logger;

  /// Runs the full Coach v2 pipeline for a user message.
  Future<CoachIntegrationResult> processMessage({
    required String userId,
    required String userMessage,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    final startedAt = DateTime.now();
    _contextRepository.clearFieldCache();
    _logger
      ..clear()
      ..log(
        IntegrationEventType.pipelineStarted,
        'Coach v2 pipeline started.',
        metadata: <String, Object?>{'messageLength': userMessage.length},
      );

    final detection = _intentDetector.detect(
      IntentDetectionRequest(message: userMessage, metadata: metadata),
    );
    _logger.log(
      IntegrationEventType.intentDetected,
      'Intent detected: ${detection.intent.name}.',
      metadata: <String, Object?>{
        'confidence': detection.confidence,
        'reason': detection.reason,
        'strategy': detection.strategy?.name,
      },
    );

    final request = AIContextRequest(
      userId: userId,
      intent: detection.intent,
      currentQuestion: userMessage,
      source: 'chat',
      metadata: metadata,
    );

    final coachContext = await _contextEngine.buildCoachContextForQuestion(
      request: request,
      intent: detection.intent,
      buildTime: startedAt,
    );
    _logger.log(
      IntegrationEventType.coachContextBuilt,
      'CoachContext assembled.',
      metadata: <String, Object?>{
        'sourceCount': coachContext.metadata.sourceCount,
        'contextVersion': coachContext.metadata.contextVersion,
        'confidence': coachContext.metadata.confidence,
      },
    );

    final providerSelection = _contextEngine.selectProviders(detection.intent);
    _logger.log(
      IntegrationEventType.providersSelected,
      'Providers selected.',
      metadata: <String, Object?>{
        'requiredProviders': providerSelection.requiredProviders
            .map((provider) => provider.id)
            .toList(growable: false),
        'optionalProviders': providerSelection.optionalProviders
            .map((provider) => provider.id)
            .toList(growable: false),
      },
    );

    if (providerSelection.missingRequiredProviders.isNotEmpty ||
        providerSelection.missingOptionalProviders.isNotEmpty) {
      _logger.log(
        IntegrationEventType.missingProviders,
        'Missing providers detected.',
        metadata: <String, Object?>{
          'missingRequired': providerSelection.missingRequiredProviders
              .map((provider) => provider.name)
              .toList(growable: false),
          'missingOptional': providerSelection.missingOptionalProviders
              .map((provider) => provider.name)
              .toList(growable: false),
        },
      );
    }

    final decision = _coachBrain.decideForSelection(
      providerSelection: providerSelection,
      context: coachContext,
    );
    _logger.log(
      IntegrationEventType.decisionCreated,
      'Coach decision created.',
      metadata: <String, Object?>{
        'shouldCallAI': decision.shouldCallAI,
        'missingData': decision.missingData,
        'confidence': decision.confidence,
      },
    );

    final responsePlan = _coachBrain.planForSelection(
      providerSelection: providerSelection,
      context: coachContext,
    );
    _logger.log(
      IntegrationEventType.responsePlanCreated,
      'Response plan created: ${responsePlan.action.wireName}.',
      metadata: <String, Object?>{
        'estimatedCost': responsePlan.estimatedCost,
        'estimatedTokens': responsePlan.estimatedTokens,
        'estimatedLatencyMs': responsePlan.estimatedLatency.inMilliseconds,
        'confidence': responsePlan.confidence,
      },
    );

    final promptPackage = _promptBuilder.buildFromCoachContext(
      CoachPromptBuildRequest(
        coachContext: coachContext,
        createdAt: coachContext.metadata.buildTime,
      ),
    );
    _logger.log(
      IntegrationEventType.promptPackageCreated,
      'Prompt package created.',
      metadata: <String, Object?>{
        'packageId': promptPackage.id,
        'sectionCount': promptPackage.sections.length,
        'estimatedTokens': promptPackage.metadata.estimatedTokens,
      },
    );

    final executorPreview = _executor.preview(responsePlan);
    _logger.log(
      IntegrationEventType.executorPreviewCreated,
      'Executor preview created.',
      metadata: <String, Object?>{
        'executionType': executorPreview.target.name,
        'wouldExecute': executorPreview.wouldExecute,
      },
    );

    final processingTime = DateTime.now().difference(startedAt);
    _logger.log(
      IntegrationEventType.pipelineCompleted,
      'Coach v2 pipeline completed.',
      metadata: <String, Object?>{
        'processingTimeMs': processingTime.inMilliseconds,
      },
    );

    return CoachIntegrationResult(
      intent: detection.intent,
      coachContext: coachContext,
      providerSelection: providerSelection,
      decision: decision,
      responsePlan: responsePlan,
      promptPackage: promptPackage,
      executorPreview: executorPreview,
      processingTime: processingTime,
      missingProviders: responsePlan.missingProviders,
      missingData: decision.missingData,
      confidence: responsePlan.confidence,
      estimatedCost: responsePlan.estimatedCost,
      estimatedTokens: responsePlan.estimatedTokens,
      estimatedLatency: responsePlan.estimatedLatency,
      logs: _logger.events,
    );
  }

  /// Runs a lightweight preview without building CoachContext or prompt data.
  CoachIntegrationResult previewMessage({
    required String userMessage,
    CoachContext? context,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final effectiveSeed = context ?? CoachContext.empty();
    final startedAt = DateTime.now();
    _logger
      ..clear()
      ..log(
        IntegrationEventType.pipelineStarted,
        'Coach integration preview started.',
        metadata: <String, Object?>{'messageLength': userMessage.length},
      );

    final detection = _intentDetector.detect(
      IntentDetectionRequest(message: userMessage, metadata: metadata),
    );
    final providerSelection = _contextEngine.selectProviders(detection.intent);
    final effectiveContext = _contextWithQuestion(effectiveSeed, userMessage);

    final decision = _coachBrain.decideForSelection(
      providerSelection: providerSelection,
      context: effectiveContext,
    );
    final responsePlan = _coachBrain.planForSelection(
      providerSelection: providerSelection,
      context: effectiveContext,
    );
    final executorPreview = _executor.preview(responsePlan);
    final processingTime = DateTime.now().difference(startedAt);

    return CoachIntegrationResult(
      intent: detection.intent,
      coachContext: effectiveContext,
      providerSelection: providerSelection,
      decision: decision,
      responsePlan: responsePlan,
      executorPreview: executorPreview,
      processingTime: processingTime,
      missingProviders: responsePlan.missingProviders,
      missingData: decision.missingData,
      confidence: responsePlan.confidence,
      estimatedCost: responsePlan.estimatedCost,
      estimatedTokens: responsePlan.estimatedTokens,
      estimatedLatency: responsePlan.estimatedLatency,
      logs: _logger.events,
    );
  }

  CoachContext _contextWithQuestion(CoachContext context, String userMessage) {
    if (context.currentQuestion != null &&
        context.currentQuestion!.trim().isNotEmpty) {
      return context;
    }

    return CoachContext(
      intent: context.intent,
      metadata: context.metadata,
      profile: context.profile,
      goals: context.goals,
      restrictions: context.restrictions,
      equipment: context.equipment,
      preferences: context.preferences,
      activeProgram: context.activeProgram,
      workoutHistory: context.workoutHistory,
      weeklyHeatmap: context.weeklyHeatmap,
      memories: context.memories,
      apiUsage: context.apiUsage,
      currentQuestion: userMessage,
      conversationSummary: context.conversationSummary,
    );
  }
}
