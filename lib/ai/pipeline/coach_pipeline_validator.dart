import 'package:gymaipro/ai/pipeline/coach_pipeline_context.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_result.dart';

/// Validation result for pipeline inputs and outputs.
class CoachPipelineValidationResult {
  const CoachPipelineValidationResult({
    required this.isValid,
    this.issues = const <String>[],
  });

  final bool isValid;
  final List<String> issues;
}

/// Validates pipeline context before and after execution.
class CoachPipelineValidator {
  const CoachPipelineValidator();

  /// Validates request inputs.
  CoachPipelineValidationResult validateInput(CoachPipelineContext context) {
    final issues = <String>[];
    if (context.userId.trim().isEmpty) {
      issues.add('user_id_empty');
    }
    if (context.userMessage.trim().isEmpty) {
      issues.add('user_message_empty');
    }
    return CoachPipelineValidationResult(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }

  /// Validates the final pipeline result.
  CoachPipelineValidationResult validateResult(CoachPipelineResult result) {
    final issues = <String>[];
    if (!result.success) {
      issues.add('pipeline_failed');
    }
    if (result.context.intentIntelligence == null) {
      issues.add('intent_missing');
    }
    if (result.context.coachContext == null) {
      issues.add('coach_context_missing');
    }
    if (result.context.localSkillHandled) {
      if (result.context.skillExecutionResult == null) {
        issues.add('skill_execution_missing');
      }
      return CoachPipelineValidationResult(
        isValid: issues.isEmpty,
        issues: List<String>.unmodifiable(issues),
      );
    }
    if (result.context.decision == null) {
      issues.add('decision_missing');
    }
    if (result.context.responsePlan == null) {
      issues.add('response_plan_missing');
    }
    if (result.context.executorPreview == null) {
      issues.add('executor_preview_missing');
    }
    return CoachPipelineValidationResult(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }
}
