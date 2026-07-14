import 'package:gymaipro/ai/entitlement/coach_entitlement.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';

/// Read-only subscription snapshot consumed by Coach entitlement runtime.
class CoachEntitlementSnapshot {
  const CoachEntitlementSnapshot({
    required this.entitlement,
    required this.source,
    this.capturedAt,
  });

  /// Creates a conservative free snapshot when no subscription data is present.
  factory CoachEntitlementSnapshot.free({
    required String userId,
    DateTime? capturedAt,
  }) {
    return CoachEntitlementSnapshot(
      entitlement: CoachEntitlement(
        userId: userId,
        plan: CoachSubscriptionPlan.free,
      ),
      source: 'free_fallback',
      capturedAt: capturedAt,
    );
  }

  /// Capability entitlement derived from the current read-only subscription.
  final CoachEntitlement entitlement;

  /// Source label used for diagnostics.
  final String source;

  /// Time the snapshot was adapted.
  final DateTime? capturedAt;
}
