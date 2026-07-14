import 'package:gymaipro/ai/entity/entity_type.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';

/// Shared entity integration mapping for Coach v2 runtime bridges.
///
/// This registry keeps entity-to-state and entity-to-memory mappings in one
/// place so integration layers do not duplicate field/type switches.
class EntityIntegrationRegistry {
  const EntityIntegrationRegistry._();

  static const List<EntityIntegrationMapping> mappings =
      <EntityIntegrationMapping>[
        EntityIntegrationMapping(
          entityType: EntityType.height,
          fieldKeys: <String>{'height'},
          memoryMapping: EntityMemoryMapping(
            key: 'profile.height',
            category: MemoryCategory.profile,
            importance: MemoryImportance.medium,
          ),
        ),
        EntityIntegrationMapping(
          entityType: EntityType.weight,
          fieldKeys: <String>{'weight'},
          memoryMapping: EntityMemoryMapping(
            key: 'profile.weight',
            category: MemoryCategory.profile,
            importance: MemoryImportance.medium,
          ),
        ),
        EntityIntegrationMapping(
          entityType: EntityType.age,
          fieldKeys: <String>{'age'},
          memoryMapping: EntityMemoryMapping(
            key: 'profile.age',
            category: MemoryCategory.profile,
            importance: MemoryImportance.medium,
          ),
        ),
        EntityIntegrationMapping(
          entityType: EntityType.gender,
          fieldKeys: <String>{'gender'},
          memoryMapping: EntityMemoryMapping(
            key: 'profile.gender',
            category: MemoryCategory.profile,
            importance: MemoryImportance.medium,
          ),
        ),
        EntityIntegrationMapping(
          entityType: EntityType.goal,
          fieldKeys: <String>{'goal', 'goals'},
          memoryMapping: EntityMemoryMapping(
            key: 'goals.primary',
            category: MemoryCategory.goal,
            importance: MemoryImportance.high,
          ),
        ),
        EntityIntegrationMapping(
          entityType: EntityType.equipment,
          fieldKeys: <String>{'equipment', 'equipments'},
          memoryMapping: EntityMemoryMapping(
            key: 'equipment.available',
            category: MemoryCategory.equipment,
            importance: MemoryImportance.medium,
          ),
        ),
        EntityIntegrationMapping(
          entityType: EntityType.experience,
          fieldKeys: <String>{'experience', 'experience_level'},
          memoryMapping: EntityMemoryMapping(
            key: 'profile.experience',
            category: MemoryCategory.profile,
            importance: MemoryImportance.high,
          ),
        ),
        EntityIntegrationMapping(
          entityType: EntityType.injury,
          fieldKeys: <String>{'injury', 'injuries'},
          memoryMapping: EntityMemoryMapping(
            key: 'restrictions.injury',
            category: MemoryCategory.restriction,
            importance: MemoryImportance.critical,
          ),
        ),
        EntityIntegrationMapping(
          entityType: EntityType.medicalCondition,
          fieldKeys: <String>{'medical_conditions', 'medical_condition'},
          memoryMapping: EntityMemoryMapping(
            key: 'medical.condition',
            category: MemoryCategory.medical,
            importance: MemoryImportance.critical,
          ),
        ),
      ];

  static Set<EntityType> entityTypesForFieldKey(String fieldKey) {
    final normalized = fieldKey.trim();
    if (normalized.isEmpty) return const <EntityType>{};

    return Set<EntityType>.unmodifiable(
      mappings
          .where((mapping) => mapping.fieldKeys.contains(normalized))
          .map((mapping) => mapping.entityType),
    );
  }

  static EntityMemoryMapping? memoryMappingForType(EntityType type) {
    for (final mapping in mappings) {
      if (mapping.entityType == type) return mapping.memoryMapping;
    }
    return null;
  }

  static bool isPersistableMemoryType(EntityType type) {
    return memoryMappingForType(type) != null;
  }
}

class EntityIntegrationMapping {
  const EntityIntegrationMapping({
    required this.entityType,
    required this.fieldKeys,
    this.memoryMapping,
  });

  final EntityType entityType;
  final Set<String> fieldKeys;
  final EntityMemoryMapping? memoryMapping;
}

class EntityMemoryMapping {
  const EntityMemoryMapping({
    required this.key,
    required this.category,
    required this.importance,
  });

  final String key;
  final MemoryCategory category;
  final MemoryImportance importance;
}
