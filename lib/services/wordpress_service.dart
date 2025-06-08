import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class WordPressService {
  // آدرس API وردپرس - این آدرس را با آدرس واقعی سایت وردپرس خود جایگزین کنید
  final String baseUrl = 'https://gymaipro.ir/wp-json/gymai/v1';

  // آدرس‌های جایگزین برای آزمایش اتصال
  final List<String> alternativeUrls = [
    'https://gymaipro.ir/wp-json/gymai/v1',
    'https://www.gymaipro.ir/wp-json/gymai/v1',
    'http://gymaipro.ir/wp-json/gymai/v1',
    'https://gymaipro.ir/index.php/wp-json/gymai/v1',
  ];

  // روش برای تست اتصال به API وردپرس
  Future<bool> testConnection() async {
    try {
      print('تست اتصال به API وردپرس: $baseUrl/test');

      final response = await http.get(Uri.parse('$baseUrl/test'));

      print('کد وضعیت پاسخ تست: ${response.statusCode}');
      print('پاسخ تست: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('خطا در تست اتصال به API وردپرس: $e');

      // تلاش با آدرس‌های جایگزین
      for (final url in alternativeUrls) {
        if (url == baseUrl) continue; // اگر همان آدرس اصلی است، رد کن

        try {
          print('تلاش با آدرس جایگزین: $url/test');
          final altResponse = await http.get(Uri.parse('$url/test'));
          print('کد وضعیت پاسخ جایگزین: ${altResponse.statusCode}');

          if (altResponse.statusCode == 200) {
            print('آدرس جایگزین موفق: $url');
            return true;
          }
        } catch (altError) {
          print('خطا با آدرس جایگزین $url: $altError');
        }
      }

      return false;
    }
  }

  // تبدیل شماره موبایل به فرمت مناسب برای وردپرس (فقط حذف صفر ابتدایی)
  String normalizePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return phoneNumber;
    }

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

    print('تبدیل شماره موبایل از $phoneNumber به $normalized');

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

  // به‌روزرسانی پروفایل کاربر در وردپرس
  Future<Map<String, dynamic>> updateUserProfile(
      String mobile, Map<String, dynamic> profileData) async {
    try {
      // تبدیل شماره موبایل به فرمت بدون صفر
      final normalizedMobile = normalizePhoneNumber(mobile);

      print('************ شروع به‌روزرسانی پروفایل در وردپرس ************');
      print('شماره موبایل اصلی: $mobile');
      print('شماره موبایل نرمال شده: $normalizedMobile');
      print('داده‌های پروفایل برای ارسال: $profileData');

      // اطمینان از وجود فیلدهای متادیتای مورد نیاز
      Map<String, dynamic> metaData = Map.from(profileData);

      // اطمینان از وجود فیلد profile_picture برای متادیتا
      if (profileData.containsKey('avatar_url') &&
          profileData['avatar_url'] != null &&
          profileData['avatar_url'].toString().isNotEmpty &&
          !profileData.containsKey('profile_picture')) {
        metaData['profile_picture'] = profileData['avatar_url'];
      }

      // تبدیل تمام مقادیر عددی و تاریخ به string
      for (var key in metaData.keys.toList()) {
        if (metaData[key] is num || metaData[key] is DateTime) {
          metaData[key] = metaData[key].toString();
        }
      }

      final requestBody = {
        'mobile': normalizedMobile,
        'profile_data': metaData,
      };

      print('داده‌های نهایی برای ارسال به API: ${jsonEncode(requestBody)}');
      print('آدرس API: $baseUrl/update-profile');

      // تنظیم timeout برای درخواست به 15 ثانیه
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse('$baseUrl/update-profile'),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 15));

        print('کد وضعیت پاسخ: ${response.statusCode}');
        print('پاسخ دریافتی از API وردپرس: ${response.body}');

        if (response.statusCode == 200) {
          Map<String, dynamic> data;
          try {
            data = jsonDecode(response.body);
          } catch (e) {
            print('خطا در تجزیه پاسخ JSON: $e');
            return {
              'success': false,
              'error': 'پاسخ دریافتی از سرور قابل پردازش نیست',
            };
          }

          print('داده‌های دریافتی از وردپرس: $data');
          print('فیلدهای به‌روزرسانی شده: ${data['updated_fields']}');
          return {
            'success': data['success'] == true,
            'user_id': data['user_id'],
            'updated_fields': data['updated_fields'],
            'message': data['message'],
          };
        } else {
          print(
              'خطا در به‌روزرسانی پروفایل کاربر در وردپرس: ${response.statusCode}');
          print('پیام خطا: ${response.body}');
          return {
            'success': false,
            'error': 'خطا در اتصال به سرور وردپرس: ${response.statusCode}',
            'body': response.body
          };
        }
      } finally {
        client.close();
      }
    } on http.ClientException catch (e) {
      print('خطای HTTP در به‌روزرسانی پروفایل کاربر در وردپرس: $e');
      return {'success': false, 'error': 'خطای شبکه: ${e.message}'};
    } on TimeoutException catch (e) {
      print('خطای timeout در به‌روزرسانی پروفایل کاربر در وردپرس: $e');
      return {'success': false, 'error': 'زمان پاسخگویی سرور به پایان رسید'};
    } catch (e) {
      print('استثنا در به‌روزرسانی پروفایل کاربر در وردپرس: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      print('************ پایان به‌روزرسانی پروفایل در وردپرس ************');
    }
  }
}
