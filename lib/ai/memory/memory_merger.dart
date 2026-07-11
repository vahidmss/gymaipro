import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';

/// Result of merging two memory items.
class MemoryMergeResult {
  const MemoryMergeResult({
    required this.memory,
    required this.hasConflict,
    this.conflictReasons = const <String>[],
  });

  /// Merged memory.
  final CoachMemory memory;

  /// Whether the merge detected conflicting information.
  final bool hasConflict;

  /// Conflict diagnostics.
  final List<String> conflictReasons;
}

/// Merges old and new memory while preserving confidence and importance.
class MemoryMerger {
  const MemoryMerger();

  /// Merges [incoming] into [existing].
  MemoryMergeResult merge(CoachMemory existing, CoachMemory incoming) {
    if (existing.key != incoming.key) {
      throw ArgumentError('Cannot merge memories with different keys.');
    }

    final conflictReasons = _conflictReasons(existing, incoming);
    final selected = _selectPreferred(existing, incoming);
    final merged = selected.copyWith(
      createdAt: existing.createdAt,
      updatedAt: _latest(existing.updatedAt, incoming.updatedAt),
      confidence: _mergedConfidence(existing, incoming, selected),
      importance: _maxImportance(existing.importance, incoming.importance),
      expiresAt: _mergedExpiry(existing, incoming),
      clearExpiresAt: existing.expiresAt == null && incoming.expiresAt == null,
    );

    return MemoryMergeResult(
      memory: merged,
      hasConflict: conflictReasons.isNotEmpty,
      conflictReasons: List<String>.unmodifiable(conflictReasons),
    );
  }

  List<String> _conflictReasons(CoachMemory existing, CoachMemory incoming) {
    final reasons = <String>[];
    final valueChanged = existing.value.trim() != incoming.value.trim();
    if (!valueChanged) return reasons;

    if (existing.confidence >= 0.7 && incoming.confidence >= 0.7) {
      reasons.add('high_confidence_value_conflict');
    } else {
      reasons.add('value_changed');
    }
    if (existing.source != incoming.source) {
      reasons.add('source_changed');
    }
    return reasons;
  }

  CoachMemory _selectPreferred(CoachMemory existing, CoachMemory incoming) {
    if (!existing.editable) return existing;
    if (incoming.importance.rank > existing.importance.rank) return incoming;
    if (incoming.confidence > existing.confidence) return incoming;
    if (incoming.updatedAt.isAfter(existing.updatedAt)) return incoming;
    return existing;
  }

  double _mergedConfidence(
    CoachMemory existing,
    CoachMemory incoming,
    CoachMemory selected,
  ) {
    if (existing.value == incoming.value) {
      final confidence = (existing.confidence + incoming.confidence) / 2;
      return confidence.clamp(0, 1).toDouble();
    }
    return selected.confidence;
  }

  MemoryImportance _maxImportance(
    MemoryImportance first,
    MemoryImportance second,
  ) {
    return second.rank > first.rank ? second : first;
  }

  DateTime _latest(DateTime first, DateTime second) {
    return second.isAfter(first) ? second : first;
  }

  DateTime? _mergedExpiry(CoachMemory existing, CoachMemory incoming) {
    if (existing.expiresAt == null) return incoming.expiresAt;
    if (incoming.expiresAt == null) return existing.expiresAt;
    return _latest(existing.expiresAt!, incoming.expiresAt!);
  }
}
