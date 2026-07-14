/// Actionable recommendation produced by skill intelligence.
class SkillRecommendation {
  const SkillRecommendation({
    required this.title,
    required this.detail,
    this.muscleKey,
    this.priority = 2,
  });

  /// Short recommendation label.
  final String title;

  /// Expanded recommendation detail.
  final String detail;

  /// Optional muscle target key when the recommendation is muscle-specific.
  final String? muscleKey;

  /// Lower numbers indicate higher priority.
  final int priority;
}
