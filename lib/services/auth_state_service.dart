import 'package:supabase_flutter/supabase_flutter.dart';
import 'wordpress_auth_service.dart';

class AuthStateService {
  static final AuthStateService _instance = AuthStateService._internal();
  final WordPressAuthService _wordpressAuthService = WordPressAuthService();

  factory AuthStateService() {
    return _instance;
  }

  AuthStateService._internal();

  Future<void> saveAuthState(Session session, {String? phoneNumber}) async {
    try {
      if (session.refreshToken == null || session.refreshToken!.isEmpty) {
        print('Warning: Attempting to save session with empty refresh token!');
      }

      // No need to save session manually, Supabase handles this automatically
      print(
          'Session saved via Supabase client: ${session.accessToken.substring(0, 10)}...');
      print(
          'Refresh token available: ${session.refreshToken != null && session.refreshToken!.isNotEmpty}');

      // همگام‌سازی توکن با وردپرس اگر شماره موبایل ارائه شده باشد
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        print('تلاش برای همگام‌سازی توکن با وردپرس برای شماره: $phoneNumber');

        // ارسال توکن به وردپرس
        final syncResult =
            await _wordpressAuthService.syncAuthTokenWithWordPress(phoneNumber);
        print(
            'نتیجه همگام‌سازی توکن با وردپرس: ${syncResult ? "موفق" : "ناموفق"}');

        // تنظیم کوکی در وردپرس
        final cookieResult =
            await _wordpressAuthService.setCookieInWordPress(phoneNumber);
        print(
            'نتیجه تنظیم کوکی در وردپرس: ${cookieResult ? "موفق" : "ناموفق"}');
      } else {
        print('شماره موبایل برای همگام‌سازی با وردپرس ارائه نشده است');
      }
    } catch (e) {
      print('Error in saveAuthState: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      print('=== AUTH SERVICE: Checking if user is logged in... ===');

      // Check if there's an active session in the Supabase client
      final currentSession = Supabase.instance.client.auth.currentSession;
      print(
          '=== AUTH SERVICE: Current session: ${currentSession != null ? "exists" : "null"} ===');

      if (currentSession != null) {
        print(
            '=== AUTH SERVICE: Session access token: ${currentSession.accessToken.isNotEmpty ? "exists" : "empty"} ===');
        print(
            '=== AUTH SERVICE: Session expired: ${currentSession.isExpired} ===');

        if (currentSession.accessToken.isNotEmpty &&
            !currentSession.isExpired) {
          print(
              '=== AUTH SERVICE: Active session found: ${currentSession.accessToken.substring(0, 10)}... ===');
          return true;
        } else {
          print(
              '=== AUTH SERVICE: Session exists but is invalid (empty token or expired) ===');
        }
      }

      // If no active session, user is not logged in
      print(
          '=== AUTH SERVICE: No active session found, user is not logged in ===');
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
