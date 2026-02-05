import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس تاریخچه پرداخت‌ها
/// از profileId استفاده می‌کند چون در این پروژه payment_transactions.user_id به profiles.id اشاره دارد.
class PaymentHistoryService {
  factory PaymentHistoryService() => _instance;
  PaymentHistoryService._internal();
  static final PaymentHistoryService _instance =
      PaymentHistoryService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// دریافت پرداخت‌های مستقیم کاربر با صفحه‌بندی
  /// user_id در جدول = profileId است، نه auth.uid()
  Future<List<PaymentTransaction>> getDirectPayments({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId == null || userId.isEmpty) return [];

      final response = await _client
          .from('payment_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final list = response as List<dynamic>;
      final payments = list
          .map<PaymentTransaction>(
            (json) => PaymentTransaction.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      if (kDebugMode) {
        print(
          'PAYMENT_HISTORY: user_id=$userId, تعداد پرداخت‌ها=${payments.length}',
        );
      }

      return payments;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت پرداخت‌های مستقیم: $e');
      }
      return [];
    }
  }
}
