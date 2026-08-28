import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_entitlement.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_snapshot.dart';
import 'package:gymaipro/ai/services/coach_chat_daily_limit_service.dart';
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
  CurrentSubscriptionAdapter({
    SubscriptionService? subscriptionService,
    CoachChatDailyLimitService? chatDailyLimitService,
  }) : _subscriptionService = subscriptionService,
       _chatDailyLimitService =
           chatDailyLimitService ?? CoachChatDailyLimitService();

  final SubscriptionService? _subscriptionService;
  final CoachChatDailyLimitService _chatDailyLimitService;

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

    final chatUsage = await _chatDailyLimitService.dailyUsageForEntitlement(
      userId: userId,
    );
    final usage = EntitlementUsageSnapshot(
      dailyUsage: <CoachCapability, int>{
        CoachCapability.coachConversation: chatUsage,
      },
    );

    final subscription = metadata['subscription'];
    if (subscription is Subscription) {
      return _fromSubscription(
        userId: userId,
        subscription: subscription,
        usage: usage,
      );
    }

    final subscriptionJson = metadata['subscriptionJson'];
    if (subscriptionJson is Map<String, Object?>) {
      return _fromSubscription(
        userId: userId,
        subscription: Subscription.fromJson(
          Map<String, dynamic>.from(subscriptionJson),
        ),
        usage: usage,
      );
    }

    final service = _subscriptionService ?? SubscriptionService();
    final active = await service.peekActiveSubscription(userId: userId);
    if (active != null) {
      return _fromSubscription(
        userId: userId,
        subscription: active,
        usage: usage,
      );
    }

    return CoachEntitlementSnapshot(
      entitlement: CoachEntitlement(
        userId: userId,
        plan: CoachSubscriptionPlan.free,
        usage: usage,
      ),
      source: 'free_fallback',
      capturedAt: DateTime.now(),
    );
  }

  CoachEntitlementSnapshot _fromSubscription({
    required String userId,
    required Subscription subscription,
    required EntitlementUsageSnapshot usage,
  }) {
    final started = subscription.coachEntitlementStarted;
    final active =
        started &&
        subscription.status == SubscriptionStatus.active &&
        !DateTime.now().isAfter(subscription.expiryDate);
    // Until the program is delivered, treat the user as free for tool/chat caps.
    final plan = started
        ? CoachPlanCatalog.planFromSubscriptionType(subscription.type)
        : CoachSubscriptionPlan.free;
    return CoachEntitlementSnapshot(
      entitlement: CoachEntitlement(
        userId: subscription.userId.isNotEmpty ? subscription.userId : userId,
        plan: plan,
        planActive: active,
        usage: usage,
        metadata: <String, Object?>{
          'subscriptionId': subscription.id,
          'subscriptionType': subscription.type.name,
          'subscriptionStatus': subscription.status.name,
          'entitlementStarted': started,
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
