import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/skills/coach_skill.dart';

/// Candidate skill considered by the coach skill engine.
class SkillCandidate {
  const SkillCandidate({required this.skill, required this.evaluation});

  final CoachSkill skill;
  final SkillEvaluation evaluation;
}

/// Result returned by the Coach Skill Engine.
class SkillResult {
  const SkillResult({
    required this.intent,
    required this.candidates,
    required this.shouldInvokeAI,
    this.selectedSkill,
    this.reason,
  });

  /// Resolved intent for this evaluation.
  final AIIntent intent;

  /// All skill candidates evaluated for the intent.
  final List<SkillCandidate> candidates;

  /// Best local-capable skill, if any.
  final SkillCandidate? selectedSkill;

  /// Whether the pipeline should continue to OpenAI.
  final bool shouldInvokeAI;

  /// Diagnostic reason for the routing decision.
  final String? reason;

  bool get hasLocalSkill => selectedSkill != null;
}
