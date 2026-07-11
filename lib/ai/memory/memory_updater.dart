import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';

/// Request for creating or updating a memory.
class MemoryUpdateRequest {
  const MemoryUpdateRequest({
    required this.key,
    required this.value,
    required this.category,
    required this.source,
    this.confidence = 0.7,
    this.importance = MemoryImportance.medium,
    this.expiresAt,
    this.editable = true,
    this.userEditable = true,
    this.aiGenerated = false,
  });

  final String key;
  final String value;
  final MemoryCategory category;
  final MemorySource source;
  final double confidence;
  final MemoryImportance importance;
  final DateTime? expiresAt;
  final bool editable;
  final bool userEditable;
  final bool aiGenerated;
}

/// Converts update requests into timestamped memory models.
class MemoryUpdater {
  const MemoryUpdater();

  /// Builds a new memory from an update request.
  CoachMemory createMemory(MemoryUpdateRequest request, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    return CoachMemory(
      key: request.key,
      value: request.value,
      category: request.category,
      confidence: request.confidence,
      importance: request.importance,
      source: request.source,
      createdAt: timestamp,
      updatedAt: timestamp,
      expiresAt: request.expiresAt,
      editable: request.editable,
      userEditable: request.userEditable,
      aiGenerated: request.aiGenerated,
    );
  }

  /// Applies an update to an existing memory while preserving creation time.
  CoachMemory updateMemory(
    CoachMemory existing,
    MemoryUpdateRequest request, {
    DateTime? now,
  }) {
    return existing.copyWith(
      value: request.value,
      category: request.category,
      confidence: request.confidence,
      importance: request.importance,
      source: request.source,
      updatedAt: now ?? DateTime.now(),
      expiresAt: request.expiresAt,
      clearExpiresAt: request.expiresAt == null,
      editable: request.editable,
      userEditable: request.userEditable,
      aiGenerated: request.aiGenerated,
    );
  }
}
