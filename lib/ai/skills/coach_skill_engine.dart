import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/skills/coach_skill_registry.dart';
import 'package:gymaipro/ai/skills/coach_skill_type.dart';
import 'package:gymaipro/ai/skills/skill_result.dart';

/// Determines whether a coach request can be answered locally before OpenAI.
///
/// This engine is infrastructure-only. It does not call OpenAI, APIs, prompts,
/// navigation, or UI layers.
class CoachSkillEngine {
  CoachSkillEngine({
    CoachSkillRegistry registry = const CoachSkillRegistry(),
    this.localConfidenceThreshold = 0.65,
  }) : _registry = registry;

  final CoachSkillRegistry _registry;

  /// Minimum confidence required to select a local skill.
  final double localConfidenceThreshold;

  /// Evaluates all skills for [intent] and returns a routing result.
  SkillResult evaluate({
    required CoachContext context,
    required AIIntent intent,
  }) {
    final skills = _registry.skillsForIntent(intent);
    if (skills.isEmpty) {
      return SkillResult(
        intent: intent,
        candidates: const <SkillCandidate>[],
        shouldInvokeAI: true,
        reason: 'No local skills are registered for ${intent.name}.',
      );
    }

    final candidates =
        <SkillCandidate>[
          for (final skill in skills)
            SkillCandidate(
              skill: skill,
              evaluation: skill.evaluate(context: context, intent: intent),
            ),
        ]..sort(
          (a, b) => b.evaluation.confidence.compareTo(a.evaluation.confidence),
        );

    final selected = _selectCandidate(candidates);
    if (selected == null) {
      return SkillResult(
        intent: intent,
        candidates: List<SkillCandidate>.unmodifiable(candidates),
        shouldInvokeAI: true,
        reason: 'No skill met the local confidence threshold.',
      );
    }

    final evaluation = selected.evaluation;
    final shouldInvokeAI =
        evaluation.requiresAIFallback ||
        evaluation.outcome == SkillOutcome.insufficientContext ||
        evaluation.outcome == SkillOutcome.requiresAI;

    return SkillResult(
      intent: intent,
      candidates: List<SkillCandidate>.unmodifiable(candidates),
      selectedSkill: selected,
      shouldInvokeAI: shouldInvokeAI,
      reason: shouldInvokeAI
          ? 'Selected skill ${selected.skill.id} still requires AI fallback.'
          : 'Selected skill ${selected.skill.id} can answer locally.',
    );
  }

  /// Returns the best local skill for [intent], if one is available.
  SkillCandidate? bestLocalSkill({
    required CoachContext context,
    required AIIntent intent,
  }) {
    return evaluate(context: context, intent: intent).selectedSkill;
  }

  /// Returns whether any registered skill can handle [intent] locally.
  bool canAnswerLocally({
    required CoachContext context,
    required AIIntent intent,
  }) {
    final result = evaluate(context: context, intent: intent);
    return result.hasLocalSkill && !result.shouldInvokeAI;
  }

  SkillCandidate? _selectCandidate(List<SkillCandidate> candidates) {
    for (final candidate in candidates) {
      final evaluation = candidate.evaluation;
      if (evaluation.outcome == SkillOutcome.insufficientContext) continue;
      if (evaluation.confidence < localConfidenceThreshold) continue;
      if (evaluation.outcome == SkillOutcome.handledLocally ||
          evaluation.outcome == SkillOutcome.partialLocal) {
        return candidate;
      }
    }
    return null;
  }
}
