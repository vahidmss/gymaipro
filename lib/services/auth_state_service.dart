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

      // پس از ورود موفق، همگام‌سازی توکن FCM با سرور
      try {
        await NotificationService().syncFCMTokenIfAvailable();
        print('Notification token synced after login/signup');
      } catch (e) {
        print('Error syncing FCM token after auth: $e');
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
        '=== AUTH SERVICE: Current session: ${currentSession != null ? "exists" : "null"} ===',
      );

      if (currentSession != null) {
        print(
          '=== AUTH SERVICE: Session access token: ${currentSession.accessToken.isNotEmpty ? "exists" : "empty"} ===',
        );
        print(
          '=== AUTH SERVICE: Session expired: ${currentSession.isExpired} ===',
        );

        if (currentSession.accessToken.isNotEmpty &&
            !currentSession.isExpired) {
          print(
            '=== AUTH SERVICE: Active session found: ${currentSession.accessToken.substring(0, 10)}... ===',
          );
          return true;
        } else {
          print(
            '=== AUTH SERVICE: Session exists but is invalid (empty token or expired) ===',
          );
        }
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
