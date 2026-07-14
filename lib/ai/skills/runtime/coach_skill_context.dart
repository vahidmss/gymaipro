import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/skills/skill_result.dart';

/// Execution context passed into a runnable coach skill.
class CoachSkillExecutionContext {
  const CoachSkillExecutionContext({
    required this.coachContext,
    required this.intent,
    required this.skillResult,
  });

  /// Assembled coach context for this request.
  final CoachContext coachContext;

  /// Resolved intent for this request.
  final AIIntent intent;

  /// Skill evaluation result selected for execution.
  final SkillResult skillResult;

  /// Selected skill candidate, if any.
  SkillCandidate? get selectedSkill => skillResult.selectedSkill;
}
