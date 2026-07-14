import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_priority.dart';
import 'package:gymaipro/ai/prompt/prompt_section.dart';

/// Section type planned before prompt package rendering.
enum CoachPromptSectionType {
  system,
  knowledge,
  memory,
  conversation,
  userProfile,
  goals,
  restrictions,
  equipment,
  workout,
  heatmap,
  state,
  currentQuestion,
  strategy,
}

/// A token-aware section selected by the prompt planner.
class CoachPromptSection {
  const CoachPromptSection({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.priority,
    required this.estimatedTokens,
    this.providerKey,
    this.required = false,
    this.compressed = false,
    this.removed = false,
    this.reason,
  });

  final String id;
  final String title;
  final CoachPromptSectionType type;
  final Object content;
  final CoachPromptPriority priority;
  final int estimatedTokens;
  final AIContextProviderKey? providerKey;
  final bool required;
  final bool compressed;
  final bool removed;
  final String? reason;

  CoachPromptSection copyWith({
    Object? content,
    CoachPromptPriority? priority,
    int? estimatedTokens,
    bool? required,
    bool? compressed,
    bool? removed,
    String? reason,
  }) {
    return CoachPromptSection(
      id: id,
      title: title,
      type: type,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      estimatedTokens: estimatedTokens ?? this.estimatedTokens,
      providerKey: providerKey,
      required: required ?? this.required,
      compressed: compressed ?? this.compressed,
      removed: removed ?? this.removed,
      reason: reason ?? this.reason,
    );
  }

  /// Converts a planned section into the existing prompt package section.
  PromptSection toPromptSection() {
    return PromptSection(
      id: id,
      title: title,
      type: _promptType(type),
      content: content,
      providerKey: providerKey,
      required: required,
      priority: _contextPriority(priority),
      estimatedTokens: estimatedTokens,
    );
  }

  PromptSectionType _promptType(CoachPromptSectionType type) {
    switch (type) {
      case CoachPromptSectionType.system:
        return PromptSectionType.system;
      case CoachPromptSectionType.knowledge:
        return PromptSectionType.knowledge;
      case CoachPromptSectionType.memory:
        return PromptSectionType.memory;
      case CoachPromptSectionType.conversation:
        return PromptSectionType.conversation;
      case CoachPromptSectionType.userProfile:
        return PromptSectionType.profile;
      case CoachPromptSectionType.goals:
        return PromptSectionType.goals;
      case CoachPromptSectionType.restrictions:
        return PromptSectionType.restrictions;
      case CoachPromptSectionType.equipment:
        return PromptSectionType.equipment;
      case CoachPromptSectionType.workout:
        return PromptSectionType.workout;
      case CoachPromptSectionType.heatmap:
        return PromptSectionType.heatmap;
      case CoachPromptSectionType.state:
        return PromptSectionType.state;
      case CoachPromptSectionType.currentQuestion:
        return PromptSectionType.currentQuestion;
      case CoachPromptSectionType.strategy:
        return PromptSectionType.strategy;
    }
  }

  ContextPriority _contextPriority(CoachPromptPriority priority) {
    switch (priority) {
      case CoachPromptPriority.critical:
        return ContextPriority.required;
      case CoachPromptPriority.high:
        return ContextPriority.high;
      case CoachPromptPriority.medium:
        return ContextPriority.medium;
      case CoachPromptPriority.low:
        return ContextPriority.low;
    }
  }
}
