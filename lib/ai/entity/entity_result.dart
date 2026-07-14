import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/entity/entity_trace.dart';
import 'package:gymaipro/ai/entity/entity_type.dart';

/// Immutable output of entity extraction.
class EntityExtractionResult {
  const EntityExtractionResult({
    required this.originalMessage,
    required this.normalizedMessage,
    required this.rawMatches,
    required this.entities,
    required this.trace,
  });

  /// Original user message.
  final String originalMessage;

  /// Normalized message used for matching.
  final String normalizedMessage;

  /// Raw extracted matches.
  final List<EntityMatch> rawMatches;

  /// Normalized entities.
  final List<NormalizedEntity> entities;

  /// Debug trace.
  final EntityTrace trace;

  /// Whether any entity was extracted.
  bool get hasEntities => entities.isNotEmpty;

  /// Entities by type.
  Map<EntityType, List<NormalizedEntity>> get entitiesByType {
    final map = <EntityType, List<NormalizedEntity>>{};
    for (final entity in entities) {
      map.putIfAbsent(entity.type, () => <NormalizedEntity>[]).add(entity);
    }
    return Map<EntityType, List<NormalizedEntity>>.unmodifiable(map);
  }
}
