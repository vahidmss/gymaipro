import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_ranker.dart';

/// Selects the best knowledge node from ranked candidates.
class CoachKnowledgeSelector {
  const CoachKnowledgeSelector({
    this.minimumScore = 0.35,
  });

  /// Minimum score required to accept a non-fallback node.
  final double minimumScore;

  /// Returns the best ranked node if it meets [minimumScore].
  CoachKnowledgeRankedNode? selectBest(List<CoachKnowledgeRankedNode> ranked) {
    if (ranked.isEmpty) return null;
    final best = ranked.first;
    if (best.score < minimumScore) return null;
    return best;
  }

  /// Returns candidate nodes sorted by score.
  List<KnowledgeNode> candidateNodes(List<CoachKnowledgeRankedNode> ranked) {
    return ranked.map((entry) => entry.node).toList(growable: false);
  }
}
