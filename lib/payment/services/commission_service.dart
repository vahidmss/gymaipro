import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/models/commission_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت کمیسیون
class CommissionService {
  factory CommissionService() => _instance;
  CommissionService._internal();
  static final CommissionService _instance = CommissionService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// دریافت تنظیمات کمیسیون فعال
  Future<CommissionSettings?> getActiveSettings() async {
    try {
      final response = await _client
          .from('commission_settings')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return CommissionSettings.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت تنظیمات کمیسیون: $e');
      }
      return null;
    }
  }

  /// دریافت تمام تنظیمات (برای ادمین)
  Future<List<CommissionSettings>> getAllSettings() async {
    try {
      final response = await _client
          .from('commission_settings')
          .select()
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => CommissionSettings.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت تمام تنظیمات: $e');
      }
      return [];
    }
  }

  /// ایجاد تنظیمات جدید
  Future<CommissionSettings?> createSettings({
    required double commissionPercentage,
    required int holdDays,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('کاربر احراز هویت نشده است');
      }

      // غیرفعال کردن تنظیمات قبلی
      await _client
          .from('commission_settings')
          .update({'is_active': false})
          .eq('is_active', true);

      // ایجاد تنظیمات جدید
      final response = await _client
          .from('commission_settings')
          .insert({
            'commission_percentage': commissionPercentage,
            'hold_days': holdDays,
            'is_active': true,
            'created_by': userId,
          })
          .select()
          .single();

      return CommissionSettings.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در ایجاد تنظیمات کمیسیون: $e');
      }
      return null;
    }
  }

  /// به‌روزرسانی تنظیمات
  Future<bool> updateSettings({
    required String id,
    double? commissionPercentage,
    int? holdDays,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (commissionPercentage != null) {
        updateData['commission_percentage'] = commissionPercentage;
      }
      if (holdDays != null) {
        updateData['hold_days'] = holdDays;
      }
      if (isActive != null) {
        updateData['is_active'] = isActive;
      }

      if (updateData.isEmpty) return true;

      await _client
          .from('commission_settings')
          .update(updateData)
          .eq('id', id);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در به‌روزرسانی تنظیمات: $e');
      }
      return false;
    }
  }

  /// محاسبه کمیسیون و درآمد مربی
  Future<Map<String, int>> calculateCommission(int finalAmount) async {
    try {
      final settings = await getActiveSettings();
      if (settings == null) {
        // اگر تنظیمات وجود نداشت، کمیسیون 0% در نظر می‌گیریم
        return {
          'platform_revenue': 0,
          'trainer_earnings': finalAmount,
        };
      }

      final commissionAmount =
          (finalAmount * settings.commissionPercentage / 100).round();
      final trainerEarnings = finalAmount - commissionAmount;

      return {
        'platform_revenue': commissionAmount,
        'trainer_earnings': trainerEarnings,
      };
    } catch (e) {
      if (kDebugMode) {
        print('خطا در محاسبه کمیسیون: $e');
      }
      return {
        'platform_revenue': 0,
        'trainer_earnings': finalAmount,
      };
    }
  }

  /// ثبت درآمد پلتفرم
  Future<bool> recordPlatformRevenue({
    required String transactionId,
    required String subscriptionId,
    required String trainerId,
    required int amount,
    required double commissionPercentage,
  }) async {
    try {
      await _client.from('platform_revenue').insert({
        'transaction_id': transactionId,
        'subscription_id': subscriptionId,
        'trainer_id': trainerId,
        'amount': amount,
        'commission_percentage': commissionPercentage,
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در ثبت درآمد پلتفرم: $e');
      }
      return false;
    }
  }

  /// دریافت مجموع درآمد پلتفرم
  Future<int> getTotalPlatformRevenue({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _client.from('platform_revenue').select('amount');

      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('created_at', toDate.toIso8601String());
      }

      final response = await query;
      int total = 0;

      for (final item in (response as List<dynamic>)) {
        total += (item['amount'] as num).toInt();
      }

      return total;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت درآمد پلتفرم: $e');
      }
      return 0;
    }
  }
}

