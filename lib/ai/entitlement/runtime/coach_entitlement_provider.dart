import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/entitlement/coach_entitlement.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_snapshot.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/payment/models/subscription.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';

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

/// Adapter that prefers explicit metadata, then peeks the active subscription.
///
/// Uses [SubscriptionService.peekActiveSubscription] so expired rows are not
/// mutated during entitlement reads.
class CurrentSubscriptionAdapter extends CoachEntitlementProvider {
  const CurrentSubscriptionAdapter({
    SubscriptionService? subscriptionService,
  }) : _subscriptionService = subscriptionService;

  final SubscriptionService? _subscriptionService;

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

    final service = _subscriptionService ?? SubscriptionService();
    final active = await service.peekActiveSubscription(userId: userId);
    if (active != null) {
      return _fromSubscription(userId: userId, subscription: active);
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
    final active =
        subscription.status == SubscriptionStatus.active &&
        !DateTime.now().isAfter(subscription.expiryDate);
    return CoachEntitlementSnapshot(
      entitlement: CoachEntitlement(
        userId: subscription.userId.isNotEmpty ? subscription.userId : userId,
        plan: CoachPlanCatalog.planFromSubscriptionType(subscription.type),
        planActive: active,
        metadata: <String, Object?>{
          'subscriptionId': subscription.id,
          'subscriptionType': subscription.type.name,
          'subscriptionStatus': subscription.status.name,
          'planId': CoachPlanCatalog.idFromPlan(
            CoachPlanCatalog.planFromSubscriptionType(subscription.type),
          ),
        },
      ),
      source: 'current_subscription_adapter',
      capturedAt: DateTime.now(),
    );
  }
}
