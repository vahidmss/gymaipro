import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/planner/coach_response_plan.dart';

/// Execution target selected from a response plan.
enum CoachExecutionTarget { local, openAI, navigation, followUp, error }

/// Dry-run execution preview for future integrations.
class CoachExecutionPreview {
  const CoachExecutionPreview({
    required this.plan,
    required this.target,
    required this.wouldExecute,
    required this.description,
  });

  /// Original plan.
  final CoachResponsePlan plan;

  /// Category of future execution.
  final CoachExecutionTarget target;

  /// Always false in phase 4 because no execution is allowed yet.
  final bool wouldExecute;

  /// Diagnostic description of what a future executor would do.
  final String description;
}

/// Placeholder executor for Coach v2 plans.
///
/// Phase 4 never executes the plan. It only classifies whether future
/// integration would be local, OpenAI-backed, navigation-backed, follow-up, or
/// error handling.
class CoachExecutor {
  const CoachExecutor();

  /// Returns a dry-run preview without executing anything.
  CoachExecutionPreview preview(CoachResponsePlan plan) {
    final target = _targetFor(plan.action);
    return CoachExecutionPreview(
      plan: plan,
      target: target,
      wouldExecute: false,
      description: 'Prepared ${plan.action.wireName} for ${target.name}.',
    );
  }

  CoachExecutionTarget _targetFor(CoachAction action) {
    switch (action) {
      case CoachAction.callOpenAI:
        return CoachExecutionTarget.openAI;
      case CoachAction.localResponse:
        return CoachExecutionTarget.local;
      case CoachAction.followUp:
        return CoachExecutionTarget.followUp;
      case CoachAction.showProgram:
      case CoachAction.showHeatmap:
      case CoachAction.showProgress:
      case CoachAction.showRecovery:
      case CoachAction.showChat:
        return CoachExecutionTarget.navigation;
      case CoachAction.error:
        return CoachExecutionTarget.error;
    }
  }
}
