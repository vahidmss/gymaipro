import 'dart:convert'; // For jsonEncode/Decode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateService {
  static const String _sessionKey = 'supabase_session'; // Changed key name
  static final AuthStateService _instance = AuthStateService._internal();

  factory AuthStateService() {
    return _instance;
  }

  AuthStateService._internal();

  Future<void> saveAuthState(Session session) async {
    try {
      if (session.refreshToken == null || session.refreshToken!.isEmpty) {
        print('Warning: Attempting to save session with empty refresh token!');
      }

      final prefs = await SharedPreferences.getInstance();
      // Store the entire session object as a JSON string
      final sessionJson = session.toJson();

      // اطمینان از وجود فیلدهای ضروری در JSON
      if (!sessionJson.containsKey('access_token') ||
          sessionJson['access_token'] == null) {
        print('Error: Session JSON does not contain valid access_token');
        return;
      }

      if (!sessionJson.containsKey('refresh_token') ||
          sessionJson['refresh_token'] == null) {
        print('Error: Session JSON does not contain valid refresh_token');
        return;
      }

      final jsonString = jsonEncode(sessionJson);
      await prefs.setString(_sessionKey, jsonString);

      // بررسی اینکه آیا ذخیره‌سازی موفق بوده است
      final savedString = prefs.getString(_sessionKey);
      if (savedString != jsonString) {
        print('Warning: Saved session string does not match original!');
      } else {
        print('Session saved successfully');
      }

      print('Access token: ${session.accessToken.substring(0, 10)}...');
      print(
          'Refresh token available: ${session.refreshToken != null && session.refreshToken!.isNotEmpty}');
    } catch (e) {
      print('Error saving auth state: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      // First, check if there's an active session in the Supabase client
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession != null &&
          currentSession.accessToken.isNotEmpty &&
          !currentSession.isExpired) {
        print(
            'Active session found: ${currentSession.accessToken.substring(0, 10)}...');
        return true;
      }

      // If no active session, try to recover from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final sessionString = prefs.getString(_sessionKey);

      print('Session stored in preferences: ${sessionString != null}');

      if (sessionString == null) {
        print('No session found in preferences.');
        return false;
      }

      try {
        final sessionJson = jsonDecode(sessionString) as Map<String, dynamic>;
        print('Session JSON parsed successfully');

        // بررسی وجود refresh token
        if (!sessionJson.containsKey('refresh_token') ||
            sessionJson['refresh_token'] == null ||
            sessionJson['refresh_token'].toString().isEmpty) {
          print('No valid refresh token found in stored session data.');
          await clearAuthState();
          return false;
        }

        final refreshToken = sessionJson['refresh_token'] as String;
        print('Attempting to recover session with refresh token');

        try {
          final response =
              await Supabase.instance.client.auth.recoverSession(refreshToken);
          print('Session recovery attempt completed');

          if (response.session != null && !response.session!.isExpired) {
            print('Session recovered successfully');
            // وقتی نشست با موفقیت بازیابی شد، آن را مجدد ذخیره می‌کنیم
            await saveAuthState(response.session!);
            return true;
          } else {
            print('Session recovery failed or returned expired session');
            await clearAuthState();
            return false;
          }
        } catch (e) {
          print('Error during session recovery: $e');
          await clearAuthState();
          return false;
        }
      } catch (e) {
        print('Error parsing session JSON: $e');
        await clearAuthState(); // Clear invalid session data
        return false;
      }
    } catch (e) {
      print('Fatal error in isLoggedIn: $e');
      return false;
    }
  }

  Future<void> clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      // Also sign out from Supabase client
      await Supabase.instance.client.auth.signOut();
      print('Auth state cleared successfully');
    } catch (e) {
      print('Error clearing auth state: $e');
    }
  }

  Future<Session?> restoreSession() async {
    try {
      print('Attempting to restore session...');
      // First, check if there's an active session in the Supabase client
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession != null &&
          currentSession.accessToken.isNotEmpty &&
          !currentSession.isExpired) {
        print('Active session already exists');
        return currentSession;
      }

      // Try to restore from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final sessionString = prefs.getString(_sessionKey);

      if (sessionString == null) {
        print('No session string found in preferences');
        return null;
      }

      try {
        final sessionJson = jsonDecode(sessionString) as Map<String, dynamic>;

        // Ensure refresh_token exists and is not null before using it
        if (!sessionJson.containsKey('refresh_token') ||
            sessionJson['refresh_token'] == null ||
            sessionJson['refresh_token'].toString().isEmpty) {
          print('No valid refresh token in stored session');
          await clearAuthState();
          return null;
        }

        final refreshToken = sessionJson['refresh_token'] as String;

        try {
          final response =
              await Supabase.instance.client.auth.recoverSession(refreshToken);

          if (response.session != null && !response.session!.isExpired) {
            print('Session restored successfully');
            // حفظ نشست بازیابی شده
            await saveAuthState(response.session!);
            return response.session;
          } else {
            print('Session restoration failed or returned expired session');
            await clearAuthState();
            return null;
          }
        } catch (e) {
          print('Error recovering session during restore: $e');
          await clearAuthState();
          return null;
        }
      } catch (e) {
        print('Error parsing JSON during restore: $e');
        await clearAuthState();
        return null;
      }
    } catch (e) {
      print('Fatal error in restoreSession: $e');
      return null;
    }
  }
}
