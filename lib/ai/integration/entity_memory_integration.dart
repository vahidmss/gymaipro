import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/integration/entity_memory_mapper.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_deduplicator.dart';
import 'package:gymaipro/ai/memory/memory_manager.dart';
import 'package:gymaipro/ai/memory/memory_updater.dart';

/// Result of applying extracted entities to coach memory.
class EntityMemoryApplicationResult {
  const EntityMemoryApplicationResult({
    required this.mappedCount,
    required this.persistedCount,
    required this.skippedCount,
    required this.duplicateCount,
    required this.conflictCount,
    required this.memoryKeys,
    required this.memorySnapshot,
  });

  static const empty = EntityMemoryApplicationResult(
    mappedCount: 0,
    persistedCount: 0,
    skippedCount: 0,
    duplicateCount: 0,
    conflictCount: 0,
    memoryKeys: <String>[],
    memorySnapshot: <CoachMemory>[],
  );

  final int mappedCount;
  final int persistedCount;
  final int skippedCount;
  final int duplicateCount;
  final int conflictCount;
  final List<String> memoryKeys;
  final List<CoachMemory> memorySnapshot;
}

/// Persists entity-engine output into coach memory.
///
/// This layer only consumes [NormalizedEntity] values and delegates merge and
/// conflict resolution to the memory deduplication pipeline before writing
/// through [MemoryManager].
class EntityMemoryIntegration {
  EntityMemoryIntegration({
    EntityMemoryMapper? mapper,
    MemoryManager? memoryManager,
    MemoryUpdater updater = const MemoryUpdater(),
    MemoryDeduplicator? deduplicator,
  }) : _mapper = mapper ?? const EntityMemoryMapper(),
       _memoryManager = memoryManager ?? MemoryManager(),
       _updater = updater,
       _deduplicator = deduplicator ?? const MemoryDeduplicator();

  final EntityMemoryMapper _mapper;
  final MemoryManager _memoryManager;
  final MemoryUpdater _updater;
  final MemoryDeduplicator _deduplicator;

  /// Maps [entities] to memory requests and persists persistable facts.
  ///
  /// When [dryRun] is true (preview mode), entities are mapped and deduplicated
  /// in memory only; nothing is written to storage.
  Future<EntityMemoryApplicationResult> applyEntities({
    required String userId,
    required List<NormalizedEntity> entities,
    bool dryRun = false,
  }) async {
    if (entities.isEmpty) {
      return EntityMemoryApplicationResult.empty;
    }

    final requests = _mapper.mapEntities(entities);
    if (requests.isEmpty) {
      return EntityMemoryApplicationResult(
        mappedCount: 0,
        persistedCount: 0,
        skippedCount: entities.length,
        duplicateCount: 0,
        conflictCount: 0,
        memoryKeys: const <String>[],
        memorySnapshot: const <CoachMemory>[],
      );
    }

    final candidates = requests
        .map(_updater.createMemory)
        .toList(growable: false);
    final existing = await _memoryManager.loadActiveMemories(userId);
    final deduplicated = _deduplicator.deduplicate(
      existing: existing,
      incoming: candidates,
    );

    if (dryRun) {
      final candidateKeys = requests
          .map((request) => request.key)
          .toList(growable: false);
      return EntityMemoryApplicationResult(
        mappedCount: requests.length,
        persistedCount: 0,
        skippedCount: entities.length - requests.length,
        duplicateCount: deduplicated.duplicateCount,
        conflictCount: deduplicated.conflictCount,
        memoryKeys: List<String>.unmodifiable(candidateKeys),
        memorySnapshot: deduplicated.memories,
      );
    }

    final writeResult = await _memoryManager.saveResolvedMemories(
      userId,
      deduplicated.memories,
    );
    final candidateKeys = requests
        .map((request) => request.key)
        .toList(growable: false);

    return EntityMemoryApplicationResult(
      mappedCount: requests.length,
      persistedCount: writeResult.saved ? requests.length : 0,
      skippedCount: entities.length - requests.length,
      duplicateCount: deduplicated.duplicateCount,
      conflictCount: deduplicated.conflictCount,
      memoryKeys: List<String>.unmodifiable(candidateKeys),
      memorySnapshot: writeResult.saved
          ? deduplicated.memories
          : const <CoachMemory>[],
    );
  }
}
