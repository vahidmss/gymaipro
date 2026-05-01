import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// سرویس ساده برای تشخیص کشور کاربر بر اساس آی‌پی عمومی.
///
/// فقط برای نمایش هشدار تجربه بهتر (مثلاً وی‌پی‌ان) استفاده می‌شود
/// و وابستگی بیزنسی ندارد؛ اگر خطا دهد، ساکت fail می‌شود.
class IpCountryService {
  IpCountryService._();

  static Future<String?> _loadCountryCode() async {
    try {
      final uri = Uri.parse('https://ipapi.co/json/');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      final code = data['country_code'] as String?;
      return code?.toUpperCase();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('IpCountryService: failed to detect country: $e');
      }
      return null;
    }
  }

  static Future<String?>? _cachedFuture;

  /// یک future کش‌شده برمی‌گرداند تا فقط یک‌بار درخواست شبکه ارسال شود.
  static Future<String?> getCountryCodeOnce() {
    _cachedFuture ??= _loadCountryCode();
    return _cachedFuture!;
  }
}

