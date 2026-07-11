import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/coach/coach_router.dart';
import 'package:gymaipro/ai/coach/coach_validator.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_engine.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';
import 'package:gymaipro/ai/planner/coach_response_plan.dart';

/// Coordinates intent selection, validation, and route decision.
///
/// The brain only consumes [CoachContext] and returns routing decisions.
class CoachBrain {
  CoachBrain({
    AIContextEngine? contextEngine,
    CoachValidator validator = const CoachValidator(),
    CoachRouter router = const CoachRouter(),
  }) : _contextEngine = contextEngine ?? AIContextEngine(),
       _validator = validator,
       _router = router;

  final AIContextEngine _contextEngine;
  final CoachValidator _validator;
  final CoachRouter _router;

  /// Resolves the intent, validates available context, and returns a decision.
  CoachDecision decide({
    AIIntent? intent,
    String? currentQuestion,
    CoachContext? context,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final effectiveContext = context ?? CoachContext.empty();
    final selection = _contextEngine.selectProvidersForQuestion(
      intent: intent,
      currentQuestion: currentQuestion,
      metadata: metadata,
    );
    return decideForSelection(
      providerSelection: selection,
      context: effectiveContext,
    );
  }

  /// Resolves the intent and returns an integration-ready response plan.
  CoachResponsePlan plan({
    AIIntent? intent,
    String? currentQuestion,
    CoachContext? context,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final effectiveContext = context ?? CoachContext.empty();
    final selection = _contextEngine.selectProvidersForQuestion(
      intent: intent,
      currentQuestion: currentQuestion,
      metadata: metadata,
    );
    return planForSelection(
      providerSelection: selection,
      context: effectiveContext,
    );
  }

  /// Runs validation and routing for an already-selected provider set.
  CoachDecision decideForSelection({
    required AIContextProviderSelection providerSelection,
    required CoachContext context,
  }) {
    final validationDecision = _validator.validate(
      intentDefinition: providerSelection.intentDefinition,
      providerSelection: providerSelection,
      context: context,
    );

    return _router.route(
      intentDefinition: providerSelection.intentDefinition,
      providerSelection: providerSelection,
      validationDecision: validationDecision,
    );
  }

  /// Converts a coach decision into a descriptive response plan.
  CoachResponsePlan planForSelection({
    required AIContextProviderSelection providerSelection,
    required CoachContext context,
  }) {
    final decision = decideForSelection(
      providerSelection: providerSelection,
      context: context,
    );
    return CoachResponsePlan.fromDecision(
      decision: decision,
      intentDefinition: providerSelection.intentDefinition,
      providerSelection: providerSelection,
    );
  }
}
