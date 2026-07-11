/// Pipeline events emitted by the Coach v2 dry-run integration.
enum IntegrationEventType {
  pipelineStarted,
  intentDetected,
  providersSelected,
  missingProviders,
  decisionCreated,
  responsePlanCreated,
  coachContextBuilt,
  promptPackageCreated,
  executorPreviewCreated,
  pipelineCompleted,
}

/// In-memory integration event for diagnostics.
class IntegrationEvent {
  const IntegrationEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.metadata = const <String, Object?>{},
  });

  /// Event type.
  final IntegrationEventType type;

  /// Human-readable event message.
  final String message;

  /// Event timestamp.
  final DateTime timestamp;

  /// Additional metadata for debug tooling.
  final Map<String, Object?> metadata;
}
