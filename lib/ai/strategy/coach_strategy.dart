import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/planner/response_priority.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_reason.dart';
import 'package:gymaipro/ai/strategy/coach_strategy_type.dart';

/// Immutable strategy package produced from coach context, knowledge, and
/// routing decisions.
///
/// This object is descriptive only. It does not call OpenAI, build prompts,
/// navigate, or change existing runtime behavior.
class CoachStrategy {
  const CoachStrategy({
    required this.primaryGoal,
    required this.strategyType,
    required this.requiresAI,
    required this.requiresFollowUp,
    required this.recommendationType,
    required this.tone,
    required this.priority,
    required this.confidence,
    required this.reasoning,
    required this.nextAction,
    required this.safetyFlags,
    required this.blockedActions,
    required this.availableActions,
    this.notes = const <String>[],
  });

  /// Product goal for this interaction.
  final String primaryGoal;

  /// Selected strategy family.
  final CoachStrategyType strategyType;

  /// Whether a future executor should call AI.
  final bool requiresAI;

  /// Whether the user must answer a follow-up first.
  final bool requiresFollowUp;

  /// Recommended response style.
  final CoachRecommendationType recommendationType;

  /// Tone guidance for future rendering.
  final CoachStrategyTone tone;

  /// Relative execution priority.
  final ResponsePriority priority;

  /// Strategy confidence from 0 to 1.
  final double confidence;

  /// Deterministic reasons for this strategy.
  final Set<CoachStrategyReason> reasoning;

  /// Primary action a future executor should take.
  final CoachAction nextAction;

  /// Safety-related flags detected during strategy assembly.
  final Set<CoachSafetyFlag> safetyFlags;

  /// Actions that must not run for this strategy.
  final Set<CoachAction> blockedActions;

  /// Actions allowed for this strategy.
  final Set<CoachAction> availableActions;

  /// Internal diagnostic notes.
  final List<String> notes;
}
