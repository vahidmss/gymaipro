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
        await NotificationService().syncFCMTokenIfAvailable();
      } catch (e) {
        debugPrint('Error syncing FCM token: $e');
      }

      await _saveCurrentUserId(session.user.id);

      // Save phone number for data fallback
      if (phoneNumber?.trim().isNotEmpty == true) {
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

  /// Check if user is logged in with automatic session refresh
  Future<bool> isLoggedIn() async {
    try {
      final currentSession = Supabase.instance.client.auth.currentSession;

      if (currentSession != null) {
        if (currentSession.accessToken.isNotEmpty && !currentSession.isExpired) {
          return true;
        }

        // Try to refresh expired session
        if (currentSession.isExpired &&
            currentSession.refreshToken?.isNotEmpty == true) {
          try {
            final response = await Supabase.instance.client.auth.refreshSession();
            return response.session != null &&
                response.session!.accessToken.isNotEmpty &&
                !response.session!.isExpired;
          } catch (_) {
            return false;
          }
        }
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

  /// Restore user session with automatic refresh support
  Future<Session?> restoreSession() async {
    try {
      // Retry session restoration with delays
      Session? currentSession;
      for (int attempt = 0; attempt < 3; attempt++) {
        currentSession = Supabase.instance.client.auth.currentSession;
        if (currentSession != null) break;
        if (attempt < 2) {
          await Future<void>.delayed(Duration(milliseconds: 100 * (attempt + 1)));
        }
      }

      if (currentSession != null) {
        if (currentSession.accessToken.isNotEmpty && !currentSession.isExpired) {
          await _checkAndClearCacheOnUserChange(currentSession.user.id);
          await _saveCurrentUserId(currentSession.user.id);
          return currentSession;
        }

        // Try to refresh expired session
        if (currentSession.isExpired &&
            currentSession.refreshToken?.isNotEmpty == true) {
          try {
            final response = await Supabase.instance.client.auth.refreshSession();
            if (response.session != null && !response.session!.isExpired) {
              await _checkAndClearCacheOnUserChange(response.session!.user.id);
              await _saveCurrentUserId(response.session!.user.id);
              return response.session;
            }
          } catch (_) {
            // Clear invalid session on refresh failure
            try {
              await Supabase.instance.client.auth.signOut();
            } catch (_) {
              // Ignore signOut errors
            }
          }
        } else {
          // Clear session without refresh token
          try {
            await Supabase.instance.client.auth.signOut();
          } catch (_) {
            // Ignore signOut errors
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error in restoreSession: $e');
      return null;
    }
  }
}
