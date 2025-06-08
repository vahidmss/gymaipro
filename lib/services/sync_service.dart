import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'wordpress_service.dart';
import 'package:shamsi_date/shamsi_date.dart';

class SyncService {
  final SupabaseService _supabaseService = SupabaseService();
  final WordPressService _wordpressService = WordPressService();

  // تست اتصال به API وردپرس
  Future<bool> testWordPressConnection() async {
    return await _wordpressService.testConnection();
  }

  // ثبت نام همزمان در وردپرس و سوپابیس
  Future<Map<String, dynamic>> syncRegister(
      String username, String phoneNumber) async {
    try {
      // نرمال‌سازی شماره موبایل برای سوپابیس (با صفر ابتدایی)
      final normalizedPhone =
          _supabaseService.normalizePhoneNumber(phoneNumber);

      // نرمال‌سازی شماره موبایل برای وردپرس (بدون صفر ابتدایی)
      final normalizedPhoneWP =
          _supabaseService.normalizePhoneNumberForWordPress(phoneNumber);

      print(
          'شروع فرآیند ثبت نام همزمان با شماره: $normalizedPhone (وردپرس: $normalizedPhoneWP)');

      // بررسی وجود کاربر در وردپرس
      final wpCheckResult =
          await _wordpressService.checkUserExists(normalizedPhoneWP);
      final existsInWordPress = wpCheckResult['exists'] == true;

      // بررسی وجود کاربر در سوپابیس
      final existsInSupabase =
          await _supabaseService.doesUserExist(normalizedPhone);

      print(
          'وضعیت وجود کاربر - وردپرس: $existsInWordPress، سوپابیس: $existsInSupabase');

      // اگر کاربر در وردپرس وجود داشت، در سوپابیس ثبت نام نکن
      if (existsInWordPress) {
        return {
          'success': false,
          'message': 'کاربری با این شماره موبایل قبلاً در سایت ثبت شده است',
          'exists_in': 'wordpress'
        };
      }

      // اگر کاربر در سوپابیس وجود داشت، ابتدا خطا نشان بده
      if (existsInSupabase) {
        return {
          'success': false,
          'message': 'کاربری با این شماره موبایل قبلاً در اپلیکیشن ثبت شده است',
          'exists_in': 'supabase'
        };
      }

      // ثبت نام در وردپرس با شماره بدون صفر
      Map<String, dynamic>? wpResult;
      try {
        wpResult =
            await _wordpressService.registerUser(username, normalizedPhoneWP);
      } catch (e) {
        return {
          'success': false,
          'message': 'خطا در ثبت نام در سایت: ${e.toString()}',
          'exists_in': 'none'
        };
      }

      if (wpResult == null) {
        return {
          'success': false,
          'message': 'خطا در ارتباط با سایت وردپرس',
          'exists_in': 'none'
        };
      }

      // ثبت نام در سوپابیس با شماره با صفر
      Session? session;
      try {
        session =
            await _supabaseService.signUpWithPhone(normalizedPhone, username);
      } catch (e) {
        return {
          'success': false,
          'message':
              'ثبت نام در سایت موفق بود اما در اپلیکیشن با خطا مواجه شد: ${e.toString()}',
          'exists_in': 'wordpress',
          'wordpress_user_id': wpResult['user_id']
        };
      }

      if (session == null) {
        return {
          'success': false,
          'message':
              'ثبت نام در سایت وردپرس موفق بود اما در اپلیکیشن با خطا مواجه شد',
          'exists_in': 'wordpress',
          'wordpress_user_id': wpResult['user_id']
        };
      }

      // ایجاد پروفایل کاربر در سوپابیس
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await _supabaseService.createInitialProfile(
            user,
            normalizedPhone,
            username: username,
          );
        } catch (e) {
          print('خطا در ایجاد پروفایل اولیه: $e');
          // ادامه میدهیم حتی اگر پروفایل ایجاد نشد، چون کاربر در سیستم احراز هویت ثبت شده است
        }
      }

      return {
        'success': true,
        'message': 'ثبت نام با موفقیت انجام شد',
        'wordpress_user_id': wpResult['user_id'],
        'supabase_user_id': user?.id,
        'session': session
      };
    } catch (e) {
      print('خطا در همگام‌سازی ثبت نام: $e');
      return {
        'success': false,
        'message': 'خطا در فرآیند ثبت نام: ${e.toString()}',
        'exists_in': 'none'
      };
    }
  }

  // بررسی همزمان وجود کاربر در هر دو سیستم
  Future<Map<String, dynamic>> checkUserExistenceInBothSystems(
      String phoneNumber) async {
    try {
      // نرمال‌سازی شماره موبایل برای سوپابیس (با صفر ابتدایی)
      final normalizedPhone =
          _supabaseService.normalizePhoneNumber(phoneNumber);

      // نرمال‌سازی شماره موبایل برای وردپرس (بدون صفر ابتدایی)
      final normalizedPhoneWP =
          _supabaseService.normalizePhoneNumberForWordPress(phoneNumber);

      // بررسی همزمان در هر دو سیستم
      final existsInSupabase =
          await _supabaseService.doesUserExist(normalizedPhone);

      final wpCheckResult =
          await _wordpressService.checkUserExists(normalizedPhoneWP);
      final existsInWordPress = wpCheckResult['exists'] == true;

      return {
        'exists_in_supabase': existsInSupabase,
        'exists_in_wordpress': existsInWordPress,
        'wordpress_details': wpCheckResult,
        'synced': existsInSupabase && existsInWordPress,
        'phone_number': normalizedPhone,
        'phone_number_wp': normalizedPhoneWP
      };
    } catch (e) {
      print('خطا در بررسی وجود کاربر: $e');
      return {'error': e.toString(), 'phone_number': phoneNumber};
    }
  }

  // ثبت نام در سوپابیس برای کاربر موجود در وردپرس
  Future<Map<String, dynamic>> registerSupabaseForWordPressUser(
      String username, String phoneNumber) async {
    try {
      // نرمال‌سازی شماره موبایل برای سوپابیس (با صفر ابتدایی)
      final normalizedPhone =
          _supabaseService.normalizePhoneNumber(phoneNumber);

      // نرمال‌سازی شماره موبایل برای وردپرس (بدون صفر ابتدایی)
      final normalizedPhoneWP =
          _supabaseService.normalizePhoneNumberForWordPress(phoneNumber);

      // بررسی وجود کاربر در وردپرس
      final wpCheckResult =
          await _wordpressService.checkUserExists(normalizedPhoneWP);
      final existsInWordPress = wpCheckResult['exists'] == true;

      // بررسی وجود کاربر در سوپابیس
      final existsInSupabase =
          await _supabaseService.doesUserExist(normalizedPhone);

      // اگر کاربر در وردپرس وجود نداشته باشد، خطا برگردان
      if (!existsInWordPress) {
        return {
          'success': false,
          'message': 'کاربر در سایت یافت نشد',
          'exists_in': 'none'
        };
      }

      // اگر کاربر در سوپابیس وجود داشته باشد، خطا برگردان
      if (existsInSupabase) {
        return {
          'success': false,
          'message': 'کاربر در اپلیکیشن از قبل وجود دارد',
          'exists_in': 'supabase'
        };
      }

      // ثبت نام در سوپابیس
      Session? session;
      try {
        session =
            await _supabaseService.signUpWithPhone(normalizedPhone, username);
      } catch (e) {
        return {
          'success': false,
          'message': 'خطا در ثبت نام در اپلیکیشن: ${e.toString()}',
          'exists_in': 'wordpress'
        };
      }

      if (session == null) {
        return {
          'success': false,
          'message': 'خطا در ثبت نام در اپلیکیشن',
          'exists_in': 'wordpress'
        };
      }

      // ایجاد پروفایل کاربر در سوپابیس
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await _supabaseService.createInitialProfile(
            user,
            normalizedPhone,
            username: username,
          );
        } catch (e) {
          print('خطا در ایجاد پروفایل: $e');
          // ادامه میدهیم حتی اگر پروفایل ایجاد نشد
        }
      }

      return {
        'success': true,
        'message': 'ثبت نام در اپلیکیشن با موفقیت انجام شد',
        'wordpress_user_id': wpCheckResult['user_id'],
        'supabase_user_id': user?.id,
        'session': session
      };
    } catch (e) {
      print('خطا در ثبت نام سوپابیس: $e');
      return {
        'success': false,
        'message': 'خطا در فرآیند ثبت نام: ${e.toString()}',
        'exists_in': 'wordpress'
      };
    }
  }

  // همگام‌سازی پروفایل کاربر بین سوپابیس و وردپرس
  Future<Map<String, dynamic>> syncUserProfile(
      String phoneNumber, Map<String, dynamic> profileData) async {
    try {
      // نرمال‌سازی شماره موبایل برای وردپرس (فقط حذف صفر ابتدایی)
      final normalizedPhoneWP =
          _supabaseService.normalizePhoneNumberForWordPress(phoneNumber);

      print(
          'شروع فرآیند همگام‌سازی پروفایل با شماره موبایل: $normalizedPhoneWP');
      print('داده‌های پروفایل برای ارسال: $profileData');

      // پردازش داده‌های پروفایل برای ارسال به وردپرس
      final Map<String, dynamic> wordpressProfileData = {};

      // کپی فیلدهای متنی با بررسی خالی نبودن
      final textFields = [
        'first_name',
        'last_name',
        'bio',
        'experience_level',
        'preferred_training_time',
        'gender',
      ];

      for (var field in textFields) {
        if (profileData.containsKey(field) &&
            profileData[field] != null &&
            profileData[field].toString().isNotEmpty) {
          wordpressProfileData[field] = profileData[field];
        }
      }

      // اطمینان از وجود فیلد profile_picture برای وردپرس
      if (profileData.containsKey('avatar_url') &&
          profileData['avatar_url'] != null &&
          profileData['avatar_url'].toString().isNotEmpty) {
        wordpressProfileData['profile_picture'] = profileData['avatar_url'];
      }

      // تبدیل فیلدهای عددی به صورت صحیح
      final numericFields = [
        'weight',
        'height',
        'arm_circumference',
        'chest_circumference',
        'waist_circumference',
        'hip_circumference',
      ];

      for (var field in numericFields) {
        if (profileData.containsKey(field) &&
            profileData[field] != null &&
            profileData[field].toString().isNotEmpty) {
          try {
            // تبدیل به عدد برای اطمینان از صحت
            var numValue = num.tryParse(profileData[field].toString());
            if (numValue != null) {
              wordpressProfileData[field] = numValue;
            }
          } catch (e) {
            print('خطا در تبدیل فیلد $field به عدد: $e');
          }
        }
      }

      // اضافه کردن سن (اگر تاریخ تولد موجود باشد)
      if (profileData.containsKey('birth_date') &&
          profileData['birth_date'] != null &&
          profileData['birth_date'].toString().isNotEmpty) {
        try {
          // تبدیل birth_date به DateTime اگر به صورت رشته نباشد
          DateTime birthDate;
          if (profileData['birth_date'] is DateTime) {
            birthDate = profileData['birth_date'] as DateTime;
          } else {
            birthDate = DateTime.parse(profileData['birth_date'].toString());
          }

          final now = DateTime.now();
          final age = now.year -
              birthDate.year -
              (now.month < birthDate.month ||
                      (now.month == birthDate.month && now.day < birthDate.day)
                  ? 1
                  : 0);
          wordpressProfileData['age'] = age;

          // تبدیل تاریخ میلادی به شمسی با فرمت سال/ماه/روز
          final persianDate = Jalali.fromDateTime(birthDate);
          String day = persianDate.day.toString().padLeft(2, '0');
          String month = persianDate.month.toString().padLeft(2, '0');
          String year = persianDate.year.toString();
          final persianDateStr = '$year/$month/$day';

          wordpressProfileData['birth_date'] = persianDateStr;
        } catch (e) {
          print('خطا در محاسبه سن: $e');
        }
      }

      // ارسال اطلاعات به وردپرس
      print('ارسال اطلاعات به وردپرس با شماره: $normalizedPhoneWP');
      print('داده‌های آماده شده برای وردپرس: $wordpressProfileData');

      final wpResult = await _wordpressService.updateUserProfile(
          normalizedPhoneWP, wordpressProfileData);

      print('نتیجه به‌روزرسانی پروفایل در وردپرس: $wpResult');

      if (wpResult['success'] != true) {
        print(
            'خطا در به‌روزرسانی پروفایل در وردپرس: ${wpResult['error'] ?? 'خطای نامشخص'}');
        return {
          'success': false,
          'wordpress_sync': false,
          'supabase_sync': false,
          'message':
              'خطا در به‌روزرسانی پروفایل در سایت: ${wpResult['error'] ?? 'خطای نامشخص'}'
        };
      }

      print('پروفایل در وردپرس با موفقیت به‌روز شد');
      print('فیلدهای به‌روز شده: ${wpResult['updated_fields']}');

      // در حالت فعلی نیازی به به‌روزرسانی مجدد سوپابیس نیست
      // چون قبلاً در _saveProfile انجام شده است

      return {
        'success': true,
        'wordpress_sync': true,
        'message': 'پروفایل با موفقیت در سایت به‌روز شد',
        'updated_fields': wpResult['updated_fields']
      };
    } catch (e) {
      print('خطا در همگام‌سازی پروفایل: $e');
      return {
        'success': false,
        'wordpress_sync': false,
        'supabase_sync': false,
        'message': 'خطا در فرآیند همگام‌سازی پروفایل: ${e.toString()}'
      };
    }
  }
}
