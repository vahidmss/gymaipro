import 'package:flutter/foundation.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/services/logout_cache_clear_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateService {
  factory AuthStateService() => _instance;

  AuthStateService._internal();
  static final AuthStateService _instance = AuthStateService._internal();

  /// Save authentication state after login/signup
  Future<void> saveAuthState(Session session, {String? phoneNumber}) async {
    try {
      await _checkAndClearCacheOnUserChange(session.user.id);

      // Sync FCM token after successful auth
      try {
        final notificationService = NotificationService();
        await notificationService.syncFCMTokenIfAvailable();
        // Ensure broadcast notifications work after login/signup
        await notificationService.forceSubscribeToAll();
      } catch (e) {
        debugPrint('Error syncing FCM token: $e');
      }

      await _saveCurrentUserId(session.user.id);

      // Save phone number for data fallback
      if (phoneNumber?.trim().isNotEmpty ?? false) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'last_logged_in_phone_number',
            phoneNumber!.trim(),
          );
        } catch (e) {
          debugPrint('Error saving phone number: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in saveAuthState: $e');
    }
  }

  /// Check if user changed and clear cache if needed
  Future<void> _checkAndClearCacheOnUserChange(String newUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const lastUserIdKey = 'last_logged_in_user_id';
      final lastUserId = prefs.getString(lastUserIdKey);

      if (lastUserId != null && lastUserId != newUserId) {
        await LogoutCacheClearService.clearAllUserData();
      }
    } catch (e) {
      debugPrint('Error checking user change: $e');
    }
  }

  /// Save current user ID for future checks
  Future<void> _saveCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_logged_in_user_id', userId);
    } catch (e) {
      debugPrint('Error saving user ID: $e');
    }
  }

  /// Check if user is logged in (fast, non-blocking).
  ///
  /// Does NOT call refreshSession() to avoid blocking on slow/offline networks.
  /// Supabase autoRefreshToken handles token refresh in the background.
  Future<bool> isLoggedIn() async {
    try {
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession == null) return false;

      // Valid, non-expired session
      if (currentSession.accessToken.isNotEmpty && !currentSession.isExpired) {
        return true;
      }

      // Expired but has a refresh token → Supabase auto-refresh will handle it.
      // Treat user as "logged in" so routing proceeds immediately.
      if (currentSession.refreshToken?.isNotEmpty ?? false) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error in isLoggedIn: $e');
      return false;
    }
  }

  /// Clear authentication state
  Future<void> clearAuthState() async {
    try {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_logged_in_user_id');
      } catch (e) {
        debugPrint('Error removing user ID: $e');
      }
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Error clearing auth state: $e');
    }
  }

  /// Restore user session with timeout protection.
  ///
  /// If the session is expired, tries to refresh with a 5-second timeout.
  /// On failure, returns the expired session instead of signing out,
  /// so Supabase autoRefreshToken can recover later.
  Future<Session?> restoreSession() async {
    try {
      // Wait a bit for Supabase to restore from storage
      Session? currentSession;
      for (int attempt = 0; attempt < 3; attempt++) {
        currentSession = Supabase.instance.client.auth.currentSession;
        if (currentSession != null) break;
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 100 * (attempt + 1)),
          );
        }
      }

      if (currentSession == null) return null;

      if (kDebugMode) {
        debugPrint(
          'restoreSession: hasSession=true expired=${currentSession.isExpired} hasRefreshToken=${currentSession.refreshToken?.isNotEmpty ?? false}',
        );
      }

      // Valid, non-expired session
      if (currentSession.accessToken.isNotEmpty && !currentSession.isExpired) {
        await _checkAndClearCacheOnUserChange(currentSession.user.id);
        await _saveCurrentUserId(currentSession.user.id);
        return currentSession;
      }

      // Expired but has a refresh token → try refresh with strict timeout
      if (currentSession.isExpired &&
          (currentSession.refreshToken?.isNotEmpty ?? false)) {
        try {
          final response = await Supabase.instance.client.auth
              .refreshSession()
              .timeout(const Duration(seconds: 5));
          if (response.session != null && !response.session!.isExpired) {
            await _checkAndClearCacheOnUserChange(response.session!.user.id);
            await _saveCurrentUserId(response.session!.user.id);
            return response.session;
          }
        } catch (_) {
          // Refresh failed (timeout or network).
          // Return the expired session so the user stays "logged in".
          // Supabase autoRefreshToken will retry in the background.
          if (kDebugMode) {
            debugPrint(
              'Session refresh failed — returning expired session for offline use',
            );
          }
          await _saveCurrentUserId(currentSession.user.id);
          return currentSession;
        }
      }

      // No refresh token → session is not recoverable right now.
      // Do NOT force signOut here; keep startup non-destructive and let
      // user authenticate explicitly if needed.
      return null;
    } catch (e) {
      debugPrint('Error in restoreSession: $e');
      return null;
    }
  }

  static Future<void> ensureFreshSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      if (!session.isExpired) return;
      if (session.refreshToken?.isEmpty ?? true) return;
      await Supabase.instance.client.auth
          .refreshSession()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('ensureFreshSession: $e');
    }
  }
}
