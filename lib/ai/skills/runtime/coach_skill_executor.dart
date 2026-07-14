import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/skills/coach_skill.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_context.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_execution_result.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/ai/skills/skill_result.dart';

/// Executes runnable coach skills after evaluation.
class CoachSkillExecutor {
  const CoachSkillExecutor();

  /// Executes the selected skill when local handling is possible.
  CoachSkillExecutionResult? execute({
    required CoachContext context,
    required AIIntent intent,
    required SkillResult skillResult,
    CoachPipelineMode pipelineMode = CoachPipelineMode.runtime,
  }) {
    if (!coachPipelineV2Active(pipelineMode)) return null;
    if (skillResult.shouldInvokeAI || skillResult.selectedSkill == null) {
      return null;
    }

    final skill = skillResult.selectedSkill!.skill;
    if (skill is! CoachRunnableSkill) return null;

    final stopwatch = Stopwatch()..start();
    try {
      final response = skill.execute(
        context: context,
        intent: intent,
      );
      stopwatch.stop();
      return CoachSkillExecutionResult(
        skillId: skill.id,
        response: response,
        executionTime: stopwatch.elapsed,
        success: true,
      );
    } on Object {
      stopwatch.stop();
      return CoachSkillExecutionResult(
        skillId: skill.id,
        response: const CoachSkillResponse(
          confidence: 0,
          requiresAI: true,
        ),
        executionTime: stopwatch.elapsed,
        success: false,
      );
    }
  }

  /// Convenience wrapper that accepts a full execution context.
  CoachSkillExecutionResult? executeFromContext(
    CoachSkillExecutionContext executionContext, {
    CoachPipelineMode pipelineMode = CoachPipelineMode.runtime,
  }) {
    return execute(
      context: executionContext.coachContext,
      intent: executionContext.intent,
      skillResult: executionContext.skillResult,
      pipelineMode: pipelineMode,
    );
  }
}
