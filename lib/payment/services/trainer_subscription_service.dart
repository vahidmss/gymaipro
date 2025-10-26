import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/models/trainer_subscription.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت اشتراک‌های مربی
class TrainerSubscriptionService {
  factory TrainerSubscriptionService() => _instance;
  TrainerSubscriptionService._internal();
  static final TrainerSubscriptionService _instance =
      TrainerSubscriptionService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// ایجاد اشتراک جدید
  Future<TrainerSubscription?> createSubscription({
    required String userId,
    required String trainerId,
    required TrainerServiceType serviceType,
    required int originalAmount,
    required int finalAmount,
    String? discountCode,
    double? discountPercentage,
    String? paymentTransactionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (kDebugMode) {
        print(
          'ایجاد اشتراک مربی - کاربر: $userId, مربی: $trainerId, نوع: $serviceType',
        );
      }

      final subscription = TrainerSubscriptionBuilder()
          .setUserId(userId)
          .setTrainerId(trainerId)
          .setServiceType(serviceType)
          .setOriginalAmount(originalAmount)
          .setFinalAmount(finalAmount)
          .setDiscountCode(discountCode ?? '')
          .setDiscountPercentage(discountPercentage ?? 0.0)
          .setPaymentTransactionId(paymentTransactionId ?? '')
          .setMetadata(metadata ?? {})
          .build();

      final response = await _client
          .from('trainer_subscriptions')
          .insert(subscription.toJson())
          .select()
          .single();

      if (kDebugMode) {
        print('اشتراک مربی با موفقیت ایجاد شد: ${subscription.id}');
      }

      return TrainerSubscription.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در ایجاد اشتراک مربی: $e');
      }
      return null;
    }
  }

  /// دریافت اشتراک بر اساس شناسه
  Future<TrainerSubscription?> getSubscription(String id) async {
    try {
      final response = await _client
          .from('trainer_subscriptions')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return TrainerSubscription.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت اشتراک: $e');
      }
      return null;
    }
  }

  /// دریافت اشتراک‌های کاربر
  Future<List<TrainerSubscription>> getUserSubscriptions(String userId) async {
    try {
      final response = await _client
          .from('trainer_subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map(
            (json) =>
                TrainerSubscription.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت اشتراک‌های کاربر: $e');
      }
      return [];
    }
  }

  /// دریافت اشتراک‌های مربی
  Future<List<TrainerSubscription>> getTrainerSubscriptions(
    String trainerId,
  ) async {
    try {
      final response = await _client
          .from('trainer_subscriptions')
          .select()
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map(
            (json) =>
                TrainerSubscription.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت اشتراک‌های مربی: $e');
      }
      return [];
    }
  }

  /// به‌روزرسانی وضعیت اشتراک
  Future<bool> updateSubscriptionStatus(
    String id,
    TrainerSubscriptionStatus status, {
    DateTime? programRegistrationDate,
    DateTime? firstUsageDate,
    ProgramStatus? programStatus,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (programRegistrationDate != null) {
        updateData['program_registration_date'] = programRegistrationDate
            .toIso8601String();

        // محاسبه تاخیر مربی
        final subscription = await getSubscription(id);
        if (subscription != null) {
          final expectedDate = subscription.purchaseDate.add(
            const Duration(days: 1),
          );
          if (programRegistrationDate.isAfter(expectedDate)) {
            final delayDays = programRegistrationDate
                .difference(expectedDate)
                .inDays;
            updateData['trainer_delay_days'] = delayDays;
            updateData['program_status'] = ProgramStatus.delayed
                .toString()
                .split('.')
                .last;
          } else {
            updateData['program_status'] = ProgramStatus.inProgress
                .toString()
                .split('.')
                .last;
          }
        }
      }

      if (firstUsageDate != null) {
        updateData['first_usage_date'] = firstUsageDate.toIso8601String();
      }

      if (programStatus != null) {
        updateData['program_status'] = programStatus.toString().split('.').last;
      }

      if (metadata != null) {
        updateData['metadata'] = metadata;
      }

      await _client
          .from('trainer_subscriptions')
          .update(updateData)
          .eq('id', id);

      if (kDebugMode) {
        print('وضعیت اشتراک به‌روزرسانی شد: $id -> $status');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در به‌روزرسانی وضعیت اشتراک: $e');
      }
      return false;
    }
  }

  /// لغو اشتراک
  Future<bool> cancelSubscription(String id, {String? reason}) async {
    try {
      await _client
          .from('trainer_subscriptions')
          .update({
            'status': TrainerSubscriptionStatus.cancelled
                .toString()
                .split('.')
                .last,
            'cancellation_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      if (kDebugMode) {
        print('اشتراک لغو شد: $id');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در لغو اشتراک: $e');
      }
      return false;
    }
  }

  /// بررسی وجود اشتراک فعال
  Future<bool> hasActiveSubscription(
    String userId,
    String trainerId,
    TrainerServiceType serviceType,
  ) async {
    try {
      final response = await _client
          .from('trainer_subscriptions')
          .select('id, status, expiry_date')
          .eq('user_id', userId)
          .eq('trainer_id', trainerId)
          .eq('service_type', serviceType.toString().split('.').last)
          .or('status.eq.paid,status.eq.active');

      if (response.isNotEmpty) {
        for (final subscription in response) {
          final expiryDate = DateTime.parse(
            subscription['expiry_date'] as String,
          );
          if (DateTime.now().isBefore(expiryDate)) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در بررسی اشتراک فعال: $e');
      }
      return false;
    }
  }

  /// دریافت آمار اشتراک‌های مربی
  Future<Map<String, dynamic>> getTrainerStats(String trainerId) async {
    try {
      final response = await _client
          .from('trainer_subscriptions')
          .select('status, service_type, created_at')
          .eq('trainer_id', trainerId);

      final stats = <String, dynamic>{
        'total_subscriptions': response.length,
        'active_subscriptions': 0,
        'completed_subscriptions': 0,
        'pending_subscriptions': 0,
        'cancelled_subscriptions': 0,
        'total_revenue': 0,
        'service_breakdown': <String, int>{},
      };

      for (final subscription in response) {
        final status = subscription['status'] as String;
        final serviceType = subscription['service_type'] as String;

        // شمارش وضعیت‌ها
        switch (status) {
          case 'active':
            stats['active_subscriptions']++;
          case 'completed':
            stats['completed_subscriptions']++;
          case 'pending':
            stats['pending_subscriptions']++;
          case 'cancelled':
            stats['cancelled_subscriptions']++;
        }

        // شمارش نوع خدمات
        stats['service_breakdown'][serviceType] =
            (stats['service_breakdown'][serviceType] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت آمار مربی: $e');
      }
      return {};
    }
  }

  /// دریافت اشتراک‌های منقضی شده
  Future<List<TrainerSubscription>> getExpiredSubscriptions() async {
    try {
      final response = await _client
          .from('trainer_subscriptions')
          .select()
          .lt('expiry_date', DateTime.now().toIso8601String())
          .or('status.eq.active,status.eq.paid');

      return (response as List<dynamic>)
          .map(
            (json) =>
                TrainerSubscription.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت اشتراک‌های منقضی: $e');
      }
      return [];
    }
  }

  /// تمدید اشتراک
  Future<bool> renewSubscription(String id, {int days = 30}) async {
    try {
      final subscription = await getSubscription(id);
      if (subscription == null) return false;

      final newExpiryDate = subscription.expiryDate.add(Duration(days: days));

      await _client
          .from('trainer_subscriptions')
          .update({
            'expiry_date': newExpiryDate.toIso8601String(),
            'status': TrainerSubscriptionStatus.active
                .toString()
                .split('.')
                .last,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      if (kDebugMode) {
        print('اشتراک تمدید شد: $id -> ${newExpiryDate.toIso8601String()}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در تمدید اشتراک: $e');
      }
      return false;
    }
  }

  /// حذف اشتراک
  Future<bool> deleteSubscription(String id) async {
    try {
      await _client.from('trainer_subscriptions').delete().eq('id', id);

      if (kDebugMode) {
        print('اشتراک حذف شد: $id');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در حذف اشتراک: $e');
      }
      return false;
    }
  }

  /// جستجوی اشتراک‌ها
  Future<List<TrainerSubscription>> searchSubscriptions({
    String? userId,
    String? trainerId,
    TrainerServiceType? serviceType,
    TrainerSubscriptionStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    try {
      final base = _client.from('trainer_subscriptions').select();
      var filter = base;

      if (userId != null) {
        filter = filter.eq('user_id', userId);
      }

      if (trainerId != null) {
        filter = filter.eq('trainer_id', trainerId);
      }

      if (serviceType != null) {
        filter = filter.eq(
          'service_type',
          serviceType.toString().split('.').last,
        );
      }

      if (status != null) {
        filter = filter.eq('status', status.toString().split('.').last);
      }

      if (fromDate != null) {
        filter = filter.gte('created_at', fromDate.toIso8601String());
      }

      if (toDate != null) {
        filter = filter.lte('created_at', toDate.toIso8601String());
      }

      final ordered = filter.order('created_at', ascending: false);

      final response = await (limit != null ? ordered.limit(limit) : ordered);

      return (response as List<dynamic>)
          .map(
            (json) =>
                TrainerSubscription.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در جستجوی اشتراک‌ها: $e');
      }
      return [];
    }
  }
}
