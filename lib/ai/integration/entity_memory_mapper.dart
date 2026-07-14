import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/integration/entity_integration_registry.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';
import 'package:gymaipro/ai/memory/memory_updater.dart';

/// Maps entity-engine output into memory update requests.
///
/// This mapper only consumes [NormalizedEntity] values. Extraction, parsing,
/// and entity validation stay in the entity module.
class EntityMemoryMapper {
  const EntityMemoryMapper({this.minConfidence = 0.35});

  final double minConfidence;

  /// Converts [entities] into memory update requests for persistable facts.
  List<MemoryUpdateRequest> mapEntities(List<NormalizedEntity> entities) {
    final bestByKey = <String, _MappedEntityCandidate>{};

    for (final entity in entities) {
      final mapping = EntityIntegrationRegistry.memoryMappingForType(
        entity.type,
      );
      if (mapping == null) continue;

      final candidates = <_MappedEntityCandidate>[
        _MappedEntityCandidate(
          key: mapping.key,
          value: _valueAsString(entity.value),
          category: mapping.category,
          importance: mapping.importance,
          confidence: entity.confidence,
        ),
        for (final alternative in entity.alternatives)
          for (final candidate in <_MappedEntityCandidate?>[
            _candidateForAlternative(alternative),
          ])
            if (candidate != null) candidate,
      ];

      for (final candidate in candidates) {
        if (candidate.confidence < minConfidence) continue;
        if (candidate.value.isEmpty) continue;

        final current = bestByKey[candidate.key];
        if (current == null || candidate.confidence > current.confidence) {
          bestByKey[candidate.key] = candidate;
        }
      }
    }

    return bestByKey.values
        .map(
          (candidate) => MemoryUpdateRequest(
            key: candidate.key,
            value: candidate.value,
            category: candidate.category,
            source: MemorySource.inference,
            confidence: candidate.confidence,
            importance: candidate.importance,
            aiGenerated: true,
          ),
        )
        .toList(growable: false);
  }

  String _valueAsString(Object value) => value.toString().trim();

  _MappedEntityCandidate? _candidateForAlternative(
    EntityAlternative alternative,
  ) {
    final mapping = EntityIntegrationRegistry.memoryMappingForType(
      alternative.type,
    );
    if (mapping == null) return null;

    return _MappedEntityCandidate(
      key: mapping.key,
      value: _valueAsString(alternative.value),
      category: mapping.category,
      importance: mapping.importance,
      confidence: alternative.confidence,
    );
  }
}

class _MappedEntityCandidate {
  const _MappedEntityCandidate({
    required this.key,
    required this.value,
    required this.category,
    required this.importance,
    required this.confidence,
  });

  final String key;
  final String value;
  final MemoryCategory category;
  final MemoryImportance importance;
  final double confidence;
}
