import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/models/subscription.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت اشتراک‌ها
class SubscriptionService {
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();
  static final SubscriptionService _instance = SubscriptionService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// دریافت اشتراک فعال کاربر
  Future<Subscription?> getActiveSubscription() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return null;

      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final subscription = Subscription.fromJson(response);

        // بررسی انقضا
        if (subscription.isExpired) {
          await _updateSubscriptionStatus(
            subscription.id,
            SubscriptionStatus.expired,
          );
          return subscription.copyWith(status: SubscriptionStatus.expired);
        }

        return subscription;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت اشتراک فعال: $e');
      }
      return null;
    }
  }

  /// دریافت تمام اشتراک‌های کاربر
  Future<List<Subscription>> getUserSubscriptions() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return [];

      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map<Subscription>(Subscription.fromJson).toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت اشتراک‌های کاربر: $e');
      }
      return [];
    }
  }

  /// ایجاد اشتراک جدید
  Future<Subscription?> createSubscription({
    required SubscriptionType type,
    required int price,
    bool autoRenewal = true,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) throw Exception('کاربر وارد نشده است');

      // بررسی اشتراک فعال موجود
      final activeSubscription = await getActiveSubscription();
      if (activeSubscription != null && !activeSubscription.isExpired) {
        throw Exception('شما در حال حاضر اشتراک فعال دارید');
      }

      final subscription = SubscriptionBuilder()
          .setUserId(userId)
          .setType(type)
          .setPrice(price)
          .setAutoRenewal(autoRenewal)
          .build();

      final subscriptionData = subscription.toJson();
      subscriptionData['user_id'] = userId; // اطمینان از وجود user_id

      final response = await _client
          .from('subscriptions')
          .insert(subscriptionData)
          .select()
          .single();

      if (kDebugMode) {
        print('اشتراک جدید ایجاد شد: ${subscription.typeText}');
      }

      return Subscription.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در ایجاد اشتراک: $e');
      }
      return null;
    }
  }

  /// فعال‌سازی اشتراک بعد از پرداخت موفق
  Future<bool> activateSubscription({
    required String subscriptionId,
    required String transactionId,
  }) async {
    try {
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 31)); // 31 روز

      await _client
          .from('subscriptions')
          .update({
            'status': 'active',
            'start_date': now.toIso8601String(),
            'expiry_date': expiryDate.toIso8601String(),
            'last_payment_date': now.toIso8601String(),
            'last_transaction_id': transactionId,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', subscriptionId);

      // اضافه کردن رکورد به تاریخچه اشتراک
      await _addSubscriptionHistory(
        subscriptionId: subscriptionId,
        action: 'activated',
        description: 'اشتراک فعال شد',
        transactionId: transactionId,
      );

      if (kDebugMode) {
        print('اشتراک $subscriptionId فعال شد');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در فعال‌سازی اشتراک: $e');
      }
      return false;
    }
  }

  /// تمدید اشتراک
  Future<bool> renewSubscription({
    required String subscriptionId,
    required String transactionId,
  }) async {
    try {
      final subscription = await _getSubscriptionById(subscriptionId);
      if (subscription == null) return false;

      final now = DateTime.now();
      final newExpiryDate = subscription.expiryDate.isAfter(now)
          ? subscription.expiryDate.add(const Duration(days: 31))
          : now.add(const Duration(days: 31));

      await _client
          .from('subscriptions')
          .update({
            'expiry_date': newExpiryDate.toIso8601String(),
            'last_payment_date': now.toIso8601String(),
            'last_transaction_id': transactionId,
            'renewal_count': subscription.renewalCount + 1,
            'status': 'active',
            'updated_at': now.toIso8601String(),
          })
          .eq('id', subscriptionId);

      await _addSubscriptionHistory(
        subscriptionId: subscriptionId,
        action: 'renewed',
        description: 'اشتراک تمدید شد',
        transactionId: transactionId,
      );

      if (kDebugMode) {
        print('اشتراک $subscriptionId تمدید شد');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در تمدید اشتراک: $e');
      }
      return false;
    }
  }

  /// لغو اشتراک
  Future<bool> cancelSubscription({
    required String subscriptionId,
    required String reason,
  }) async {
    try {
      final now = DateTime.now();

      await _client
          .from('subscriptions')
          .update({
            'status': 'cancelled',
            'cancelled_at': now.toIso8601String(),
            'cancellation_reason': reason,
            'auto_renewal': false,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', subscriptionId);

      await _addSubscriptionHistory(
        subscriptionId: subscriptionId,
        action: 'cancelled',
        description: 'اشتراک لغو شد: $reason',
      );

      if (kDebugMode) {
        print('اشتراک $subscriptionId لغو شد');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در لغو اشتراک: $e');
      }
      return false;
    }
  }

  /// بررسی نیاز به تمدید خودکار
  Future<List<Subscription>> getSubscriptionsNeedingRenewal() async {
    try {
      final threeDaysFromNow = DateTime.now().add(const Duration(days: 3));

      final response = await _client
          .from('subscriptions')
          .select()
          .eq('status', 'active')
          .eq('auto_renewal', true)
          .lt('expiry_date', threeDaysFromNow.toIso8601String());

      return response.map<Subscription>(Subscription.fromJson).toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت اشتراک‌های نیازمند تمدید: $e');
      }
      return [];
    }
  }

  /// به‌روزرسانی اشتراک‌های منقضی شده
  Future<void> updateExpiredSubscriptions() async {
    try {
      final now = DateTime.now();

      await _client
          .from('subscriptions')
          .update({'status': 'expired', 'updated_at': now.toIso8601String()})
          .eq('status', 'active')
          .lt('expiry_date', now.toIso8601String());

      if (kDebugMode) {
        print('اشتراک‌های منقضی شده به‌روزرسانی شدند');
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در به‌روزرسانی اشتراک‌های منقضی: $e');
      }
    }
  }

  /// بررسی دسترسی کاربر به ویژگی خاص
  Future<bool> hasFeatureAccess({
    required String featureName,
    SubscriptionType? requiredType,
  }) async {
    try {
      final activeSubscription = await getActiveSubscription();
      if (activeSubscription == null || !activeSubscription.isActive) {
        return false;
      }

      // بررسی نوع اشتراک مورد نیاز
      if (requiredType != null && activeSubscription.type != requiredType) {
        return false;
      }

      // بررسی ویژگی‌های خاص
      switch (featureName) {
        case 'ai_programs':
          return activeSubscription.type == SubscriptionType.aiPremium ||
              activeSubscription.type == SubscriptionType.fullAccess;
        case 'trainer_access':
          return activeSubscription.type == SubscriptionType.trainerAccess ||
              activeSubscription.type == SubscriptionType.fullAccess;
        case 'unlimited_programs':
          return activeSubscription.type == SubscriptionType.fullAccess;
        default:
          return true; // ویژگی‌های پایه برای همه اشتراک‌ها
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در بررسی دسترسی ویژگی: $e');
      }
      return false;
    }
  }

  /// دریافت آمار اشتراک‌ها
  Future<Map<String, dynamic>> getSubscriptionStats() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return {};

      final subscriptions = await getUserSubscriptions();

      final activeCount = subscriptions.where((s) => s.isActive).length;
      final expiredCount = subscriptions
          .where((s) => s.status == SubscriptionStatus.expired)
          .length;
      final cancelledCount = subscriptions.where((s) => s.isCancelled).length;

      final totalPaid = subscriptions
          .where(
            (s) =>
                s.status == SubscriptionStatus.active ||
                s.status == SubscriptionStatus.expired,
          )
          .fold<int>(0, (sum, s) => sum + (s.price * (s.renewalCount + 1)));

      return {
        'total_subscriptions': subscriptions.length,
        'active_count': activeCount,
        'expired_count': expiredCount,
        'cancelled_count': cancelledCount,
        'total_paid': totalPaid,
        'total_renewals': subscriptions.fold<int>(
          0,
          (sum, s) => sum + s.renewalCount,
        ),
      };
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت آمار اشتراک‌ها: $e');
      }
      return {};
    }
  }

  /// متدهای کمکی خصوصی

  Future<Subscription?> _getSubscriptionById(String subscriptionId) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('id', subscriptionId)
          .single();

      return Subscription.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateSubscriptionStatus(
    String subscriptionId,
    SubscriptionStatus status,
  ) async {
    try {
      await _client
          .from('subscriptions')
          .update({
            'status': status.toString().split('.').last,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscriptionId);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در به‌روزرسانی وضعیت اشتراک: $e');
      }
    }
  }

  Future<void> _addSubscriptionHistory({
    required String subscriptionId,
    required String action,
    required String description,
    String? transactionId,
  }) async {
    try {
      await _client.from('subscription_history').insert({
        'subscription_id': subscriptionId,
        'action': action,
        'description': description,
        'transaction_id': transactionId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('خطا در اضافه کردن تاریخچه اشتراک: $e');
      }
    }
  }
}
