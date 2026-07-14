import 'package:gymaipro/ai/skills/coach_skill_type.dart';

/// Capability category exposed by a coach skill.
enum SkillCapabilityKind {
  readOnlyData,
  navigationHint,
  templatedText,
  diagnosticSummary,
}

/// Metadata describing what a skill can produce without calling OpenAI.
class SkillCapability {
  const SkillCapability({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    this.outputs = const <String>[],
    this.navigationTargets = const <String>[],
  });

  /// Stable capability id.
  final String id;

  /// Human-readable capability title.
  final String title;

  /// Product description.
  final String description;

  /// Capability category.
  final SkillCapabilityKind kind;

  /// Logical outputs such as `show_program` or `show_heatmap`.
  final List<String> outputs;

  /// Future navigation targets the skill may suggest.
  final List<String> navigationTargets;
}

/// Bundles a skill type with its capability metadata.
class SkillCapabilityProfile {
  const SkillCapabilityProfile({
    required this.skillType,
    required this.capability,
    this.tags = const <String>[],
  });

  final CoachSkillType skillType;
  final SkillCapability capability;
  final List<String> tags;
}
