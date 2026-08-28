import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/entitlement/subscription_capability_map.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/payment/models/subscription.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';

/// منبع حقیقت برای «پاس برنامه AI».
///
/// - [AiProgramAccessSnapshot.hasPaidAccess]: پرداخت شده و می‌تواند بسازد
/// - [AiProgramAccessSnapshot.hasPass]: برنامه تحویل شده و ساعت اعتبار شروع شده
class AiProgramAccess {
  AiProgramAccess({SubscriptionService? subscriptions})
    : _subscriptions = subscriptions ?? SubscriptionService();

  final SubscriptionService _subscriptions;

  /// True when the delivered AI pass window is active (chat / tools / days).
  Future<bool> hasActivePass({String? userId}) async {
    final snapshot = await load(userId: userId);
    return snapshot.hasPass;
  }

  /// True when the user has paid and may build (even before delivery clock).
  Future<bool> hasPaidAccess({String? userId}) async {
    final snapshot = await load(userId: userId);
    return snapshot.hasPaidAccess;
  }

  Future<AiProgramAccessSnapshot> load({String? userId}) async {
    final uid = (userId != null && userId.trim().isNotEmpty)
        ? userId.trim()
        : await AuthHelper.getCurrentUserId();
    if (uid == null || uid.isEmpty) {
      return const AiProgramAccessSnapshot.none();
    }

    final subscription = await _subscriptions.peekActiveSubscription(
      userId: uid,
    );
    if (subscription == null) {
      return const AiProgramAccessSnapshot.none();
    }

    final plan = CoachPlanCatalog.planFromSubscriptionType(subscription.type);
    final caps = SubscriptionCapabilityMap.forPlan(plan);
    final hasToolkit = caps.contains(CoachCapability.generateWorkout);
    if (!hasToolkit) {
      return const AiProgramAccessSnapshot.none();
    }

    final started = subscription.coachEntitlementStarted;
    final now = DateTime.now();
    final expiry = subscription.expiryDate;
    var days = 0;
    if (started && expiry.isAfter(now)) {
      final remainder = expiry.difference(now);
      days = remainder.inDays;
      if (days == 0) days = 1;
    }

    return AiProgramAccessSnapshot(
      hasPaidAccess: true,
      hasPass: started,
      plan: plan,
      subscription: subscription,
      daysRemaining: days,
      userId: uid,
    );
  }
}

class AiProgramAccessSnapshot {
  const AiProgramAccessSnapshot({
    required this.hasPaidAccess,
    required this.hasPass,
    required this.plan,
    required this.daysRemaining,
    this.subscription,
    this.userId,
  });

  const AiProgramAccessSnapshot.none()
    : hasPaidAccess = false,
      hasPass = false,
      plan = CoachSubscriptionPlan.free,
      daysRemaining = 0,
      subscription = null,
      userId = null;

  /// Paid coach plan — allowed to enter/build even before delivery clock.
  final bool hasPaidAccess;

  /// Delivered pass — unlimited chat / remaining days / full premium tools.
  final bool hasPass;
  final CoachSubscriptionPlan plan;
  final int daysRemaining;
  final Subscription? subscription;
  final String? userId;
}
