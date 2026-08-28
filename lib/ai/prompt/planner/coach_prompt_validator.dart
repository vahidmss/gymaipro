import 'package:gymaipro/ai/prompt/planner/coach_prompt_plan.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_section.dart';
import 'package:gymaipro/features/product_experience/domain/coach_decision_lock.dart';
import 'package:gymaipro/features/product_experience/domain/coach_user_card.dart';

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
    if (!plan.sections.any(
      (s) => s.id == CoachUserCard.sectionId && !s.removed,
    )) {
      issues.add('User card section is required.');
      blocking = true;
    }
    if (plan.budget.remainingTokens < 0) {
      issues.add(
        'Prompt token budget is negative; fallback kept critical sections.',
      );
    }

    final system = plan.sections.where(
      (s) => s.type == CoachPromptSectionType.system && !s.removed,
    );
    if (system.isNotEmpty) {
      final content = system.first.content.toString();
      if (!CoachDecisionLock.systemMentionsNumericLock(content)) {
        issues.add(
          'System section must lock numeric decisions (cite decisions.lock only).',
        );
        blocking = true;
      }
    }

    final lock = plan.sections.where(
      (s) => s.id == CoachDecisionLock.sectionId && !s.removed,
    );
    if (lock.isNotEmpty) {
      final content = lock.first.content;
      if (content is Map && content.isEmpty) {
        issues.add('decisions.lock section is empty.');
        blocking = true;
      }
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
