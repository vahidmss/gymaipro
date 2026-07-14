import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/knowledge/knowledge_graph.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_ranker.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_trace.dart';

/// Validates knowledge selection and applies safe fallback behavior.
class CoachKnowledgeValidator {
  const CoachKnowledgeValidator({
    this.fallbackNodeId = 'general_chat',
  });

  /// Stable id used when no node is suitable.
  final String fallbackNodeId;

  /// Applies fallback to general chat when [selected] is null.
  CoachKnowledgeResult validate({
    required KnowledgeGraph graph,
    required CoachKnowledgeRankedNode? selected,
    required List<CoachKnowledgeRankedNode> ranked,
    required Duration executionTime,
  }) {
    final candidateNodes = ranked.map((entry) => entry.node).toList();
    final nodeTraces = ranked.map((entry) => entry.trace).toList();

    if (selected != null) {
      return CoachKnowledgeResult(
        selectedNode: selected.node,
        candidateNodes: List<KnowledgeNode>.unmodifiable(candidateNodes),
        confidence: selected.score,
        reasons: _selectionReasons(selected),
        trace: CoachKnowledgeTrace(
          nodeTraces: List<CoachKnowledgeNodeTrace>.unmodifiable(nodeTraces),
          executionTime: executionTime,
          selectedNodeId: selected.node.id,
          usedFallback: false,
        ),
      );
    }

    final fallback =
        graph.nodeById(fallbackNodeId) ??
        graph.nodeForIntent(AIIntent.generalChat) ??
        graph.allNodes.first;

    return CoachKnowledgeResult(
      selectedNode: fallback,
      candidateNodes: List<KnowledgeNode>.unmodifiable(candidateNodes),
      confidence: ranked.isEmpty ? 0.2 : ranked.first.score,
      reasons: <String>[
        'No knowledge node met the minimum ranking threshold.',
        'Fell back to ${fallback.id}.',
      ],
      trace: CoachKnowledgeTrace(
        nodeTraces: List<CoachKnowledgeNodeTrace>.unmodifiable(nodeTraces),
        executionTime: executionTime,
        selectedNodeId: fallback.id,
        usedFallback: true,
      ),
      usedFallback: true,
    );
  }

  List<String> _selectionReasons(CoachKnowledgeRankedNode selected) {
    return List<String>.unmodifiable(<String>[
      'Selected ${selected.node.id} with score ${selected.score.toStringAsFixed(2)}.',
      ...selected.trace.reasons,
    ]);
  }
}
