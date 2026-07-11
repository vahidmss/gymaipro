import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_rule.dart';

/// Rule-based confidence calculator for memory extraction and updates.
class MemoryConfidenceEngine {
  const MemoryConfidenceEngine();

  /// Calculates confidence for an extracted memory.
  double confidenceFor({required MemoryRule rule, required String text}) {
    var confidence = rule.baseConfidence;
    final trimmed = text.trim();

    if (trimmed.length > 24) {
      confidence += 0.05;
    }
    if (_containsFirstPersonSignal(trimmed)) {
      confidence += 0.08;
    }
    if (trimmed.endsWith('?')) {
      confidence -= 0.12;
    }

    return confidence.clamp(0, 1).toDouble();
  }

  /// Adjusts confidence after resolving a duplicate or conflict.
  double mergedConfidence(CoachMemory existing, CoachMemory incoming) {
    if (existing.value.trim() == incoming.value.trim()) {
      return ((existing.confidence + incoming.confidence) / 2 + 0.05)
          .clamp(0, 1)
          .toDouble();
    }
    return incoming.confidence > existing.confidence
        ? incoming.confidence
        : existing.confidence * 0.92;
  }

  bool _containsFirstPersonSignal(String text) {
    return text.contains('من ') ||
        text.contains('هدفم') ||
        text.contains('میخوام') ||
        text.contains('می‌خوام') ||
        text.contains('دارم');
  }
}
