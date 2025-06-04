import 'dart:convert';
import 'package:http/http.dart' as http;

class WordPressService {
  // آدرس API وردپرس - این آدرس را با آدرس واقعی سایت وردپرس خود جایگزین کنید
  final String baseUrl = 'https://gymaipro.ir/wp-json/gymai/v1';

  // تبدیل شماره موبایل به فرمت بدون صفر در ابتدا
  String normalizePhoneNumber(String phoneNumber) {
    // حذف فاصله‌ها و کاراکترهای اضافی
    String normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    normalized = normalized.replaceAll(RegExp(r'[^\d]'), '');

    // فقط حذف صفر ابتدایی اگر وجود داشته باشد - حفظ بقیه ارقام
    if (normalized.startsWith('0')) {
      normalized = normalized.substring(1);
    }

    // حذف کد کشور اگر وجود داشته باشد
    if (normalized.startsWith('98')) {
      normalized = normalized.substring(2);
    }

    return normalized;
  }

  // ثبت نام کاربر در وردپرس
  Future<Map<String, dynamic>?> registerUser(
      String username, String mobile) async {
    try {
      // تبدیل شماره موبایل به فرمت بدون صفر
      final normalizedMobile = normalizePhoneNumber(mobile);

      print(
          'تلاش برای ثبت نام کاربر در وردپرس - نام کاربری: $username، موبایل: $normalizedMobile');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'mobile': normalizedMobile,
        }),
      );

      print('پاسخ API وردپرس: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('ثبت نام در وردپرس موفقیت‌آمیز بود: $data');
        return data;
      } else if (response.statusCode == 409) {
        // کاربر قبلاً وجود دارد
        print('خطای تکراری بودن کاربر در وردپرس');
        throw Exception(
            'کاربری با این نام کاربری یا شماره موبایل قبلاً ثبت شده است');
      } else {
        // خطای دیگر
        print('خطای API وردپرس: ${response.statusCode} - ${response.body}');
        Map<String, dynamic> errorData = {};
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          // اگر پاسخ قابل تبدیل به JSON نبود
        }

        final errorMessage =
            errorData['message'] ?? 'خطا در ارتباط با سرور وردپرس';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('خطا در ثبت نام در وردپرس: $e');
      // بازگرداندن null به معنی عدم موفقیت است
      rethrow;
    }
  }

  // بررسی وجود کاربر در وردپرس با استفاده از شماره موبایل
  Future<Map<String, dynamic>> checkUserExists(String mobile) async {
    try {
      // تبدیل شماره موبایل به فرمت بدون صفر
      final normalizedMobile = normalizePhoneNumber(mobile);

      print('بررسی وجود کاربر در وردپرس با شماره موبایل: $normalizedMobile');

      final response = await http.get(
        Uri.parse('$baseUrl/check-user?mobile=$normalizedMobile'),
      );

      print(
          'پاسخ API وردپرس (بررسی وجود کاربر): ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('نتیجه بررسی وجود کاربر: ${data['exists']}');

        return {
          'exists': data['exists'] == true,
          'user_id': data['user_id'],
          'found_in': data['found_in'],
          'user_data': data['user_data'],
          'smart_login_data': data['smart_login_data'],
        };
      } else {
        print('خطا در بررسی وجود کاربر: ${response.statusCode}');
        return {'exists': false, 'error': 'خطا در اتصال به سرور وردپرس'};
      }
    } catch (e) {
      print('خطا در بررسی وجود کاربر در وردپرس: $e');
      return {'exists': false, 'error': e.toString()};
    }
  }
}
