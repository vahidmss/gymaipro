import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/intelligence/memory_extraction_reason.dart';

/// Result of extracting memory candidates from user text.
class MemoryExtractionResult {
  const MemoryExtractionResult({
    required this.memories,
    required this.reasons,
    required this.ignored,
    required this.originalText,
  });

  /// Extracted memory candidates. They are not persisted by extraction.
  final List<CoachMemory> memories;

  /// Reasons emitted by classifier and extractor.
  final Set<MemoryExtractionReason> reasons;

  /// Whether the input was ignored as not memory-worthy.
  final bool ignored;

  /// Original user text.
  final String originalText;

  /// Whether any memory candidates were extracted.
  bool get hasMemories => memories.isNotEmpty;
}
