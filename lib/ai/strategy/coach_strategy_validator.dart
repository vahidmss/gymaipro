import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/strategy/coach_strategy.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_type.dart';

/// Validation result for strategy inputs or outputs.
class CoachStrategyValidationResult {
  const CoachStrategyValidationResult({
    required this.isValid,
    this.issues = const <String>[],
  });

  final bool isValid;
  final List<String> issues;
}

/// Validates strategy engine inputs and assembled strategies.
///
/// The validator is deterministic and does not fetch data or call services.
class CoachStrategyValidator {
  const CoachStrategyValidator();

  /// Validates the inputs required to build a strategy.
  CoachStrategyValidationResult validateInputs({
    required CoachContext context,
    required KnowledgeNode knowledgeNode,
    required CoachDecision decision,
  }) {
    final issues = <String>[];

    if (knowledgeNode.id.trim().isEmpty) {
      issues.add('Knowledge node id must not be empty.');
    }
    if (decision.confidence < 0 || decision.confidence > 1) {
      issues.add('Decision confidence must be between 0 and 1.');
    }
    if (context.metadata.confidence < 0 || context.metadata.confidence > 1) {
      issues.add('Context metadata confidence must be between 0 and 1.');
    }
    if (context.intent != knowledgeNode.intent &&
        knowledgeNode.intent != null) {
      issues.add(
        'Context intent ${context.intent.name} does not match '
        'knowledge node intent ${knowledgeNode.intent!.name}.',
      );
    }

    return CoachStrategyValidationResult(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }

  /// Validates an assembled [CoachStrategy].
  CoachStrategyValidationResult validateStrategy(CoachStrategy strategy) {
    final issues = <String>[];

    if (strategy.primaryGoal.trim().isEmpty) {
      issues.add('primaryGoal must not be empty.');
    }
    if (strategy.confidence < 0 || strategy.confidence > 1) {
      issues.add('confidence must be between 0 and 1.');
    }
    if (!strategy.requiresAI && strategy.nextAction == CoachAction.callOpenAI) {
      issues.add('nextAction cannot be callOpenAI when requiresAI is false.');
    }
    if (strategy.requiresFollowUp &&
        strategy.nextAction != CoachAction.followUp) {
      issues.add(
        'nextAction should be followUp when requiresFollowUp is true.',
      );
    }
    if (strategy.blockedActions
        .intersection(strategy.availableActions)
        .isNotEmpty) {
      issues.add('blockedActions and availableActions must not overlap.');
    }
    if (strategy.strategyType == CoachStrategyType.safetyGate &&
        strategy.safetyFlags.isEmpty) {
      issues.add(
        'safetyGate strategies must include at least one safety flag.',
      );
    }

    return CoachStrategyValidationResult(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }
}
