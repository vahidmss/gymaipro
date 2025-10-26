import 'package:supabase_flutter/supabase_flutter.dart';

class OTPService {
  // These constants are kept for future use
  // static const String _baseUrl =
  //     'https://rest.payamak-panel.com/api/SendSMS/BaseServiceNumber';
  // static const String _username = '1990557589';
  // static const String _password = '08918b92-394d-4d42-a2a5-8828112ded71';
  // static const int _bodyId = 318085;

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

      // فقط لاگ کن و پیامک ارسال نکن (در محیط توسعه)
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
    String phoneNumber,
    String code,
  ) async {
    try {
      final client = Supabase.instance.client;
      final expiresAt = DateTime.now().add(const Duration(minutes: 2));

      // تلاش برای ذخیره کد OTP - روش بهینه‌شده
      await client.from('otp_codes').insert({
        'phone_number': phoneNumber,
        'code': code,
        'expires_at': expiresAt.toIso8601String(),
        'is_used': false,
      });

      return true;
    } catch (e) {
      print('Error saving OTP to Supabase: $e');
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
    String phoneNumber,
    String code,
  ) async {
    try {
      final client = Supabase.instance.client;

      // بررسی OTP در Supabase با کوئری بهینه‌شده
      final response = await client
          .from('otp_codes')
          .select('id')
          .eq('phone_number', phoneNumber)
          .eq('code', code)
          .eq('is_used', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (response != null) {
        try {
          // علامت‌گذاری OTP به عنوان استفاده شده
          await client
              .from('otp_codes')
              .update({
                'is_used': true,
                'used_at': DateTime.now().toIso8601String(),
              })
              .eq('id', response['id'] as Object);

          return true;
        } catch (e) {
          // اگر OTP معتبر است اما نتوانستیم آن را علامت‌گذاری کنیم
          print('Error marking OTP as used: $e');
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
    // تولید کد 6 رقمی تصادفی - روش بهینه‌شده
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString();
  }
}
