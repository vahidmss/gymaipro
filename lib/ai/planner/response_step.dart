import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/planner/response_priority.dart';

/// One executable step inside a future coach response pipeline.
///
/// Phase 4 only models steps. No step is executed by this module.
class ResponseStep {
  const ResponseStep({
    required this.id,
    required this.action,
    required this.priority,
    required this.description,
    this.payload = const <String, Object?>{},
  });

  /// Stable step id inside the plan.
  final String id;

  /// Action represented by this step.
  final CoachAction action;

  /// Step priority for future schedulers or UI integrations.
  final ResponsePriority priority;

  /// Human-readable description for diagnostics.
  final String description;

  /// Future-safe payload for integration metadata.
  final Map<String, Object?> payload;
}
