import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_explanation.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_reason.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_recommendation.dart';

/// User-facing output produced by a local skill execution.
class CoachSkillResponse {
  const CoachSkillResponse({
    required this.confidence,
    required this.requiresAI,
    this.message,
    this.structuredData = const <String, Object?>{},
    this.actions = const <CoachAction>[],
    this.reasons = const <SkillReason>[],
    this.explanation,
    this.recommendations = const <SkillRecommendation>[],
    this.warnings = const <String>[],
    this.nextActions = const <String>[],
  });

  /// Rendered user-facing text when the skill can answer locally.
  final String? message;

  /// Optional structured payload for future UI or navigation wiring.
  final Map<String, Object?> structuredData;

  /// Suggested coach actions for future executor integration.
  final List<CoachAction> actions;

  /// Explainable reasons behind this response.
  final List<SkillReason> reasons;

  /// Narrative explanation for the response.
  final SkillExplanation? explanation;

  /// Structured recommendations such as muscle focus or next steps.
  final List<SkillRecommendation> recommendations;

  /// Non-blocking warnings derived from restrictions or imbalance.
  final List<String> warnings;

  /// Human-readable next actions for the user.
  final List<String> nextActions;

  /// Confidence in the local response from 0 to 1.
  final double confidence;

  /// Whether the pipeline should continue to AI fallback.
  final bool requiresAI;

  /// Whether this response is complete enough to skip OpenAI.
  bool get handledLocally =>
      !requiresAI && message != null && message!.trim().isNotEmpty;
}
