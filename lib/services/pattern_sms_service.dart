import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:http/http.dart' as http;

/// ارسال پیامک الگویی (BaseServiceNumber) از طریق پیامک‌پنل / ملی‌پیامک.
class PatternSmsService {
  /// ارسال پیامک با bodyId و پارامترهای الگو ({0};{1};...)
  static Future<bool> sendPattern({
    required String phoneNumber,
    required int bodyId,
    required List<String> parameters,
  }) async {
    if (bodyId <= 0) {
      if (kDebugMode) {
        debugPrint('PatternSmsService: invalid bodyId ($bodyId)');
      }
      return false;
    }

    final username = AppConfig.smsApiUsername;
    final password = AppConfig.smsApiPassword;
    if (username.isEmpty || password.isEmpty) {
      if (kDebugMode) {
        debugPrint('PatternSmsService: SMS credentials not configured');
      }
      return false;
    }

    final normalized = _normalizePhoneNumber(phoneNumber);
    if (normalized.isEmpty) {
      if (kDebugMode) {
        debugPrint('PatternSmsService: empty phone number');
      }
      return false;
    }

    final internationalPhone = _toInternationalPhone(normalized);
    final text = parameters.map((p) => p.trim()).join(';');

    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.smsApiBaseUrl),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {
              'username': username,
              'password': password,
              'to': internationalPhone,
              'text': text,
              'bodyId': bodyId.toString(),
            },
          )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint(
          'PatternSmsService: bodyId=$bodyId to=$internationalPhone '
          'status=${response.statusCode} body=${response.body}',
        );
      }

      if (response.statusCode != 200) return false;

      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['StrRetStatus'] == '1' ||
            data['RetStatus'] == 1 ||
            data['success'] == true ||
            (data['status'] != null &&
                (data['status'] == 'success' || data['status'] == 200));
      } catch (_) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PatternSmsService error: $e');
      }
      return false;
    }
  }

  /// نام کوتاه برای پارامتر {0} الگوهای پیامک.
  static Future<String> displayNameForProfile(String profileOrAuthId) async {
    try {
      final row =
          await ProfileRepository.instance.fetchProfile(profileOrAuthId);
      return ProfileRepository.instance.displayNameFromMap(
        row,
        fallback: 'کاربر',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PatternSmsService.displayNameForProfile: $e');
      }
      return 'کاربر';
    }
  }

  /// شماره موبایل از profiles (با id پروفایل یا auth_user_id).
  static Future<String?> phoneForProfile(String profileOrAuthId) async {
    try {
      final row =
          await ProfileRepository.instance.fetchProfile(profileOrAuthId);
      final phone = (row?['phone_number'] as String?)?.trim() ?? '';
      return phone.isNotEmpty ? phone : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PatternSmsService.phoneForProfile: $e');
      }
      return null;
    }
  }

  static String _normalizePhoneNumber(String phoneNumber) {
    var normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    if (!normalized.startsWith('0') && normalized.length == 10) {
      normalized = '0$normalized';
    }
    return normalized;
  }

  static String _toInternationalPhone(String phoneNumber) {
    if (phoneNumber.startsWith('0')) {
      return '98${phoneNumber.substring(1)}';
    }
    if (!phoneNumber.startsWith('98')) {
      return '98$phoneNumber';
    }
    return phoneNumber;
  }
}
