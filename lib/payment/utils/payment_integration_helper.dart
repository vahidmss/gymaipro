import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/payment_plan.dart';
import 'package:gymaipro/payment/models/subscription.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';

/// کلاس کمکی برای ادغام سیستم پرداخت با بقیه اپلیکیشن
class PaymentIntegrationHelper {
  static final SubscriptionService _subscriptionService = SubscriptionService();

  /// بررسی دسترسی به ویژگی‌های AI
  static Future<bool> hasAIAccess() async {
    return _subscriptionService.hasFeatureAccess(featureName: 'ai_programs');
  }

  /// بررسی دسترسی به مربی‌ها
  static Future<bool> hasTrainerAccess() async {
    return _subscriptionService.hasFeatureAccess(featureName: 'trainer_access');
  }

  /// نمایش صفحه پرداخت برای برنامه AI
  static void showAIProgramPayment(BuildContext context) {
    final aiPlan = PredefinedPlans.aiPrograms.first;
    Navigator.pushNamed(context, '/payment', arguments: aiPlan);
  }

  /// نمایش صفحه پرداخت برای اشتراک
  static void showSubscriptionPayment(
    BuildContext context, {
    bool isPremium = false,
  }) {
    final subscriptionPlan = isPremium
        ? PredefinedPlans.subscriptions.firstWhere(
            (p) => p.accessLevel == PlanAccessLevel.premium,
          )
        : PredefinedPlans.subscriptions.firstWhere(
            (p) => p.accessLevel == PlanAccessLevel.basic,
          );

    Navigator.pushNamed(context, '/payment', arguments: subscriptionPlan);
  }

  /// نمایش دیالوگ محدودیت دسترسی
  static void showAccessLimitDialog(
    BuildContext context, {
    required String featureName,
    String? customMessage,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دسترسی محدود'),
        content: Text(
          customMessage ?? 'برای استفاده از این ویژگی نیاز به اشتراک دارید.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/subscriptions');
            },
            child: const Text('خرید اشتراک'),
          ),
        ],
      ),
    );
  }

  /// بررسی و هدایت به پرداخت در صورت عدم دسترسی
  static Future<bool> checkAccessOrRedirect(
    BuildContext context, {
    required String featureName,
    String? customMessage,
  }) async {
    final hasAccess = await _subscriptionService.hasFeatureAccess(
      featureName: featureName,
    );

    if (!hasAccess) {
      showAccessLimitDialog(
        context,
        featureName: featureName,
        customMessage: customMessage,
      );
      return false;
    }

    return true;
  }

  /// دریافت وضعیت اشتراک کاربر
  static Future<Map<String, dynamic>> getUserSubscriptionStatus() async {
    final subscription = await _subscriptionService.getActiveSubscription();

    if (subscription == null) {
      return {
        'has_subscription': false,
        'status': 'none',
        'message': 'بدون اشتراک',
      };
    }

    return {
      'has_subscription': true,
      'subscription': subscription,
      'status': subscription.statusText,
      'remaining_days': subscription.remainingDays,
      'needs_renewal': subscription.needsRenewal,
      'message': subscription.remainingTimeText,
    };
  }
}

/// ویجت نمایش وضعیت اشتراک
class SubscriptionStatusWidget extends StatelessWidget {
  const SubscriptionStatusWidget({
    super.key,
    this.subscription,
    this.onUpgrade,
  });
  final Subscription? subscription;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'برای دسترسی کامل، اشتراک تهیه کنید',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.orange.shade300,
                ),
              ),
            ),
            if (onUpgrade != null)
              TextButton(
                onPressed: onUpgrade,
                child: const Text(
                  'خرید',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
          ],
        ),
      );
    }

    if (!subscription!.isActive) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_outlined, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'اشتراک شما ${subscription!.statusText}',
                style: TextStyle(fontSize: 12.sp, color: Colors.red.shade300),
              ),
            ),
            if (onUpgrade != null)
              TextButton(
                onPressed: onUpgrade,
                child: const Text(
                  'تمدید',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'اشتراک فعال - ${subscription!.remainingTimeText}',
              style: TextStyle(fontSize: 12.sp, color: Colors.green.shade300),
            ),
          ),
        ],
      ),
    );
  }
}
