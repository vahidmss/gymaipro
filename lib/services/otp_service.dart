import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/auth/utils/otp_autofill_helper.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/core/client_secret_guard.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class OTPService {
  static String normalizePhoneNumber(String phoneNumber) {
    String normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    if (!normalized.startsWith('0')) {
      normalized = '0$normalized';
    }
    return normalized;
  }

  /// ارسال OTP — روی وب/حالت امن فقط از Edge Function `send-otp`.
  static Future<bool> sendOTP(String phoneNumber) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      if (AppConfig.otpUseServerRoute) {
        return _sendViaServer(normalizedPhone);
      }

      if (ClientSecretGuard.blocksClientSmsCredentials) {
        debugPrint('OTP: client route blocked on web — use server Edge Function');
        return false;
      }

      final code = generateOTP();
      return _sendViaClient(normalizedPhone, code);
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  static Future<bool> _sendViaServer(String normalizedPhone) async {
    try {
      final appSignature = await OtpAutofillHelper.fetchAppSignature();

      final response = await Supabase.instance.client.functions.invoke(
        'send-otp',
        body: {
          'phone_number': normalizedPhone,
          if (appSignature != null) 'app_signature': appSignature,
        },
      );

      final data = _decodeResponseData(response.data);
      if (data == null) {
        debugPrint('send-otp: empty response');
        return false;
      }

      if (data['error'] != null) {
        debugPrint('send-otp error: ${data['error']}');
        return false;
      }

      return data['ok'] == true;
    } on FunctionException catch (e) {
      debugPrint('send-otp FunctionException: ${e.details}');
      return false;
    } catch (e) {
      debugPrint('send-otp failed: $e');
      return false;
    }
  }

  static Future<bool> _sendViaClient(
    String normalizedPhone,
    String code,
  ) async {
    String? appSignature;
    try {
      appSignature = await OtpAutofillHelper.fetchAppSignature();
    } catch (e) {
      debugPrint('⚠️ Could not get app signature: $e');
    }

    final smsSent = await _sendRealSMS(normalizedPhone, code, appSignature);
    if (!smsSent) {
      debugPrint('⚠️ Warning: Failed to send SMS, but saving OTP to database');
    }

    return _saveOtpToSupabase(normalizedPhone, code);
  }

  static Future<bool> _sendRealSMS(
    String phoneNumber,
    String code,
    String? appSignature,
  ) async {
    try {
      final baseUrl = AppConfig.smsApiBaseUrl;
      final username = AppConfig.smsApiUsername;
      final password = AppConfig.smsApiPassword;
      final bodyId = AppConfig.smsApiBodyId;

      if (username.isEmpty || password.isEmpty || bodyId == 0) {
        if (kDebugMode) {
          debugPrint('❌ SMS API credentials not configured');
        }
        return false;
      }

      String internationalPhone = phoneNumber;
      if (internationalPhone.startsWith('0')) {
        internationalPhone = '98${internationalPhone.substring(1)}';
      } else if (!internationalPhone.startsWith('98')) {
        internationalPhone = '98$internationalPhone';
      }

      final String message;
      if (bodyId > 0) {
        message = OtpAutofillHelper.payamakPatternText(code, appSignature);
      } else {
        message = OtpAutofillHelper.freeTextMessage(code, appSignature);
      }

      final url = Uri.parse(baseUrl);
      final requestBody = {
        'username': username,
        'password': password,
        'to': internationalPhone,
        'text': message,
        'bodyId': bodyId.toString(),
      };

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

      if (response.statusCode == 200) {
        try {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;
          return responseData['StrRetStatus'] == '1' ||
              responseData['RetStatus'] == 1 ||
              responseData['success'] == true ||
              (responseData['status'] != null &&
                  (responseData['status'] == 'success' ||
                      responseData['status'] == 200));
        } catch (_) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error in _sendRealSMS: $e');
      return false;
    }
  }

  static Future<bool> _saveOtpToSupabase(
    String phoneNumber,
    String code,
  ) async {
    try {
      final client = Supabase.instance.client;
      final expiresAt = DateTime.now().add(const Duration(minutes: 2));

      await client.from('otp_codes').insert({
        'phone_number': phoneNumber,
        'code': code,
        'expires_at': expiresAt.toIso8601String(),
        'is_used': false,
      });

      return true;
    } catch (e) {
      debugPrint('Error saving OTP to Supabase: $e');
      return false;
    }
  }

  static Future<bool> verifyOTP(String phoneNumber, String code) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      if (AppConfig.otpUseServerRoute) {
        return _verifyViaServer(normalizedPhone, code);
      }

      if (ClientSecretGuard.blocksClientSmsCredentials) {
        debugPrint('OTP verify: client route blocked on web');
        return false;
      }

      return _verifyOtpInSupabase(normalizedPhone, code);
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return false;
    }
  }

  static Future<bool> _verifyViaServer(String phoneNumber, String code) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'verify-otp',
        body: {
          'phone_number': phoneNumber,
          'code': code.trim(),
        },
      );

      final data = _decodeResponseData(response.data);
      return data?['ok'] == true;
    } on FunctionException catch (e) {
      debugPrint('verify-otp FunctionException: ${e.details}');
      return false;
    } catch (e) {
      debugPrint('verify-otp failed: $e');
      return false;
    }
  }

  static Future<bool> _verifyOtpInSupabase(
    String phoneNumber,
    String code,
  ) async {
    try {
      final client = Supabase.instance.client;

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
          await client
              .from('otp_codes')
              .update({
                'is_used': true,
                'used_at': DateTime.now().toIso8601String(),
              })
              .eq('id', response['id'] as Object);
          return true;
        } catch (e) {
          debugPrint('Error marking OTP as used: $e');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error verifying OTP in Supabase: $e');
      return false;
    }
  }

  static Map<String, dynamic>? _decodeResponseData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  static String generateOTP() {
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString();
  }
}
