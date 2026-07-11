import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/prompt/prompt_version.dart';

/// Metadata attached to a prompt package.
class PromptMetadata {
  const PromptMetadata({
    required this.intent,
    required this.createdAt,
    required this.version,
    required this.sectionCount,
    required this.estimatedTokens,
    required this.estimatedCost,
    required this.requiresAI,
    required this.knowledgeNodeId,
    this.notes = const <String>[],
  });

  /// Intent represented by the package.
  final AIIntent intent;

  /// Package creation time.
  final DateTime createdAt;

  /// Builder/template architecture version.
  final PromptVersion version;

  /// Selected knowledge node id.
  final String? knowledgeNodeId;

  /// Number of included sections.
  final int sectionCount;

  /// Estimated input tokens.
  final int estimatedTokens;

  /// Estimated relative cost.
  final double estimatedCost;

  /// Whether the package is meant for a future AI call.
  final bool requiresAI;

  /// Diagnostic notes.
  final List<String> notes;
}
