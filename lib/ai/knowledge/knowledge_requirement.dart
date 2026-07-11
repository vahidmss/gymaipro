import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/knowledge/knowledge_category.dart';

/// Strategy used when a knowledge requirement is missing.
enum KnowledgeFallbackStrategy {
  askFollowUp,
  useLocalDefault,
  continueWithoutIt,
  blockExecution,
  requireHumanSupport,
}

/// One atomic knowledge requirement for an intent.
class KnowledgeRequirement {
  const KnowledgeRequirement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.required,
    required this.priority,
    required this.providerKey,
    required this.fallbackStrategy,
    this.validationRuleId,
  });

  /// Stable requirement id.
  final String id;

  /// Human-readable title.
  final String title;

  /// Description of why this knowledge is needed.
  final String description;

  /// Knowledge domain.
  final KnowledgeCategory category;

  /// Whether this requirement blocks a complete answer when missing.
  final bool required;

  /// Requirement priority.
  final ContextPriority priority;

  /// Provider key expected to satisfy this requirement.
  final AIContextProviderKey providerKey;

  /// Fallback behavior when this knowledge is missing.
  final KnowledgeFallbackStrategy fallbackStrategy;

  /// Optional validation rule id for CoachValidator migration.
  final String? validationRuleId;
}
