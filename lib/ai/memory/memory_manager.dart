import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_merger.dart';
import 'package:gymaipro/ai/memory/memory_repository.dart';
import 'package:gymaipro/ai/memory/memory_updater.dart';
import 'package:gymaipro/ai/memory/memory_validator.dart';

/// Result returned after adding or updating memory.
class MemoryWriteResult {
  const MemoryWriteResult({
    required this.memory,
    required this.validation,
    required this.wasMerged,
    required this.hasConflict,
    this.conflictReasons = const <String>[],
  });

  final CoachMemory? memory;
  final MemoryValidationResult validation;
  final bool wasMerged;
  final bool hasConflict;
  final List<String> conflictReasons;
}

/// Result returned after replacing a resolved memory snapshot.
class MemorySnapshotWriteResult {
  const MemorySnapshotWriteResult({
    required this.saved,
    required this.validation,
  });

  final bool saved;
  final MemoryValidationResult validation;
}

/// High-level API for the Coach Memory Engine.
///
/// The manager is infrastructure only. Nothing in the current app calls it yet.
class MemoryManager {
  MemoryManager({
    MemoryRepository? repository,
    MemoryUpdater updater = const MemoryUpdater(),
    MemoryMerger merger = const MemoryMerger(),
    MemoryValidator validator = const MemoryValidator(),
  }) : _repository = repository ?? MemoryRepository(),
       _updater = updater,
       _merger = merger,
       _validator = validator;

  final MemoryRepository _repository;
  final MemoryUpdater _updater;
  final MemoryMerger _merger;
  final MemoryValidator _validator;

  /// Adds or merges a memory for [userId].
  Future<MemoryWriteResult> addOrUpdateMemory(
    String userId,
    MemoryUpdateRequest request,
  ) async {
    final memories = await _repository.pruneExpired(userId);
    final existing = _findByKey(memories, request.key);
    final incoming = existing == null
        ? _updater.createMemory(request)
        : _updater.updateMemory(existing, request);
    final validation = _validator.validate(incoming);
    if (!validation.isValid) {
      return MemoryWriteResult(
        memory: null,
        validation: validation,
        wasMerged: existing != null,
        hasConflict: false,
      );
    }

    final result = existing == null
        ? MemoryMergeResult(memory: incoming, hasConflict: false)
        : _merger.merge(existing, incoming);

    await _repository.upsertMemory(userId, result.memory);
    return MemoryWriteResult(
      memory: result.memory,
      validation: validation,
      wasMerged: existing != null,
      hasConflict: result.hasConflict,
      conflictReasons: result.conflictReasons,
    );
  }

  /// Loads all non-expired memories.
  Future<List<CoachMemory>> loadActiveMemories(String userId) {
    return _repository.pruneExpired(userId);
  }

  /// Saves a fully resolved memory snapshot without merging again.
  Future<MemorySnapshotWriteResult> saveResolvedMemories(
    String userId,
    List<CoachMemory> memories,
  ) async {
    final errors = <String>[];
    for (final memory in memories) {
      final validation = _validator.validate(memory);
      if (validation.isValid) continue;
      errors.addAll(validation.errors);
    }

    final validation = MemoryValidationResult(
      isValid: errors.isEmpty,
      errors: List<String>.unmodifiable(errors),
    );
    if (!validation.isValid) {
      return MemorySnapshotWriteResult(saved: false, validation: validation);
    }

    await _repository.saveMemories(userId, memories);
    return MemorySnapshotWriteResult(saved: true, validation: validation);
  }

  /// Loads permanent memories only.
  Future<List<CoachMemory>> loadPermanentMemories(String userId) async {
    final memories = await loadActiveMemories(userId);
    return memories
        .where((memory) => memory.isPermanent)
        .toList(growable: false);
  }

  /// Loads temporary memories only.
  Future<List<CoachMemory>> loadTemporaryMemories(String userId) async {
    final memories = await loadActiveMemories(userId);
    return memories
        .where((memory) => memory.isTemporary)
        .toList(growable: false);
  }

  /// Deletes a memory by key.
  Future<void> deleteMemory(String userId, String key) {
    return _repository.deleteMemory(userId, key);
  }

  CoachMemory? _findByKey(List<CoachMemory> memories, String key) {
    for (final memory in memories) {
      if (memory.key == key) return memory;
    }
    return null;
  }
}
