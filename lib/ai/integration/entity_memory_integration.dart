import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/integration/entity_memory_mapper.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_deduplicator.dart';
import 'package:gymaipro/ai/memory/memory_fact_confirmation_service.dart';
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
    this.pendingConfirmations = const <PendingMemoryConfirmation>[],
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
  final List<PendingMemoryConfirmation> pendingConfirmations;
}

/// Persists entity-engine output into coach memory.
class EntityMemoryIntegration {
  EntityMemoryIntegration({
    EntityMemoryMapper? mapper,
    MemoryManager? memoryManager,
    MemoryUpdater updater = const MemoryUpdater(),
    MemoryDeduplicator? deduplicator,
    MemoryFactConfirmationService? confirmationService,
  }) : _mapper = mapper ?? const EntityMemoryMapper(),
       _memoryManager = memoryManager ?? MemoryManager(),
       _updater = updater,
       _deduplicator = deduplicator ?? const MemoryDeduplicator(),
       _confirmationService =
           confirmationService ?? MemoryFactConfirmationService();

  final EntityMemoryMapper _mapper;
  final MemoryManager _memoryManager;
  final MemoryUpdater _updater;
  final MemoryDeduplicator _deduplicator;
  final MemoryFactConfirmationService _confirmationService;

  /// Maps [entities] to memory update requests and persists persistable facts.
  ///
  /// Sensitive medical / restriction facts are stored as pending confirmations
  /// instead of durable memories until the user confirms.
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

    final autoRequests = <MemoryUpdateRequest>[];
    final pendingRequests = <MemoryUpdateRequest>[];
    for (final request in requests) {
      if (MemoryFactConfirmationService.requiresConfirmation(request.category)) {
        pendingRequests.add(request);
      } else {
        autoRequests.add(request);
      }
    }

    final pendingConfirmations = pendingRequests
        .map(
          (request) => PendingMemoryConfirmation(
            originalKey: request.key,
            value: request.value,
            category: request.category,
            confidence: request.confidence,
            prompt: _confirmationService.confirmationPrompt(request),
          ),
        )
        .toList(growable: false);

    if (dryRun) {
      return EntityMemoryApplicationResult(
        mappedCount: requests.length,
        persistedCount: 0,
        skippedCount: entities.length - requests.length,
        duplicateCount: 0,
        conflictCount: 0,
        memoryKeys: requests.map((r) => r.key).toList(growable: false),
        memorySnapshot: const <CoachMemory>[],
        pendingConfirmations: pendingConfirmations,
      );
    }

    if (pendingRequests.isNotEmpty) {
      await _confirmationService.savePending(
        userId: userId,
        requests: pendingRequests,
      );
    }

    if (autoRequests.isEmpty) {
      final snapshot = await _memoryManager.loadActiveMemories(userId);
      return EntityMemoryApplicationResult(
        mappedCount: requests.length,
        persistedCount: 0,
        skippedCount: entities.length - requests.length,
        duplicateCount: 0,
        conflictCount: 0,
        memoryKeys: requests.map((r) => r.key).toList(growable: false),
        memorySnapshot: snapshot,
        pendingConfirmations: pendingConfirmations,
      );
    }

    final candidates = autoRequests
        .map(_updater.createMemory)
        .toList(growable: false);
    final existing = await _memoryManager.loadActiveMemories(userId);
    final deduplicated = _deduplicator.deduplicate(
      existing: existing,
      incoming: candidates,
    );

    final writeResult = await _memoryManager.saveResolvedMemories(
      userId,
      deduplicated.memories,
    );

    return EntityMemoryApplicationResult(
      mappedCount: requests.length,
      persistedCount: writeResult.saved ? autoRequests.length : 0,
      skippedCount: entities.length - requests.length,
      duplicateCount: deduplicated.duplicateCount,
      conflictCount: deduplicated.conflictCount,
      memoryKeys: requests.map((r) => r.key).toList(growable: false),
      memorySnapshot: writeResult.saved
          ? deduplicated.memories
          : const <CoachMemory>[],
      pendingConfirmations: pendingConfirmations,
    );
  }
}
