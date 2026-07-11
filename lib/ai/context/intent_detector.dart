/// Intent categories supported by GymAI Coach v2.
///
/// This enum is intentionally rule-free for phase 1. Future phases can map
/// user text, app events, or deep links to these values without changing the
/// context engine contract.
enum AIIntent {
  workoutGeneration,
  workoutToday,
  workoutModification,
  exerciseQuestion,
  workoutQuestion,
  progressAnalysis,
  recovery,
  nutrition,
  supplement,
  motivation,
  generalFitness,
  generalChat,
  appHelp,
  bugReport,
  feedback,
}

/// Strategy families supported by the intent detection pipeline.
enum IntentDetectionStrategy { rule, regex, keyword, llm }

/// Immutable input for intent detection.
class IntentDetectionRequest {
  const IntentDetectionRequest({
    required this.message,
    this.locale,
    this.metadata = const <String, Object?>{},
  });

  /// Raw user message or app-provided text.
  final String message;

  /// Optional locale hint for future language-aware detection.
  final String? locale;

  /// Optional product metadata such as source screen or CTA id.
  final Map<String, Object?> metadata;
}

/// Result object returned by [AIIntentDetector].
class IntentDetectionResult {
  const IntentDetectionResult({
    required this.intent,
    this.confidence,
    this.reason,
    this.strategy,
  });

  /// Best matching high-level intent.
  final AIIntent intent;

  /// Optional confidence score for future rule-based or model-based detectors.
  final double? confidence;

  /// Optional diagnostic explanation for internal tooling.
  final String? reason;

  /// Strategy that produced the result.
  final IntentDetectionStrategy? strategy;
}

/// Base contract for future intent detection strategies.
abstract interface class IntentDetectionResolver {
  /// Strategy family implemented by this resolver.
  IntentDetectionStrategy get strategy;

  /// Returns a result when the resolver can detect an intent.
  IntentDetectionResult? resolve(IntentDetectionRequest request);
}

/// Detects the user's intent before context is assembled.
///
/// Phase 2 defines a pipeline for rule, regex, keyword, and LLM-backed
/// resolvers. No resolver performs NLP or calls AI yet.
class AIIntentDetector {
  const AIIntentDetector({
    List<IntentDetectionResolver> resolvers = const <IntentDetectionResolver>[],
  }) : _resolvers = resolvers;

  final List<IntentDetectionResolver> _resolvers;

  /// Registered detection resolvers in execution order.
  List<IntentDetectionResolver> get resolvers => _resolvers;

  /// Runs the resolver pipeline and falls back to a neutral intent.
  IntentDetectionResult detect(IntentDetectionRequest request) {
    for (final resolver in _resolvers) {
      final result = resolver.resolve(request);
      if (result != null) return result;
    }

    return const IntentDetectionResult(
      intent: AIIntent.generalChat,
      confidence: 0,
      reason: 'Phase 2 fallback detector.',
    );
  }
}
