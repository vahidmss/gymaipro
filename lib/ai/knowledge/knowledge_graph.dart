import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/knowledge_registry.dart';

/// Read-only central knowledge graph for GymAI Coach.
///
/// This graph is not wired into runtime behavior yet. Future CoachBrain phases
/// can use it as the single source of truth for intent knowledge requirements.
class KnowledgeGraph {
  const KnowledgeGraph({this.nodes = KnowledgeRegistry.nodes});

  /// Registered nodes keyed by stable intent id.
  final Map<String, KnowledgeNode> nodes;

  /// Returns all registered nodes.
  Iterable<KnowledgeNode> get allNodes => nodes.values;

  /// Finds a node by stable id.
  KnowledgeNode? nodeById(String id) {
    return nodes[id];
  }

  /// Finds a node by current AIIntent enum when available.
  KnowledgeNode? nodeForIntent(AIIntent intent) {
    for (final node in nodes.values) {
      if (node.intent == intent) return node;
    }
    return null;
  }
}
