import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';
import 'package:gymaipro/ai/integration/integration_event.dart';
import 'package:gymaipro/ai/planner/coach_executor.dart';
import 'package:gymaipro/ai/planner/coach_response_plan.dart';
import 'package:gymaipro/ai/prompt/prompt_package.dart';

/// Result returned by the Coach v2 integration pipeline.
class CoachIntegrationResult {
  const CoachIntegrationResult({
    required this.intent,
    required this.coachContext,
    required this.decision,
    required this.responsePlan,
    required this.executorPreview,
    required this.processingTime,
    required this.missingProviders,
    required this.missingData,
    required this.confidence,
    required this.estimatedCost,
    required this.estimatedTokens,
    required this.estimatedLatency,
    required this.logs,
    this.providerSelection,
    this.promptPackage,
  });

  /// Detected intent.
  final AIIntent intent;

  /// Unified coach context package.
  final CoachContext coachContext;

  /// Provider selection used for this run.
  final AIContextProviderSelection? providerSelection;

  /// Coach decision produced before planning.
  final CoachDecision decision;

  /// Response plan generated from the decision.
  final CoachResponsePlan responsePlan;

  /// Structured prompt package for Coach v2 rendering.
  final PromptPackage? promptPackage;

  /// Dry-run execution preview.
  final CoachExecutionPreview executorPreview;

  /// Total processing time for the pipeline.
  final Duration processingTime;

  /// Required providers that were missing.
  final Set<AIContextProviderKey> missingProviders;

  /// Required data fields that were missing.
  final List<String> missingData;

  /// Decision/plan confidence.
  final double confidence;

  /// Estimated relative cost.
  final double estimatedCost;

  /// Estimated token budget.
  final int estimatedTokens;

  /// Estimated latency.
  final Duration estimatedLatency;

  /// In-memory pipeline logs.
  final List<IntegrationEvent> logs;
}
