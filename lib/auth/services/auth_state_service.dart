import 'package:gymaipro/notification/notification_service.dart';
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

      print('=== AUTH STATE SERVICE: saveAuthState completed successfully ===');
    } catch (e) {
      print('=== AUTH STATE SERVICE: Error in saveAuthState: $e ===');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      print('=== AUTH SERVICE: Checking if user is logged in... ===');

      // Check if there's an active session in the Supabase client
      final currentSession = Supabase.instance.client.auth.currentSession;
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

        if (currentSession.accessToken.isNotEmpty &&
            !currentSession.isExpired) {
          print(
            '=== AUTH SERVICE: Active session found: ${currentSession.accessToken.substring(0, 10)}... ===',
          );
          print(
            '=== AUTH SERVICE: User is logged in with Supabase session ===',
          );
          return true;
        } else {
          print(
            '=== AUTH SERVICE: Session exists but is invalid (empty token or expired) ===',
          );
        }
      } else {
        print('=== AUTH SERVICE: No Supabase session found ===');
      }

      // If no active session, user is not logged in
      print(
        '=== AUTH SERVICE: No active session found, user is not logged in ===',
      );
      return false;
    } catch (e) {
      print('=== AUTH SERVICE: Error in isLoggedIn: $e ===');
      return false;
    }
  }

  Future<void> clearAuthState() async {
    try {
      // Sign out from Supabase client
      await Supabase.instance.client.auth.signOut();
      print('Auth state cleared successfully');
    } catch (e) {
      print('Error clearing auth state: $e');
    }
  }

  Future<Session?> restoreSession() async {
    try {
      print('Attempting to restore session...');
      // Check if there's an active session in the Supabase client
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession != null &&
          currentSession.accessToken.isNotEmpty &&
          !currentSession.isExpired) {
        print('Active session already exists');
        return currentSession;
      }

      // If no active session exists, return null
      print('No session found');
      return null;
    } catch (e) {
      print('Error in restoreSession: $e');
      return null;
    }
  }
}
