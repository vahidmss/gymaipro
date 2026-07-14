import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/entitlement/coach_entitlement.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_snapshot.dart';
import 'package:gymaipro/payment/models/subscription.dart';

/// Read-only adapter boundary for Coach entitlement snapshots.
class CoachEntitlementProvider {
  const CoachEntitlementProvider();

  /// Returns a read-only entitlement snapshot for the current request.
  Future<CoachEntitlementSnapshot> snapshotFor({
    required String userId,
    required CoachContext context,
    required Map<String, Object?> metadata,
  }) async {
    return CoachEntitlementSnapshot.free(
      userId: userId,
      capturedAt: DateTime.now(),
    );
  }
}

/// Temporary adapter for current subscription data already available in memory.
///
/// This adapter intentionally does not call subscription services because the
/// existing service can mutate expired subscription state.
class CurrentSubscriptionAdapter extends CoachEntitlementProvider {
  const CurrentSubscriptionAdapter();

  @override
  Future<CoachEntitlementSnapshot> snapshotFor({
    required String userId,
    required CoachContext context,
    required Map<String, Object?> metadata,
  }) async {
    final explicitSnapshot = metadata['coachEntitlementSnapshot'];
    if (explicitSnapshot is CoachEntitlementSnapshot) return explicitSnapshot;

    final explicitEntitlement = metadata['coachEntitlement'];
    if (explicitEntitlement is CoachEntitlement) {
      return CoachEntitlementSnapshot(
        entitlement: explicitEntitlement,
        source: 'metadata_entitlement',
        capturedAt: DateTime.now(),
      );
    }

    final subscription = metadata['subscription'];
    if (subscription is Subscription) {
      return _fromSubscription(userId: userId, subscription: subscription);
    }

    final subscriptionJson = metadata['subscriptionJson'];
    if (subscriptionJson is Map<String, Object?>) {
      return _fromSubscription(
        userId: userId,
        subscription: Subscription.fromJson(
          Map<String, dynamic>.from(subscriptionJson),
        ),
      );
    }

    return CoachEntitlementSnapshot.free(
      userId: userId,
      capturedAt: DateTime.now(),
    );
  }

  CoachEntitlementSnapshot _fromSubscription({
    required String userId,
    required Subscription subscription,
  }) {
    final active = subscription.status == SubscriptionStatus.active &&
        !DateTime.now().isAfter(subscription.expiryDate);
    return CoachEntitlementSnapshot(
      entitlement: CoachEntitlement(
        userId: subscription.userId.isNotEmpty ? subscription.userId : userId,
        plan: _planFor(subscription.type),
        planActive: active,
        metadata: <String, Object?>{
          'subscriptionId': subscription.id,
          'subscriptionType': subscription.type.name,
          'subscriptionStatus': subscription.status.name,
        },
      ),
      source: 'current_subscription_adapter',
      capturedAt: DateTime.now(),
    );
  }

  CoachSubscriptionPlan _planFor(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return CoachSubscriptionPlan.coachPro;
      case SubscriptionType.aiPremium:
        return CoachSubscriptionPlan.ultimateAI;
      case SubscriptionType.trainerAccess:
        return CoachSubscriptionPlan.coachPro;
      case SubscriptionType.fullAccess:
        return CoachSubscriptionPlan.ultimateAI;
    }
  }
}
