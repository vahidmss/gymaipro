import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_trace.dart';

/// Output of the knowledge runtime stage.
class CoachKnowledgeResult {
  const CoachKnowledgeResult({
    required this.selectedNode,
    required this.candidateNodes,
    required this.confidence,
    required this.reasons,
    required this.trace,
    this.usedFallback = false,
  });

  /// Best-ranked knowledge node for this request.
  final KnowledgeNode selectedNode;

  /// Candidate nodes considered during ranking.
  final List<KnowledgeNode> candidateNodes;

  /// Confidence in the selected node from 0 to 1.
  final double confidence;

  /// Human-readable selection reasons.
  final List<String> reasons;

  /// Detailed ranking trace.
  final CoachKnowledgeTrace trace;

  /// Whether the general fallback node was used.
  final bool usedFallback;
}
