import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_confidence_engine.dart';
import 'package:gymaipro/ai/memory/memory_merger.dart';

/// Resolution strategy used for memory conflicts.
enum MemoryConflictResolutionStrategy {
  keepExisting,
  useIncoming,
  merge,
  requireUserConfirmation,
}

/// Conflict resolution result.
class MemoryConflictResolution {
  const MemoryConflictResolution({
    required this.memory,
    required this.strategy,
    required this.reasons,
  });

  /// Resolved memory.
  final CoachMemory memory;

  /// Strategy used to resolve the conflict.
  final MemoryConflictResolutionStrategy strategy;

  /// Diagnostic reasons.
  final List<String> reasons;
}

/// Resolves conflicts detected by [MemoryMerger].
class MemoryConflictResolver {
  const MemoryConflictResolver({
    this.confidenceEngine = const MemoryConfidenceEngine(),
  });

  /// Confidence helper.
  final MemoryConfidenceEngine confidenceEngine;

  /// Resolves a merge conflict without asking the user yet.
  MemoryConflictResolution resolve({
    required CoachMemory existing,
    required CoachMemory incoming,
    required MemoryMergeResult mergeResult,
  }) {
    if (!mergeResult.hasConflict) {
      return MemoryConflictResolution(
        memory: mergeResult.memory,
        strategy: MemoryConflictResolutionStrategy.merge,
        reasons: mergeResult.conflictReasons,
      );
    }

    if (!existing.editable) {
      return MemoryConflictResolution(
        memory: existing,
        strategy: MemoryConflictResolutionStrategy.keepExisting,
        reasons: mergeResult.conflictReasons,
      );
    }

    final confidenceGap = (incoming.confidence - existing.confidence).abs();
    if (confidenceGap < 0.15 && existing.confidence >= 0.7) {
      return MemoryConflictResolution(
        memory: existing,
        strategy: MemoryConflictResolutionStrategy.requireUserConfirmation,
        reasons: mergeResult.conflictReasons,
      );
    }

    final selected = incoming.confidence > existing.confidence
        ? incoming
        : existing;
    return MemoryConflictResolution(
      memory: selected.copyWith(
        confidence: confidenceEngine.mergedConfidence(existing, incoming),
        updatedAt: incoming.updatedAt.isAfter(existing.updatedAt)
            ? incoming.updatedAt
            : existing.updatedAt,
      ),
      strategy: selected == incoming
          ? MemoryConflictResolutionStrategy.useIncoming
          : MemoryConflictResolutionStrategy.keepExisting,
      reasons: mergeResult.conflictReasons,
    );
  }
}
