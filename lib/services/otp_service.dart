import 'package:supabase_flutter/supabase_flutter.dart';

class OTPService {
  static const String _baseUrl =
      'https://rest.payamak-panel.com/api/SendSMS/BaseServiceNumber';
  static const String _username = '1990557589';
  static const String _password = '08918b92-394d-4d42-a2a5-8828112ded71';
  static const int _bodyId = 318085;

  // Normalize phone number format
  static String normalizePhoneNumber(String phoneNumber) {
    // Remove any spaces or special characters
    String normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');

    // Ensure it starts with 0
    if (!normalized.startsWith('0')) {
      normalized = '0$normalized';
    }

    return normalized;
  }

  static Future<bool> sendOTP(String phoneNumber, String code) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      // فقط لاگ کن و پیامک ارسال نکن
      print('==============================');
      print('      ⚡️ OTP CODE FOR TEST ⚡️');
      print('      PHONE: $normalizedPhone');
      print('      OTP:   $code');
      print('==============================');

      // ذخیره OTP در دیتابیس Supabase
      return await _saveOtpToSupabase(normalizedPhone, code);
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // ذخیره OTP در دیتابیس Supabase
  static Future<bool> _saveOtpToSupabase(
      String phoneNumber, String code) async {
    try {
      final client = Supabase.instance.client;
      final expiresAt = DateTime.now()
          .add(const Duration(minutes: 2)); // افزایش زمان انقضا به ۲ دقیقه

      // ابتدا RLS را بررسی کنیم
      try {
        print('Testing RLS with an SQL query');
        await client.rpc('check_user_exists', params: {
          'phone': phoneNumber,
        });
        print('RPC call successful, database connection works');
      } catch (e) {
        print('RPC test failed: $e');
      }

      // روش اول: استفاده از insert با select
      try {
        print('Trying insertion with select');
        final insertResponse = await client.from('otp_codes').insert({
          'phone_number': phoneNumber,
          'code': code,
          'expires_at': expiresAt.toIso8601String(),
          'is_used': false,
        }).select();

        print('Insert response: $insertResponse');
        return insertResponse.isNotEmpty;
      } catch (e) {
        print('Error with insert+select: $e');

        // روش دوم: فقط insert بدون select
        try {
          print('Trying insertion without select');
          await client.from('otp_codes').insert({
            'phone_number': phoneNumber,
            'code': code,
            'expires_at': expiresAt.toIso8601String(),
            'is_used': false,
          });

          print('Insert without select successful');
          return true;
        } catch (e2) {
          print('Error with insert-only: $e2');

          // روش سوم: استفاده از SQL مستقیم
          try {
            print('Trying direct SQL execution');
            await client.rpc('insert_otp_code', params: {
              'p_phone_number': phoneNumber,
              'p_code': code,
              'p_expires_at': expiresAt.toIso8601String(),
            });

            print('Direct SQL execution successful');
            return true;
          } catch (e3) {
            print('Error with direct SQL: $e3');
            return false;
          }
        }
      }
    } catch (e) {
      print('Error saving OTP to Supabase: $e');
      if (e is PostgrestException) {
        print(
            'PostgrestException details: ${e.message}, code: ${e.code}, details: ${e.details}');
      }
      return false;
    }
  }

  static Future<bool> verifyOTP(String phoneNumber, String code) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      // بررسی OTP در Supabase
      return await _verifyOtpInSupabase(normalizedPhone, code);
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // بررسی OTP در دیتابیس Supabase
  static Future<bool> _verifyOtpInSupabase(
      String phoneNumber, String code) async {
    try {
      final client = Supabase.instance.client;

      // بررسی OTP در Supabase
      final response = await client
          .from('otp_codes')
          .select()
          .eq('phone_number', phoneNumber)
          .eq('code', code)
          .eq('is_used', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (response != null) {
        try {
          // علامت‌گذاری OTP به عنوان استفاده شده
          await client.from('otp_codes').update({
            'is_used': true,
            'used_at': DateTime.now().toIso8601String(),
          }).eq('id', response['id']);

          return true;
        } catch (e) {
          print('Error marking OTP as used in Supabase: $e');
          // اگر OTP معتبر است اما نتوانستیم آن را علامت‌گذاری کنیم
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error verifying OTP in Supabase: $e');
      return false;
    }
  }

  static String generateOTP() {
    // تولید کد 6 رقمی تصادفی
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString();
  }
}
