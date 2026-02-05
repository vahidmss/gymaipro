import 'package:flutter/foundation.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateService {
  factory AuthStateService() {
    return _instance;
  }

  AuthStateService._internal();
  static final AuthStateService _instance = AuthStateService._internal();

  Future<void> saveAuthState(Session session, {String? phoneNumber}) async {
    try {
      if (session.refreshToken == null || session.refreshToken!.isEmpty) {
        print('Warning: Attempting to save session with empty refresh token!');
      }

      // No need to save session manually, Supabase handles this automatically
      print(
        'Session saved via Supabase client: ${session.accessToken.substring(0, 10)}...',
      );
      print(
        'Refresh token available: ${session.refreshToken != null && session.refreshToken!.isNotEmpty}',
      );

      // WordPress sync حذف شد - فقط Supabase استفاده می‌شود

      // پس از ورود موفق، همگام‌سازی توکن FCM با سرور و subscribe به topic 'all'
      try {
        final notificationService = NotificationService();
        await notificationService.syncFCMTokenIfAvailable();
        // Force subscribe to 'all' topic after login to ensure broadcast notifications work
        await notificationService.forceSubscribeToAll();
        print('Notification token synced and subscribed to topic "all" after login/signup');
      } catch (e) {
        print('Error syncing FCM token or subscribing to topic after auth: $e');
      }
    } catch (e) {
      print('Error in saveAuthState: $e');
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
      // Check connectivity before clearing auth state
      final isOnline = await ConnectivityService.instance.checkNow();

      if (isOnline) {
        // Online: normal sign out
        await Supabase.instance.client.auth.signOut();
        print('Auth state cleared successfully (online)');
      } else {
        // Offline: local sign out only
        print('Offline mode: performing local auth state clear');
        await Supabase.instance.client.auth.signOut();
        print('Auth state cleared successfully (offline)');
      }
    } catch (e) {
      print('Error clearing auth state: $e');
      // Don't throw exception in offline mode
      if (kDebugMode) {
        print('Auth state clear error (may be offline): $e');
      }
    }
  }

  /// بازیابی نشست کاربر - با پشتیبانی از رفرش خودکار نشست‌های منقضی شده
  Future<Session?> restoreSession() async {
    try {
      print('=== AUTH SERVICE: Attempting to restore session... ===');

      // بررسی نشست فعلی
      var currentSession = Supabase.instance.client.auth.currentSession;

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
