import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس تاریخچه پرداخت ها
class PaymentHistoryService {
  factory PaymentHistoryService() => _instance;
  PaymentHistoryService._internal();
  static final PaymentHistoryService _instance =
      PaymentHistoryService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// دریافت پرداخت های مستقیم کاربر با صفحه بندی
  Future<List<PaymentTransaction>> getDirectPayments({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return [];

      final response = await _client
          .from('payment_transactions')
          .select()
          .eq('user_id', userId)
          .eq('payment_method', PaymentMethod.direct.toString().split('.').last)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map(
            (json) => PaymentTransaction.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت پرداخت های مستقیم: $e');
      }
      return [];
    }
  }
}
