import 'package:gymaipro/ai/entity/entity_type.dart';

/// Metadata for one extractable entity type.
class EntityDefinition {
  const EntityDefinition({
    required this.type,
    required this.id,
    required this.title,
    required this.description,
    required this.valueKind,
    this.defaultUnit,
    this.supportedUnits = const <String>[],
    this.locales = const <String>['fa', 'en'],
    this.tags = const <String>[],
  });

  /// Entity enum value.
  final EntityType type;

  /// Stable machine id.
  final String id;

  /// Human-readable title.
  final String title;

  /// Product description.
  final String description;

  /// Canonical value kind after normalization.
  final EntityValueKind valueKind;

  /// Default normalized unit.
  final String? defaultUnit;

  /// Units accepted by normalizer.
  final List<String> supportedUnits;

  /// Supported locales.
  final List<String> locales;

  /// Optional grouping tags.
  final List<String> tags;
}
