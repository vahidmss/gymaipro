import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/planner/response_priority.dart';
import 'package:gymaipro/ai/strategy/coach_strategy.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_builder.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_reason.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_type.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_validator.dart';

/// Result returned by [CoachStrategyEngine].
class CoachStrategyResult {
  const CoachStrategyResult({
    required this.strategy,
    required this.inputValidation,
    required this.outputValidation,
  });

  /// Assembled strategy package.
  final CoachStrategy strategy;

  /// Validation outcome for engine inputs.
  final CoachStrategyValidationResult inputValidation;

  /// Validation outcome for the assembled strategy.
  final CoachStrategyValidationResult outputValidation;

  /// Whether both input and output validation passed.
  bool get isValid => inputValidation.isValid && outputValidation.isValid;
}

/// First layer of the Coach Intelligence system.
///
/// Transforms [CoachDecision] into a richer [CoachStrategy] using
/// [CoachContext] and [CoachKnowledgeResult]. This engine is infrastructure-only and
/// is not connected to runtime, prompts, OpenAI, UI, or navigation.
class CoachStrategyEngine {
  CoachStrategyEngine({
    CoachStrategyBuilder builder = const CoachStrategyBuilder(),
    CoachStrategyValidator validator = const CoachStrategyValidator(),
  }) : _builder = builder,
       _validator = validator;

  final CoachStrategyBuilder _builder;
  final CoachStrategyValidator _validator;

  /// Builds a data-only strategy from coach inputs.
  CoachStrategyResult buildStrategy({
    required CoachContext context,
    required CoachKnowledgeResult knowledgeResult,
    required CoachDecision decision,
  }) {
    final knowledgeNode = knowledgeResult.selectedNode;
    final inputValidation = _validator.validateInputs(
      context: context,
      knowledgeNode: knowledgeNode,
      decision: decision,
    );

    final strategy = _builder.build(
      context: context,
      knowledgeNode: knowledgeNode,
      decision: decision,
    );

    final outputValidation = _validator.validateStrategy(strategy);

    if (!outputValidation.isValid) {
      return CoachStrategyResult(
        strategy: _fallbackStrategy(
          knowledgeNode: knowledgeNode,
          decision: decision,
          issues: outputValidation.issues,
        ),
        inputValidation: inputValidation,
        outputValidation: outputValidation,
      );
    }

    return CoachStrategyResult(
      strategy: strategy,
      inputValidation: inputValidation,
      outputValidation: outputValidation,
    );
  }

  /// Convenience accessor that returns only the assembled strategy.
  CoachStrategy build({
    required CoachContext context,
    required CoachKnowledgeResult knowledgeResult,
    required CoachDecision decision,
  }) {
    return buildStrategy(
      context: context,
      knowledgeResult: knowledgeResult,
      decision: decision,
    ).strategy;
  }

  CoachStrategy _fallbackStrategy({
    required KnowledgeNode knowledgeNode,
    required CoachDecision decision,
    required List<String> issues,
  }) {
    return CoachStrategy(
      primaryGoal: knowledgeNode.title,
      strategyType: CoachStrategyType.errorFallback,
      requiresAI: false,
      requiresFollowUp: decision.requiresFollowUp,
      recommendationType: CoachRecommendationType.defer,
      tone: CoachStrategyTone.direct,
      priority: ResponsePriority.high,
      confidence: decision.confidence.clamp(0, 1),
      reasoning: const <CoachStrategyReason>{
        CoachStrategyReason.validationBlocked,
      },
      nextAction: CoachAction.error,
      safetyFlags: const <CoachSafetyFlag>{},
      blockedActions: Set<CoachAction>.unmodifiable(
        CoachAction.values.where((action) => action != CoachAction.error),
      ),
      availableActions: const <CoachAction>{CoachAction.error},
      notes: List<String>.unmodifiable(<String>[
        'Strategy validation failed; returned safe fallback.',
        ...issues,
      ]),
    );
  }
}
