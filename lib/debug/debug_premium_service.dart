import 'package:flutter/foundation.dart';
import 'package:gymaipro/features/workout_program_request/application/workout_program_token_service.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/payment/models/subscription.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';

/// Debug-only grant/revoke of coach premium for AI testing.
class DebugPremiumService {
  DebugPremiumService({
    SubscriptionService? subscriptions,
    WorkoutProgramTokenService? tokens,
  }) : _subscriptions = subscriptions ?? SubscriptionService(),
       _tokens = tokens ?? WorkoutProgramTokenService();

  final SubscriptionService _subscriptions;
  final WorkoutProgramTokenService _tokens;

  static const String _debugTxPrefix = 'debug-premium';

  Future<Subscription?> currentPremium() async {
    assert(kDebugMode, 'DebugPremiumService is debug-only');
    if (!kDebugMode) return null;
    return _subscriptions.peekActiveSubscription();
  }

  /// Grants the single AI program pass for [days] days.
  Future<Subscription> grantPremium({
    String planId = CoachPlanCatalog.coachProId,
    int days = CoachPlanCatalog.defaultValidityDays,
    int programTokens = 1,
  }) async {
    assert(kDebugMode, 'DebugPremiumService is debug-only');
    if (!kDebugMode) {
      throw StateError('Premium grant is only available in debug mode');
    }

    final userId = await AuthHelper.getCurrentUserId();
    if (userId == null) {
      throw StateError('کاربر وارد نشده است');
    }

    final type = CoachPlanCatalog.subscriptionTypeForPlanId(planId);
    final txId =
        '$_debugTxPrefix-${DateTime.now().millisecondsSinceEpoch}';

    final sub = await _subscriptions.createAndActivateCoachPlan(
      type: type,
      // DB check `subscriptions_price_check` rejects 0 — use a nominal rial.
      price: 10000,
      validityDays: days,
      transactionId: txId,
      metadata: <String, dynamic>{
        'source': 'debug_premium_grant',
        'plan_id': planId,
        'debug': true,
        'price_note': 'nominal_debug_price',
      },
    );

    if (sub == null) {
      throw StateError('ثبت اشتراک دیباگ ناموفق بود (احتمالاً RLS)');
    }

    if (programTokens > 0) {
      await _tokens.grantPurchaseTokens(
        userId: userId,
        count: programTokens,
      );
    }

    if (kDebugMode) {
      debugPrint(
        'DEBUG premium: granted $planId until ${sub.expiryDate.toIso8601String()} '
        'tokens=+$programTokens',
      );
    }

    return sub;
  }

  /// Cancels the active coach subscription and clears program tokens.
  Future<void> revokePremium({bool clearTokens = true}) async {
    assert(kDebugMode, 'DebugPremiumService is debug-only');
    if (!kDebugMode) {
      throw StateError('Premium revoke is only available in debug mode');
    }

    final userId = await AuthHelper.getCurrentUserId();
    if (userId == null) {
      throw StateError('کاربر وارد نشده است');
    }

    final active = await _subscriptions.peekActiveSubscription(userId: userId);
    if (active != null) {
      final ok = await _subscriptions.cancelSubscription(
        subscriptionId: active.id,
        reason: 'لغو دیباگ پرمیوم',
      );
      if (!ok) {
        throw StateError(
          'لغو اشتراک ناموفق بود. احتمالاً policy آپدیت روی subscriptions ندارید.',
        );
      }
    }

    if (clearTokens) {
      await _tokens.clearTokensForDebug(userId: userId);
    }

    if (kDebugMode) {
      debugPrint('DEBUG premium: revoked for $userId');
    }
  }
}
