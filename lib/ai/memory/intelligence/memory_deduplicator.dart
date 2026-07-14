import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_conflict_resolver.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_extraction_reason.dart';
import 'package:gymaipro/ai/memory/memory_merger.dart';

/// Result of deduplicating extracted memory candidates.
class MemoryDeduplicationResult {
  const MemoryDeduplicationResult({
    required this.memories,
    required this.reasons,
    required this.duplicateCount,
    required this.conflictCount,
  });

  /// Full deduplicated memory snapshot.
  final List<CoachMemory> memories;

  /// Reasons emitted during deduplication.
  final Set<MemoryExtractionReason> reasons;

  /// Number of duplicates merged.
  final int duplicateCount;

  /// Number of conflicts detected.
  final int conflictCount;
}

/// Deduplicates memory candidates against existing memories.
class MemoryDeduplicator {
  const MemoryDeduplicator({
    this.merger = const MemoryMerger(),
    this.conflictResolver = const MemoryConflictResolver(),
  });

  /// Memory merger.
  final MemoryMerger merger;

  /// Conflict resolver.
  final MemoryConflictResolver conflictResolver;

  /// Deduplicates [incoming] memories against [existing].
  MemoryDeduplicationResult deduplicate({
    required List<CoachMemory> existing,
    required List<CoachMemory> incoming,
  }) {
    final byKey = <String, CoachMemory>{
      for (final memory in existing) memory.key: memory,
    };
    final reasons = <MemoryExtractionReason>{};
    var duplicateCount = 0;
    var conflictCount = 0;

    for (final candidate in incoming) {
      final current = byKey[candidate.key];
      if (current == null) {
        byKey[candidate.key] = candidate;
        continue;
      }

      duplicateCount++;
      reasons.add(MemoryExtractionReason.duplicateDetected);
      final mergeResult = merger.merge(current, candidate);
      if (mergeResult.hasConflict) {
        conflictCount++;
        reasons.add(MemoryExtractionReason.conflictDetected);
      }
      final resolution = conflictResolver.resolve(
        existing: current,
        incoming: candidate,
        mergeResult: mergeResult,
      );
      byKey[candidate.key] = resolution.memory;
    }

    return MemoryDeduplicationResult(
      memories: List<CoachMemory>.unmodifiable(byKey.values),
      reasons: Set<MemoryExtractionReason>.unmodifiable(reasons),
      duplicateCount: duplicateCount,
      conflictCount: conflictCount,
    );
  }
}
