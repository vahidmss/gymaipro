import 'package:gymaipro/ai/entity/entity_type.dart';

/// One weighted synonym entry for keyword entity extraction.
class EntitySynonym {
  const EntitySynonym({
    required this.value,
    required this.terms,
    this.weight = 1,
    this.locale,
  });

  /// Canonical value emitted when any term matches.
  final String value;

  /// Terms or phrases that map to [value].
  final List<String> terms;

  /// Relative confidence weight.
  final double weight;

  /// Optional locale marker.
  final String? locale;
}

/// Data-driven rule for one entity type.
class EntityRule {
  const EntityRule({
    required this.id,
    required this.type,
    required this.ruleType,
    required this.weight,
    this.synonyms = const <EntitySynonym>[],
    this.regexPattern,
    this.valueGroup = 1,
    this.unitGroup,
    this.caseInsensitive = true,
    this.description,
  });

  /// Stable rule id.
  final String id;

  /// Target entity type.
  final EntityType type;

  /// Matching strategy.
  final EntityRuleType ruleType;

  /// Base rule weight.
  final double weight;

  /// Keyword/synonym entries.
  final List<EntitySynonym> synonyms;

  /// Regex pattern for extraction.
  final String? regexPattern;

  /// Regex capture group containing value.
  final int valueGroup;

  /// Optional regex capture group containing unit.
  final int? unitGroup;

  /// Whether matching should be case-insensitive.
  final bool caseInsensitive;

  /// Diagnostic description.
  final String? description;
}
