import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class WordPressAuthService {
  // آدرس API وردپرس - این آدرس را با آدرس واقعی سایت وردپرس خود جایگزین کنید
  final String baseUrl = 'https://gymaipro.ir/wp-json/gymai/v1';

  /// ارسال توکن Supabase به وردپرس برای ذخیره‌سازی
  Future<bool> syncAuthTokenWithWordPress(String phoneNumber) async {
    try {
      print('شروع همگام‌سازی توکن با وردپرس...');

      // دریافت توکن فعلی از Supabase
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        print('هیچ نشست فعالی یافت نشد');
        return false;
      }

      // نرمال‌سازی شماره موبایل (حذف صفر ابتدایی)
      String normalizedPhone = phoneNumber;
      if (normalizedPhone.startsWith('0')) {
        normalizedPhone = normalizedPhone.substring(1);
      }

      print('ارسال توکن به وردپرس برای شماره: $normalizedPhone');

      // تبدیل زمان انقضا به یک فرمت قابل استفاده
      String expiresAtStr = '';
      if (session.expiresAt != null) {
        final expiresAtDate =
            DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
        expiresAtStr = expiresAtDate.toIso8601String();
      }

      // ارسال درخواست به API وردپرس با timeout
      final response = await http
          .post(
            Uri.parse('$baseUrl/store-token'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'mobile': normalizedPhone,
              'access_token': session.accessToken,
              'refresh_token': session.refreshToken,
              'expires_at': expiresAtStr,
            }),
          )
          .timeout(const Duration(seconds: 5));

      print('کد وضعیت پاسخ: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('توکن با موفقیت در وردپرس ذخیره شد');
        return true;
      } else {
        print('خطا در ذخیره توکن');
        return false;
      }
    } catch (e) {
      print('خطا در همگام‌سازی توکن: $e');
      return false;
    }
  }

  /// تنظیم کوکی در وردپرس از طریق API
  Future<bool> setCookieInWordPress(String phoneNumber) async {
    try {
      print('تنظیم کوکی در وردپرس...');

      // دریافت توکن فعلی از Supabase
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        print('هیچ نشست فعالی یافت نشد');
        return false;
      }

      // نرمال‌سازی شماره موبایل (حذف صفر ابتدایی)
      String normalizedPhone = phoneNumber;
      if (normalizedPhone.startsWith('0')) {
        normalizedPhone = normalizedPhone.substring(1);
      }

      print('ارسال درخواست تنظیم کوکی برای شماره: $normalizedPhone');

      // ارسال درخواست به API وردپرس با timeout
      final response = await http
          .post(
            Uri.parse('$baseUrl/set-cookie'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'mobile': normalizedPhone,
              'token': session.accessToken,
            }),
          )
          .timeout(const Duration(seconds: 5));

      print('کد وضعیت پاسخ تنظیم کوکی: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('کوکی با موفقیت در وردپرس تنظیم شد');
        return true;
      } else {
        print('خطا در تنظیم کوکی');
        return false;
      }
    } catch (e) {
      print('خطا در تنظیم کوکی: $e');
      return false;
    }
  }
}
