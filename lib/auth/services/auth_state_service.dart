import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/services/logout_cache_clear_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateService {
  factory AuthStateService() {
    return _instance;
  }

  AuthStateService._internal();
  static final AuthStateService _instance = AuthStateService._internal();

  Future<void> saveAuthState(Session session, {String? phoneNumber}) async {
    try {
      print('=== AUTH STATE SERVICE: Starting saveAuthState ===');
      print('=== AUTH STATE SERVICE: Session user ID: ${session.user.id} ===');
      print(
        '=== AUTH STATE SERVICE: Access token: ${session.accessToken.substring(0, 10)}... ===',
      );

      // بررسی تغییر کاربر و پاک کردن کش در صورت نیاز
      await _checkAndClearCacheOnUserChange(session.user.id);

      if (session.refreshToken == null || session.refreshToken!.isEmpty) {
        print(
          '=== AUTH STATE SERVICE: Warning: Attempting to save session with empty refresh token! ===',
        );
      }

      // NOTE: SDK به‌صورت خودکار سشن را پایدار می‌کند؛ setSession اشتباه با access token می‌تواند مشکل‌ساز شود
      // بنابراین از setSession استفاده نمی‌کنیم و فقط لاگ می‌زنیم
      try {
        final currentSession = Supabase.instance.client.auth.currentSession;
        print(
          '=== AUTH STATE SERVICE: Current session after sign in: ${currentSession != null ? "exists" : "null"} ===',
        );
        if (currentSession != null) {
          print(
            '=== AUTH STATE SERVICE: Current session user ID: ${currentSession.user.id} ===',
          );
        }
      } catch (e) {
        print(
          '=== AUTH STATE SERVICE: Error reading current session after auth: $e ===',
        );
      }

      // WordPress sync حذف شد - فقط Supabase استفاده می‌شود

      // پس از ورود موفق، همگام‌سازی توکن FCM با سرور
      try {
        await NotificationService().syncFCMTokenIfAvailable();
        print(
          '=== AUTH STATE SERVICE: Notification token synced after login/signup ===',
        );
      } catch (e) {
        print(
          '=== AUTH STATE SERVICE: Error syncing FCM token after auth: $e ===',
        );
      }

      // ذخیره userId فعلی برای بررسی تغییر کاربر در آینده
      await _saveCurrentUserId(session.user.id);

      // ذخیره شماره موبایل آخرین لاگین (برای fallback های دیتایی)
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'last_logged_in_phone_number',
            phoneNumber.trim(),
          );
        } catch (e) {
          print('=== AUTH STATE SERVICE: خطا در ذخیره phoneNumber: $e ===');
        }
      }

      print('=== AUTH STATE SERVICE: saveAuthState completed successfully ===');
    } catch (e) {
      print('=== AUTH STATE SERVICE: Error in saveAuthState: $e ===');
    }
  }

  /// بررسی تغییر کاربر و پاک کردن کش در صورت نیاز
  /// این متد بررسی می‌کند که آیا کاربر جدیدی login کرده یا نه
  /// و در صورت تغییر کاربر، تمام کش‌های مربوط به کاربر قبلی را پاک می‌کند
  Future<void> _checkAndClearCacheOnUserChange(String newUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const lastUserIdKey = 'last_logged_in_user_id';
      final lastUserId = prefs.getString(lastUserIdKey);

      // اگر userId قبلی وجود دارد و با userId جدید متفاوت است
      if (lastUserId != null && lastUserId != newUserId) {
        print(
          '=== AUTH STATE SERVICE: کاربر تغییر کرده است! (قبلی: $lastUserId, جدید: $newUserId) ===',
        );
        print(
          '=== AUTH STATE SERVICE: شروع پاک کردن کش‌های کاربر قبلی... ===',
        );

        // پاک کردن تمام کش‌های کاربر قبلی
        // توجه: موزیک و ویدیو پاک نمی‌شوند چون فایل‌های دانلود شده هستند
        await LogoutCacheClearService.clearAllUserData();

        print(
          '=== AUTH STATE SERVICE: کش‌های کاربر قبلی با موفقیت پاک شدند ===',
        );
      } else if (lastUserId == null) {
        print(
          '=== AUTH STATE SERVICE: اولین login کاربر (کش قبلی وجود ندارد) ===',
        );
      } else {
        print(
          '=== AUTH STATE SERVICE: همان کاربر (کش پاک نمی‌شود) ===',
        );
      }
    } catch (e) {
      print(
        '=== AUTH STATE SERVICE: خطا در بررسی تغییر کاربر: $e ===',
      );
      // حتی اگر خطایی رخ داد، ادامه می‌دهیم
    }
  }

  /// ذخیره userId فعلی برای بررسی تغییر کاربر در آینده
  Future<void> _saveCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_logged_in_user_id', userId);
    } catch (e) {
      print('=== AUTH STATE SERVICE: خطا در ذخیره userId: $e ===');
    }
  }

  /// بررسی وضعیت لاگین کاربر - با پشتیبانی از رفرش خودکار نشست‌های منقضی شده
  Future<bool> isLoggedIn() async {
    try {
      print('=== AUTH SERVICE: Checking if user is logged in... ===');

      // بررسی نشست فعلی
      var currentSession = Supabase.instance.client.auth.currentSession;
      print(
        '=== AUTH SERVICE: Current session: ${currentSession != null ? "exists" : "null"} ===',
      );

      if (currentSession != null) {
        print(
          '=== AUTH SERVICE: Session access token: ${currentSession.accessToken.isNotEmpty ? "exists" : "empty"} ===',
        );
        print(
          '=== AUTH SERVICE: Session expired: ${currentSession.isExpired} ===',
        );
        print(
          '=== AUTH SERVICE: Session user ID: ${currentSession.user.id} ===',
        );

        // اگر نشست معتبر است
        if (currentSession.accessToken.isNotEmpty &&
            !currentSession.isExpired) {
          print(
            '=== AUTH SERVICE: Active session found: ${currentSession.accessToken.substring(0, 10)}... ===',
          );
          print(
            '=== AUTH SERVICE: User is logged in with valid Supabase session ===',
          );
          return true;
        }

        // اگر نشست منقضی شده اما refresh token موجود است، تلاش برای رفرش
        if (currentSession.isExpired &&
            currentSession.refreshToken != null &&
            currentSession.refreshToken!.isNotEmpty) {
          print(
            '=== AUTH SERVICE: Session expired, attempting automatic refresh... ===',
          );
          try {
            // تلاش برای رفرش نشست
            final response = await Supabase.instance.client.auth
                .refreshSession();
            if (response.session != null &&
                response.session!.accessToken.isNotEmpty &&
                !response.session!.isExpired) {
              print(
                '=== AUTH SERVICE: Session refreshed successfully, user is logged in ===',
              );
              return true;
            } else {
              print(
                '=== AUTH SERVICE: Session refresh failed - user is not logged in ===',
              );
            }
          } catch (refreshError) {
            print(
              '=== AUTH SERVICE: Error refreshing expired session: $refreshError ===',
            );
            // در صورت خطا در رفرش، کاربر لاگین نیست
            return false;
          }
        } else {
          print(
            '=== AUTH SERVICE: Session exists but is invalid (empty token or expired without refresh token) ===',
          );
        }
      } else {
        print('=== AUTH SERVICE: No Supabase session found ===');
      }

      // اگر نشست معتبری پیدا نشد، کاربر لاگین نیست
      print(
        '=== AUTH SERVICE: No active session found, user is not logged in ===',
      );
      return false;
    } catch (e, stackTrace) {
      print('=== AUTH SERVICE: Error in isLoggedIn: $e ===');
      print('=== AUTH SERVICE: Stack trace: $stackTrace ===');
      return false;
    }
  }

  Future<void> clearAuthState() async {
    try {
      // پاک کردن userId ذخیره شده
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_logged_in_user_id');
      } catch (e) {
        print('Error removing last user ID: $e');
      }

      // Sign out from Supabase client
      await Supabase.instance.client.auth.signOut();
      print('Auth state cleared successfully');
    } catch (e) {
      print('Error clearing auth state: $e');
    }
  }

  /// بازیابی نشست کاربر - با پشتیبانی از رفرش خودکار نشست‌های منقضی شده
  Future<Session?> restoreSession() async {
    try {
      print('=== AUTH SERVICE: Attempting to restore session... ===');

      // تلاش چندباره برای بازیابی session (در صورت تاخیر در restoration)
      Session? currentSession;
      for (int attempt = 0; attempt < 3; attempt++) {
        currentSession = Supabase.instance.client.auth.currentSession;
        if (currentSession != null) {
          break;
        }
        if (attempt < 2) {
          // منتظر بمان و دوباره تلاش کن
          await Future<void>.delayed(Duration(milliseconds: 100 * (attempt + 1)));
          print('=== AUTH SERVICE: Retrying session restoration (attempt ${attempt + 2})... ===');
        }
      }

      if (currentSession != null) {
        print('=== AUTH SERVICE: Session found ===');
        print(
          '=== AUTH SERVICE: Session expired: ${currentSession.isExpired} ===',
        );
        print('=== AUTH SERVICE: User ID: ${currentSession.user.id} ===');

        // اگر نشست معتبر است، آن را برگردان
        if (currentSession.accessToken.isNotEmpty &&
            !currentSession.isExpired) {
          print('=== AUTH SERVICE: Active session restored successfully ===');
          // بررسی تغییر کاربر و ذخیره userId
          await _checkAndClearCacheOnUserChange(currentSession.user.id);
          await _saveCurrentUserId(currentSession.user.id);
          return currentSession;
        }

        // اگر نشست منقضی شده اما refresh token موجود است، تلاش برای رفرش
        if (currentSession.isExpired &&
            currentSession.refreshToken != null &&
            currentSession.refreshToken!.isNotEmpty) {
          print('=== AUTH SERVICE: Session expired, attempting refresh... ===');
          try {
            // تلاش برای رفرش نشست با استفاده از refresh token
            final response = await Supabase.instance.client.auth
                .refreshSession();
            if (response.session != null && !response.session!.isExpired) {
              print('=== AUTH SERVICE: Session refreshed successfully ===');
              print(
                '=== AUTH SERVICE: New session user ID: ${response.session!.user.id} ===',
              );
              // بررسی تغییر کاربر و ذخیره userId
              await _checkAndClearCacheOnUserChange(response.session!.user.id);
              await _saveCurrentUserId(response.session!.user.id);
              return response.session;
            } else {
              print(
                '=== AUTH SERVICE: Session refresh failed - session still invalid ===',
              );
            }
          } catch (refreshError) {
            print(
              '=== AUTH SERVICE: Error refreshing session: $refreshError ===',
            );
            // اگر رفرش با خطا مواجه شد، نشست را پاک کن
            try {
              await Supabase.instance.client.auth.signOut();
              print(
                '=== AUTH SERVICE: Cleared invalid session after refresh failure ===',
              );
            } catch (signOutError) {
              print(
                '=== AUTH SERVICE: Error clearing session: $signOutError ===',
              );
            }
          }
        } else {
          print(
            '=== AUTH SERVICE: Session expired but no refresh token available ===',
          );
          // اگر refresh token موجود نیست، نشست را پاک کن
          try {
            await Supabase.instance.client.auth.signOut();
            print('=== AUTH SERVICE: Cleared invalid session ===');
          } catch (signOutError) {
            print(
              '=== AUTH SERVICE: Error clearing invalid session: $signOutError ===',
            );
          }
        }
      } else {
        print('=== AUTH SERVICE: No session found in storage ===');
      }

      // اگر نشست معتبری پیدا نشد، null برگردان
      print('=== AUTH SERVICE: No valid session to restore ===');
      return null;
    } catch (e, stackTrace) {
      print('=== AUTH SERVICE: Error in restoreSession: $e ===');
      print('=== AUTH SERVICE: Stack trace: $stackTrace ===');
      return null;
    }
  }
}
