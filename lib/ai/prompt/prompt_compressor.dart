import 'package:gymaipro/ai/prompt/prompt_budget.dart';
import 'package:gymaipro/ai/prompt/prompt_section.dart';

/// Result of a prompt compression pass.
class PromptCompressionResult {
  const PromptCompressionResult({
    required this.sections,
    required this.compressed,
    required this.notes,
  });

  /// Sections after compression.
  final List<PromptSection> sections;

  /// Whether compression changed the sections.
  final bool compressed;

  /// Diagnostic notes.
  final List<String> notes;
}

/// Placeholder compressor for future prompt rendering.
///
/// Phase 1 of prompt architecture does not compress content. It only exposes
/// the contract so future token-aware strategies can be added safely.
class PromptCompressor {
  const PromptCompressor();

  /// Returns sections unchanged for now.
  PromptCompressionResult compress({
    required List<PromptSection> sections,
    required PromptBudget budget,
  }) {
    return PromptCompressionResult(
      sections: List<PromptSection>.unmodifiable(sections),
      compressed: false,
      notes: const <String>[
        'PromptCompressor is structural only; no compression applied.',
      ],
    );
  }
}
