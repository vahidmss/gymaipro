import 'package:gymaipro/ai/prompt/planner/coach_prompt_plan.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_section.dart';

/// Validation result for prompt plans.
class CoachPromptValidationResult {
  const CoachPromptValidationResult({
    required this.isValid,
    this.issues = const <String>[],
  });

  final bool isValid;
  final List<String> issues;
}

/// Validates critical prompt planning invariants.
class CoachPromptValidator {
  const CoachPromptValidator();

  CoachPromptValidationResult validate(CoachPromptPlan plan) {
    final issues = <String>[];
    var blocking = false;
    if (!_hasType(plan, CoachPromptSectionType.system)) {
      issues.add('System section is required.');
      blocking = true;
    }
    if (!_hasType(plan, CoachPromptSectionType.currentQuestion)) {
      issues.add('Current question section is required.');
      blocking = true;
    }
    if (plan.budget.remainingTokens < 0) {
      issues.add('Prompt token budget is negative; fallback kept critical sections.');
    }
    return CoachPromptValidationResult(
      isValid: !blocking,
      issues: List<String>.unmodifiable(issues),
    );
  }

  bool _hasType(CoachPromptPlan plan, CoachPromptSectionType type) {
    return plan.sections.any((section) {
      return section.type == type && !section.removed;
    });
  }
}
