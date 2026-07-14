import 'package:gymaipro/ai/prompt/planner/coach_prompt_budget.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_priority.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_section.dart';

/// Result of optimizing planned prompt sections.
class CoachPromptOptimizationResult {
  const CoachPromptOptimizationResult({
    required this.sections,
    required this.removedSections,
    required this.compressedSections,
    required this.warnings,
  });

  final List<CoachPromptSection> sections;
  final List<CoachPromptSection> removedSections;
  final List<CoachPromptSection> compressedSections;
  final List<String> warnings;
}

/// Rule-based prompt optimizer.
class CoachPromptOptimizer {
  const CoachPromptOptimizer();

  CoachPromptOptimizationResult optimize({
    required List<CoachPromptSection> sections,
    required CoachPromptBudget budget,
  }) {
    final working = _sortSections(sections);
    final removed = <CoachPromptSection>[];
    final compressed = <CoachPromptSection>[];
    final warnings = <String>[];

    if (_tokenTotal(working) > budget.availablePromptTokens) {
      _compressType(
        working,
        compressed,
        CoachPromptSectionType.conversation,
        0.45,
        'Compressed conversation history before lower-priority removals.',
      );
    }

    if (_tokenTotal(working) > budget.availablePromptTokens) {
      _removeType(
        working,
        removed,
        CoachPromptSectionType.heatmap,
        'Removed heatmap because prompt budget was low.',
      );
    }

    if (_tokenTotal(working) > budget.availablePromptTokens) {
      _compressType(
        working,
        compressed,
        CoachPromptSectionType.workout,
        0.55,
        'Compressed workout history because prompt budget was low.',
      );
    }

    if (_tokenTotal(working) > budget.availablePromptTokens) {
      _compressMemory(working, compressed);
    }

    while (_tokenTotal(working) > budget.availablePromptTokens) {
      final removableIndex = working.lastIndexWhere(
        (section) => !section.required && section.priority.rank < 3,
      );
      if (removableIndex < 0) break;
      final section = working.removeAt(removableIndex).copyWith(
        removed: true,
        reason: 'Removed low-priority section to fit prompt budget.',
      );
      removed.add(section);
    }

    if (_tokenTotal(working) > budget.availablePromptTokens) {
      warnings.add(
        'Prompt budget exceeded after optimization; critical sections were kept.',
      );
    }

    return CoachPromptOptimizationResult(
      sections: List<CoachPromptSection>.unmodifiable(_sortSections(working)),
      removedSections: List<CoachPromptSection>.unmodifiable(removed),
      compressedSections: List<CoachPromptSection>.unmodifiable(compressed),
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  List<CoachPromptSection> _sortSections(List<CoachPromptSection> sections) {
    return List<CoachPromptSection>.from(sections)
      ..sort((a, b) {
        final priority = b.priority.rank.compareTo(a.priority.rank);
        if (priority != 0) return priority;
        return a.id.compareTo(b.id);
      });
  }

  void _removeType(
    List<CoachPromptSection> sections,
    List<CoachPromptSection> removed,
    CoachPromptSectionType type,
    String reason,
  ) {
    final indexes = <int>[];
    for (var index = 0; index < sections.length; index++) {
      final section = sections[index];
      if (section.type == type && !section.required) indexes.add(index);
    }
    for (final index in indexes.reversed) {
      removed.add(
        sections.removeAt(index).copyWith(removed: true, reason: reason),
      );
    }
  }

  void _compressType(
    List<CoachPromptSection> sections,
    List<CoachPromptSection> compressed,
    CoachPromptSectionType type,
    double factor,
    String reason,
  ) {
    for (var index = 0; index < sections.length; index++) {
      final section = sections[index];
      if (section.type != type || section.compressed) continue;
      final replacement = section.copyWith(
        content: _compressedContent(section.content),
        estimatedTokens: (section.estimatedTokens * factor).round(),
        compressed: true,
        reason: reason,
      );
      sections[index] = replacement;
      compressed.add(replacement);
    }
  }

  void _compressMemory(
    List<CoachPromptSection> sections,
    List<CoachPromptSection> compressed,
  ) {
    for (var index = 0; index < sections.length; index++) {
      final section = sections[index];
      if (section.type != CoachPromptSectionType.memory || section.compressed) {
        continue;
      }
      final content = section.content;
      Object nextContent = content;
      if (content is List<Object?> && content.length > 3) {
        nextContent = content.take(3).toList(growable: false);
      }
      final replacement = section.copyWith(
        content: nextContent,
        estimatedTokens: (section.estimatedTokens * 0.5).round(),
        compressed: true,
        reason: 'Kept only the most important memory items.',
      );
      sections[index] = replacement;
      compressed.add(replacement);
    }
  }

  Object _compressedContent(Object content) {
    if (content is String) {
      if (content.length <= 160) return content;
      return '${content.substring(0, 160)}...';
    }
    if (content is Map<String, Object?>) {
      return <String, Object?>{
        'summary': content.entries.take(4).map((entry) {
          return '${entry.key}: ${entry.value}';
        }).join(' | '),
      };
    }
    if (content is Iterable<Object?>) {
      return content.take(4).toList(growable: false);
    }
    return content;
  }

  int _tokenTotal(List<CoachPromptSection> sections) {
    return sections.fold<int>(
      0,
      (total, section) => total + section.estimatedTokens,
    );
  }
}
