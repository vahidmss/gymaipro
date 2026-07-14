import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';

/// Result of executing one local coach skill.
class CoachSkillExecutionResult {
  const CoachSkillExecutionResult({
    required this.skillId,
    required this.response,
    required this.executionTime,
    required this.success,
  });

  /// Stable id of the executed skill.
  final String skillId;

  /// Skill response payload.
  final CoachSkillResponse response;

  /// Wall-clock execution time for the skill runtime.
  final Duration executionTime;

  /// Whether execution completed without runtime errors.
  final bool success;

  /// Whether the skill produced a complete local answer.
  bool get handledLocally => success && response.handledLocally;
}
