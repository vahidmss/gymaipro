import 'package:gymaipro/ai/entity/entity_type.dart';

/// Raw entity match emitted by the rule engine.
class EntityMatch {
  const EntityMatch({
    required this.ruleId,
    required this.type,
    required this.rawText,
    required this.rawValue,
    required this.score,
    required this.start,
    required this.end,
    this.rawUnit,
    this.locale,
  });

  /// Rule that produced the match.
  final String ruleId;

  /// Matched entity type.
  final EntityType type;

  /// Raw matched text.
  final String rawText;

  /// Raw extracted value.
  final String rawValue;

  /// Raw extracted unit, if any.
  final String? rawUnit;

  /// Weighted match score.
  final double score;

  /// Start offset in normalized message.
  final int start;

  /// End offset in normalized message.
  final int end;

  /// Optional locale marker.
  final String? locale;
}

/// Normalized entity emitted by the extractor.
class NormalizedEntity {
  const NormalizedEntity({
    required this.type,
    required this.value,
    required this.confidence,
    required this.source,
    this.unit,
    this.alternatives = const <EntityAlternative>[],
  });

  /// Entity type.
  final EntityType type;

  /// Canonical normalized value.
  final Object value;

  /// Canonical normalized unit.
  final String? unit;

  /// Confidence score from 0 to 1.
  final double confidence;

  /// Source raw match.
  final EntityMatch source;

  /// Alternative normalized entities for the same type.
  final List<EntityAlternative> alternatives;
}

/// Alternative entity candidate.
class EntityAlternative {
  const EntityAlternative({
    required this.type,
    required this.value,
    required this.confidence,
    this.unit,
  });

  /// Entity type.
  final EntityType type;

  /// Alternative value.
  final Object value;

  /// Alternative unit.
  final String? unit;

  /// Alternative confidence.
  final double confidence;
}
