import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/services/logout_cache_clear_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateService {
  factory AuthStateService() => _instance;

  AuthStateService._internal();
  static final AuthStateService _instance = AuthStateService._internal();

  static Future<AuthResponse>? _refreshInFlight;
  static DateTime? _lastRefreshFailureAt;
  static const Duration _refreshFailureCooldown = Duration(seconds: 8);

  /// Save authentication state after login/signup.
  Future<void> saveAuthState(Session session, {String? phoneNumber}) async {
    try {
      await _checkAndClearCacheOnUserChange(session.user.id);
      await _saveCurrentUserId(session.user.id);

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

      unawaited(_syncNotificationsInBackground());
    } catch (e) {
      debugPrint('Error in saveAuthState: $e');
    }
  }

  Future<void> _syncNotificationsInBackground() async {
    try {
      final notificationService = NotificationService();
      await notificationService
          .syncFCMTokenIfAvailable()
          .timeout(const Duration(seconds: 5));
      await notificationService
          .forceSubscribeToAll()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

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

  Future<void> _saveCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_logged_in_user_id', userId);
    } catch (e) {
      debugPrint('Error saving user ID: $e');
    }
  }

  /// True only when there is a usable (non-expired) session.
  Future<bool> isLoggedIn() async {
    try {
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession == null) return false;
      return currentSession.accessToken.isNotEmpty && !currentSession.isExpired;
    } catch (e) {
      debugPrint('Error in isLoggedIn: $e');
      return false;
    }
  }

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

  /// Restore a usable session. Returns null when expired and refresh fails
  /// (caller should show offline / login — never enter the app half-loaded).
  Future<Session?> restoreSession() async {
    try {
      Session? currentSession;
      const maxAttempts = kIsWeb ? 12 : 3;
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        currentSession = Supabase.instance.client.auth.currentSession;
        if (currentSession != null) break;
        if (attempt < maxAttempts - 1) {
          await Future<void>.delayed(
            Duration(
              milliseconds: kIsWeb ? 60 * (attempt + 1) : 100 * (attempt + 1),
            ),
          );
        }
      }

      if (currentSession == null) return null;

      if (kDebugMode) {
        debugPrint(
          'restoreSession: hasSession=true expired=${currentSession.isExpired} '
          'hasRefreshToken=${currentSession.refreshToken?.isNotEmpty ?? false}',
        );
      }

      if (currentSession.accessToken.isNotEmpty && !currentSession.isExpired) {
        await _checkAndClearCacheOnUserChange(currentSession.user.id);
        await _saveCurrentUserId(currentSession.user.id);
        return currentSession;
      }

      if (currentSession.isExpired &&
          (currentSession.refreshToken?.isNotEmpty ?? false)) {
        final refreshed = await tryRefreshSession();
        if (refreshed != null && !refreshed.isExpired) {
          await _checkAndClearCacheOnUserChange(refreshed.user.id);
          await _saveCurrentUserId(refreshed.user.id);
          return refreshed;
        }
        // Stop GoTrue from hammering refresh (ANR) while backend/DNS is down.
        _pauseAutoRefresh();
        if (kDebugMode) {
          debugPrint(
            'Session refresh failed — no usable session (show offline/login)',
          );
        }
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('Error in restoreSession: $e');
      return null;
    }
  }

  /// Single-flight refresh with cooldown — prevents ANR refresh storms.
  static Future<Session?> tryRefreshSession({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return null;
      if (!session.isExpired) return session;
      if (session.refreshToken?.isEmpty ?? true) return null;

      final lastFailure = _lastRefreshFailureAt;
      if (lastFailure != null &&
          DateTime.now().difference(lastFailure) < _refreshFailureCooldown) {
        if (kDebugMode) {
          debugPrint('tryRefreshSession: skipped (cooldown)');
        }
        return null;
      }

      final inFlight = _refreshInFlight;
      if (inFlight != null) {
        try {
          final response = await inFlight.timeout(timeout);
          return response.session;
        } catch (_) {
          return null;
        }
      }

      // Ensure GoTrue ticker is allowed to run before we refresh.
      resumeAutoRefresh();

      final future = Supabase.instance.client.auth.refreshSession();
      _refreshInFlight = future;
      try {
        final response = await future.timeout(timeout);
        _lastRefreshFailureAt = null;
        return response.session;
      } catch (e) {
        _lastRefreshFailureAt = DateTime.now();
        _pauseAutoRefresh();
        if (kDebugMode) {
          debugPrint('tryRefreshSession failed: $e');
        }
        return null;
      } finally {
        _refreshInFlight = null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('tryRefreshSession error: $e');
      }
      return null;
    }
  }

  static Future<void> ensureFreshSession() async {
    await tryRefreshSession();
  }

  static void _pauseAutoRefresh() {
    try {
      Supabase.instance.client.auth.stopAutoRefresh();
    } catch (_) {}
  }

  /// Call when backend is reachable again (e.g. offline screen reconnect).
  static void resumeAutoRefresh() {
    try {
      Supabase.instance.client.auth.startAutoRefresh();
      _lastRefreshFailureAt = null;
    } catch (_) {}
  }
}
