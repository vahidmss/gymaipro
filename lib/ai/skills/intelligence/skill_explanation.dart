/// Narrative explanation for why a skill produced its response.
class SkillExplanation {
  const SkillExplanation({
    required this.summary,
    this.bullets = const <String>[],
  });

  /// One-line explanation summary.
  final String summary;

  /// Supporting bullet points for explainability.
  final List<String> bullets;
}
