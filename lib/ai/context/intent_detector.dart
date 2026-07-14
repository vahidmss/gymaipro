/// Intent categories supported by GymAI Coach v2.
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
