import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/knowledge/knowledge_requirement.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';

/// Behavior when required knowledge is missing.
enum KnowledgeMissingBehaviour {
  askFollowUp,
  routeToLocalFallback,
  blockAndExplain,
  continueWithLowerConfidence,
}

/// Central knowledge definition for one Coach intent.
class KnowledgeNode {
  const KnowledgeNode({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredKnowledge,
    required this.optionalKnowledge,
    required this.missingBehaviour,
    required this.recommendedFollowUp,
    required this.defaultAction,
    required this.requiresAI,
    this.intent,
  });

  /// Stable node id. This can represent current or future intents.
  final String id;

  /// Current AIIntent enum value when available.
  final AIIntent? intent;

  /// Human-readable title.
  final String title;

  /// Product description of the intent.
  final String description;

  /// Required knowledge for a complete answer.
  final List<KnowledgeRequirement> requiredKnowledge;

  /// Optional knowledge that improves answer quality.
  final List<KnowledgeRequirement> optionalKnowledge;

  /// Missing knowledge behavior.
  final KnowledgeMissingBehaviour missingBehaviour;

  /// Recommended follow-up question when required knowledge is missing.
  final String recommendedFollowUp;

  /// Default future action.
  final CoachAction defaultAction;

  /// Whether the default complete answer requires AI.
  final bool requiresAI;
}
