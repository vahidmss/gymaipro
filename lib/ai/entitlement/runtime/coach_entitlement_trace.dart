import 'package:gymaipro/ai/entitlement/coach_capability.dart';

/// Trace emitted by the Coach entitlement runtime stage.
class CoachEntitlementTrace {
  const CoachEntitlementTrace({
    required this.checkedCapabilities,
    required this.missingCapabilities,
    required this.remainingUsage,
    required this.executionTime,
    this.upgradeSuggestion,
    this.snapshotSource,
  });

  /// Capabilities evaluated for this request.
  final Set<CoachCapability> checkedCapabilities;

  /// Required capabilities not granted by the current entitlement.
  final Set<CoachCapability> missingCapabilities;

  /// Remaining usage counters keyed by capability and limit type.
  final Map<String, int?> remainingUsage;

  /// Suggested upgrade plan id, when blocked by plan access.
  final String? upgradeSuggestion;

  /// Source label from the read-only entitlement snapshot provider.
  final String? snapshotSource;

  /// Runtime execution time.
  final Duration executionTime;
}
