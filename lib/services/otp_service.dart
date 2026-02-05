import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gymaipro/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sms_autofill/sms_autofill.dart' as sms;

class OTPService {
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

      // دریافت App Signature برای Android SMS Retriever API
      String? appSignature;
      try {
        appSignature = await sms.SmsAutoFill().getAppSignature;
        print('📱 App Signature for SMS: $appSignature');
      } catch (e) {
        print('⚠️ Could not get app signature: $e');
      }

      // ارسال پیامک واقعی
      final smsSent = await _sendRealSMS(normalizedPhone, code, appSignature);

      if (!smsSent) {
        print('⚠️ Warning: Failed to send SMS, but saving OTP to database');
      }

      // ذخیره OTP در دیتابیس Supabase (حتی اگر پیامک ارسال نشد)
      final saved = await _saveOtpToSupabase(normalizedPhone, code);

      return saved;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  /// ارسال پیامک واقعی از طریق API پیامک پنل
  static Future<bool> _sendRealSMS(
    String phoneNumber,
    String code,
    String? appSignature,
  ) async {
    try {
      // بررسی وجود تنظیمات SMS API
      final baseUrl = AppConfig.smsApiBaseUrl;
      final username = AppConfig.smsApiUsername;
      final password = AppConfig.smsApiPassword;
      final bodyId = AppConfig.smsApiBodyId;

      if (username.isEmpty || password.isEmpty || bodyId == 0) {
        if (kDebugMode) {
          print('❌ SMS API credentials not configured');
          print(
            'Please set SMS_API_USERNAME, SMS_API_PASSWORD, and SMS_API_BODY_ID',
          );
        }
        return false;
      }

      // تبدیل شماره تلفن به فرمت بین‌المللی (بدون 0 اول)
      String internationalPhone = phoneNumber;
      if (internationalPhone.startsWith('0')) {
        internationalPhone = '98${internationalPhone.substring(1)}';
      } else if (!internationalPhone.startsWith('98')) {
        internationalPhone = '98$internationalPhone';
      }

      // ساخت متن پیامک با فرمت Android SMS Retriever API
      // فرمت: <#> Your verification code is: 123456\nAppSignatureHash
      final String message;
      if (appSignature != null && appSignature.isNotEmpty) {
        // استفاده از فرمت Android SMS Retriever برای Auto-fill
        message = '<#> کد تایید شما: $code\n$appSignature';
        print('📱 Using Android SMS Retriever format with signature');
      } else {
        // فرمت عادی اگر signature در دسترس نباشد
        message = 'کد تایید شما: $code\nGymAI Pro';
        print('⚠️ App signature not available, using regular format');
      }

      // ساخت درخواست
      final url = Uri.parse(baseUrl);

      // استفاده از form-data (فرمت استاندارد API پیامک پنل)
      final requestBody = {
        'username': username,
        'password': password,
        'to': internationalPhone,
        'text': message,
        'bodyId': bodyId.toString(),
      };

      print('📱 Sending SMS to: $internationalPhone');
      print('📝 Message: $message');

      // ارسال درخواست با form-data
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      print('📡 SMS API Response: ${response.statusCode}');
      print('📡 SMS API Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;

          // بررسی پاسخ API (بسته به فرمت پاسخ API پیامک پنل)
          // معمولاً اگر موفق باشد، یک فیلد success یا status دارد
          final isSuccess =
              responseData['StrRetStatus'] == '1' ||
              responseData['RetStatus'] == 1 ||
              responseData['success'] == true ||
              (responseData['status'] != null &&
                  (responseData['status'] == 'success' ||
                      responseData['status'] == 200));

          if (isSuccess) {
            print('✅ SMS sent successfully');
            return true;
          } else {
            print('❌ SMS API returned error: ${responseData.toString()}');
            return false;
          }
        } catch (e) {
          // اگر JSON parse نشد، اما status code 200 بود، احتمالاً موفق بوده
          print('⚠️ Could not parse response, but status is 200: $e');
          return true;
        }
      } else {
        print('❌ SMS API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error in _sendRealSMS: $e');
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
