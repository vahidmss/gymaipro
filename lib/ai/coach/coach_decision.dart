import 'package:gymaipro/ai/coach/coach_reason.dart';
import 'package:gymaipro/ai/context/context_models.dart';

/// Immutable decision returned by the GymAI Coach Brain.
///
/// This object only describes what should happen next. It never calls OpenAI,
/// writes state, shows UI, or changes existing app behavior.
class CoachDecision {
  const CoachDecision({
    required this.shouldCallAI,
    required this.missingData,
    required this.requiredProviders,
    required this.missingProviders,
    required this.decisionReason,
    required this.confidence,
    required this.notes,
    this.localResponse,
    this.followUpQuestion,
  });

  /// Whether the next layer should call AI.
  final bool shouldCallAI;

  /// Optional local response text for future non-AI flows.
  final String? localResponse;

  /// Optional follow-up question when more data is needed.
  final String? followUpQuestion;

  /// Human-readable missing data keys.
  final List<String> missingData;

  /// Provider keys required by the resolved intent.
  final Set<AIContextProviderKey> requiredProviders;

  /// Required provider keys that are not currently available.
  final Set<AIContextProviderKey> missingProviders;

  /// Reasons that explain the decision.
  final Set<CoachReason> decisionReason;

  /// Confidence in this routing decision from 0 to 1.
  final double confidence;

  /// Internal notes for future diagnostics.
  final List<String> notes;

  /// Convenience flag for follow-up routing.
  bool get requiresFollowUp => followUpQuestion != null;

  /// Convenience flag for local routing.
  bool get hasLocalResponse => localResponse != null && !shouldCallAI;
}
