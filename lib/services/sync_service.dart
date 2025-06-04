import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'wordpress_service.dart';

class SyncService {
  final SupabaseService _supabaseService = SupabaseService();
  final WordPressService _wordpressService = WordPressService();

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
}
