import 'package:gymaipro/ai/context/context_models.dart';

/// Metadata describing how a coach context package was assembled.
class CoachContextMetadata {
  const CoachContextMetadata({
    required this.buildTime,
    required this.sourceCount,
    required this.missingProviders,
    required this.confidence,
    required this.contextVersion,
  });

  /// Time when the context package was assembled.
  final DateTime buildTime;

  /// Number of populated context sources included in the package.
  final int sourceCount;

  /// Provider keys that were requested but could not be satisfied.
  final Set<AIContextProviderKey> missingProviders;

  /// Heuristic confidence score for context completeness.
  final double confidence;

  /// Coach context schema version.
  final String contextVersion;
}
