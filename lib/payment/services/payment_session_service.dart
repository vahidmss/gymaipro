import 'package:flutter/foundation.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت جلسات پرداخت
class PaymentSessionService {
  factory PaymentSessionService() => _instance;
  PaymentSessionService._internal();
  static final PaymentSessionService _instance =
      PaymentSessionService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// ایجاد جلسه پرداخت جدید
  Future<String?> createPaymentSession({
    required int amount,
    int? expirationMinutes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        if (kDebugMode) {
          print('کاربر وارد نشده است');
        }
        return null;
      }

      // تولید شناسه جلسه منحصر به فرد
      final sessionId =
          'session_${DateTime.now().millisecondsSinceEpoch}_$userId';

      // زمان انقضا (پیش‌فرض: 30 دقیقه)
      final expMinutes = expirationMinutes ?? 30;
      final expiresAt = DateTime.now().add(Duration(minutes: expMinutes));

      // ایجاد جلسه در دیتابیس
      final response = await _client
          .from('payment_sessions')
          .insert({
            'session_id': sessionId,
            'user_id': userId,
            'amount': amount,
            'status': 'pending',
            'expires_at': expiresAt.toIso8601String(),
            'metadata': {'created_from': 'mobile_app', 'app_version': '1.0.0'},
          })
          .select('session_id')
          .single();

      if (kDebugMode) {
        print('جلسه پرداخت ایجاد شد: $sessionId');
      }

      return response['session_id'] as String;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در ایجاد جلسه پرداخت: $e');
      }
      return null;
    }
  }

  /// دریافت وضعیت جلسه پرداخت
  Future<Map<String, dynamic>?> getSessionStatus(String sessionId) async {
    try {
      final response = await _client
          .from('payment_sessions')
          .select()
          .eq('session_id', sessionId)
          .single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت وضعیت جلسه: $e');
      }
      return null;
    }
  }

  /// به‌روزرسانی وضعیت جلسه
  Future<bool> updateSessionStatus({
    required String sessionId,
    required String status,
    String? gateway,
    String? gatewayRef,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (gateway != null) updateData['gateway'] = gateway;
      if (gatewayRef != null) updateData['gateway_ref'] = gatewayRef;
      if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }
      if (metadata != null) {
        updateData['metadata'] = metadata.toString();
      }

      await _client
          .from('payment_sessions')
          .update(updateData)
          .eq('session_id', sessionId);

      if (kDebugMode) {
        print('وضعیت جلسه به‌روزرسانی شد: $sessionId -> $status');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در به‌روزرسانی جلسه: $e');
      }
      return false;
    }
  }

  /// دریافت تاریخچه جلسات پرداخت کاربر
  Future<List<Map<String, dynamic>>> getUserSessions({
    int limit = 20,
    int offset = 0,
    String? status,
  }) async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return [];

      PostgrestFilterBuilder<dynamic> query = _client
          .from('payment_sessions')
          .select()
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response as Iterable<dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت تاریخچه جلسات: $e');
      }
      return [];
    }
  }

  /// پاک کردن جلسات منقضی شده
  Future<bool> cleanupExpiredSessions() async {
    try {
      await _client.rpc<void>('cleanup_expired_payment_sessions');

      if (kDebugMode) {
        print('جلسات منقضی پاک شدند');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در پاک کردن جلسات منقضی: $e');
      }
      return false;
    }
  }

  /// بررسی انقضای جلسه
  bool isSessionExpired(Map<String, dynamic> session) {
    try {
      final expiresAt = DateTime.parse(session['expires_at'] as String);
      return DateTime.now().isAfter(expiresAt);
    } catch (e) {
      return true; // در صورت خطا، جلسه را منقضی در نظر بگیر
    }
  }

  /// دریافت جلسات در انتظار
  Future<List<Map<String, dynamic>>> getPendingSessions() async {
    return getUserSessions(status: 'pending');
  }

  /// دریافت جلسات تکمیل شده
  Future<List<Map<String, dynamic>>> getCompletedSessions() async {
    return getUserSessions(status: 'completed');
  }

  /// دریافت جلسات ناموفق
  Future<List<Map<String, dynamic>>> getFailedSessions() async {
    return getUserSessions(status: 'failed');
  }
}
