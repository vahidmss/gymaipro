import 'package:gymaipro/ai/context/context_models.dart';

/// Type of structured data included in a prompt package.
enum PromptSectionType {
  intent,
  currentQuestion,
  profile,
  goals,
  workout,
  heatmap,
  equipment,
  restrictions,
  preferences,
  memory,
  apiUsage,
  recovery,
  knowledge,
  notes,
}

/// One structured section inside a future prompt package.
///
/// This is a data model only. It is not rendered into any existing prompt.
class PromptSection {
  const PromptSection({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.providerKey,
    required this.required,
    required this.priority,
    required this.estimatedTokens,
  });

  /// Stable section id.
  final String id;

  /// Human-readable section title.
  final String title;

  /// Section type.
  final PromptSectionType type;

  /// Structured section content for future prompt rendering.
  final Object content;

  /// Context provider key represented by this section.
  final AIContextProviderKey? providerKey;

  /// Whether the section satisfies required knowledge.
  final bool required;

  /// Selection priority.
  final ContextPriority priority;

  /// Estimated token cost for future prompt rendering.
  final int estimatedTokens;
}
