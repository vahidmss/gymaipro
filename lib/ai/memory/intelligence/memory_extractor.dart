import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_classifier.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_confidence_engine.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_extraction_result.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_rule.dart';

/// Rule-based memory extractor.
///
/// This class does not use NLP, LLM, OpenAI, prompts, APIs, or runtime app
/// integration. It only turns text into memory candidates.
class MemoryExtractor {
  const MemoryExtractor({
    this.classifier = const MemoryClassifier(),
    this.confidenceEngine = const MemoryConfidenceEngine(),
  });

  /// Classifies input text before extraction.
  final MemoryClassifier classifier;

  /// Calculates confidence for extracted memories.
  final MemoryConfidenceEngine confidenceEngine;

  /// Extracts memory candidates from [text].
  MemoryExtractionResult extract(String text, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    final classification = classifier.classify(text);
    if (!classification.shouldStore) {
      return MemoryExtractionResult(
        memories: const <CoachMemory>[],
        reasons: classification.reasons,
        ignored: true,
        originalText: text,
      );
    }

    final memories = <CoachMemory>[
      for (final rule in classification.matchedRules)
        _memoryFromRule(rule, text, timestamp),
    ];

    return MemoryExtractionResult(
      memories: List<CoachMemory>.unmodifiable(memories),
      reasons: classification.reasons,
      ignored: false,
      originalText: text,
    );
  }

  CoachMemory _memoryFromRule(
    MemoryRule rule,
    String text,
    DateTime timestamp,
  ) {
    return CoachMemory(
      key: rule.memoryKey,
      value: text.trim(),
      category: rule.category,
      confidence: confidenceEngine.confidenceFor(rule: rule, text: text),
      importance: rule.importance,
      source: rule.source,
      createdAt: timestamp,
      updatedAt: timestamp,
      expiresAt: rule.expiresAfter == null
          ? null
          : timestamp.add(rule.expiresAfter!),
      editable: true,
      userEditable: rule.userEditable,
      aiGenerated: false,
    );
  }
}
