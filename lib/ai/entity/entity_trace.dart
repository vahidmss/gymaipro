import 'package:gymaipro/ai/entity/entity_type.dart';

/// Debug trace for one evaluated entity rule.
class EntityTraceEntry {
  const EntityTraceEntry({
    required this.ruleId,
    required this.entityType,
    required this.ruleType,
    required this.matched,
    required this.score,
    this.rawText,
    this.detail,
  });

  /// Rule id.
  final String ruleId;

  /// Entity type name.
  final String entityType;

  /// Rule type name.
  final String ruleType;

  /// Whether this rule matched.
  final bool matched;

  /// Awarded score.
  final double score;

  /// Raw matched text.
  final String? rawText;

  /// Diagnostic detail.
  final String? detail;
}

/// Immutable entity extraction trace.
class EntityTrace {
  const EntityTrace({required this.normalizedMessage, required this.entries});

  /// Normalized user message.
  final String normalizedMessage;

  /// Per-rule trace entries.
  final List<EntityTraceEntry> entries;

  /// Number of matched rules.
  int get matchedRuleCount => entries.where((entry) => entry.matched).length;

  /// Matched entity types.
  Set<EntityType> get matchedTypes {
    final values = <EntityType>{};
    for (final entry in entries.where((item) => item.matched)) {
      final type = EntityType.values.firstWhere(
        (value) => value.name == entry.entityType,
        orElse: () => EntityType.timeExpression,
      );
      values.add(type);
    }
    return Set<EntityType>.unmodifiable(values);
  }
}
