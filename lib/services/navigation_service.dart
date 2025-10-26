import 'package:flutter/material.dart';
import 'package:gymaipro/services/auth_state_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NavigationService {
  factory NavigationService() => _instance;
  NavigationService._internal();
  static final NavigationService _instance = NavigationService._internal();

  /// Safe navigation back with auth check
  static Future<void> safePop(BuildContext context) async {
    try {
      // Check if user is still authenticated
      final authService = AuthStateService();
      final isLoggedIn = await authService.isLoggedIn();

      if (!isLoggedIn) {
        // User is not logged in, navigate to login
        if (context.mounted) {
          try {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          } catch (e) {
            debugPrint('Error in safePop login navigation: $e');
          }
        }
        return;
      }

      // Check if we can pop
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // If we can't pop, go to main screen
        if (context.mounted) {
          try {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/main',
              (route) => false,
            );
          } catch (e) {
            debugPrint('Error in safePop main navigation: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in safePop: $e');
      // Fallback to main screen instead of login
      if (context.mounted) {
        try {
          Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        } catch (e) {
          debugPrint('Error in safePop fallback navigation: $e');
        }
      }
    }
  }

  /// Navigate to a route with auth check
  static Future<void> safeNavigateTo(
    BuildContext context,
    String route, {
    Object? arguments,
    bool replace = false,
  }) async {
    try {
      // Check if user is still authenticated
      final authService = AuthStateService();
      final isLoggedIn = await authService.isLoggedIn();

      if (!isLoggedIn) {
        // User is not logged in, navigate to login
        if (context.mounted) {
          try {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          } catch (e) {
            debugPrint('Error in safeNavigateTo login navigation: $e');
          }
        }
        return;
      }

      // Proceed with navigation
      if (replace) {
        Navigator.pushReplacementNamed(context, route, arguments: arguments);
      } else {
        Navigator.pushNamed(context, route, arguments: arguments);
      }
    } catch (e) {
      debugPrint('Error in safeNavigateTo: $e');
      // Fallback to main screen instead of login
      if (context.mounted) {
        try {
          Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        } catch (e) {
          debugPrint('Error in safeNavigateTo fallback navigation: $e');
        }
      }
    }
  }

  /// Check if user is authenticated
  static Future<bool> isUserAuthenticated() async {
    try {
      final authService = AuthStateService();
      return await authService.isLoggedIn();
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }
}
