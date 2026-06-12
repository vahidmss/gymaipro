import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';

class NavigationGuard {
  static DateTime? _lastBackPressed;

  /// Handle back button press with navigation guard
  static Future<bool> handleBackPress(BuildContext context) async {
    try {
      // Check if user is logged in
      final authService = AuthStateService();
      final isLoggedIn = await authService.isLoggedIn();

      if (!isLoggedIn) {
        // User is not logged in, allow normal navigation
        return true;
      }

      // User is logged in, implement double back to show exit dialog
      final now = DateTime.now();
      const maxDuration = Duration(seconds: 2);
      final isFirstPress =
          _lastBackPressed == null ||
          now.difference(_lastBackPressed!) > maxDuration;

      if (isFirstPress) {
        // First back press - record the time
        _lastBackPressed = now;
        return false; // Don't exit yet
      } else {
        // Double back pressed within 2 seconds - show exit dialog
        _lastBackPressed = null; // Reset for next time
        
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('خروج از برنامه'),
              content: const Text('آیا می‌خواهید از برنامه خارج شوید؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('خیر'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('بله'),
                ),
              ],
            );
          },
        );

        if (shouldExit ?? false) {
          SystemNavigator.pop();
        }
        
        return false;
      }
    } catch (e) {
      debugPrint('Error in handleBackPress: $e');
      return true;
    }
  }

  /// Check if route is allowed for logged in user
  static bool isRouteAllowedForLoggedInUser(String route) {
    const restrictedRoutes = ['/login', '/register', '/welcome'];

    return !restrictedRoutes.contains(route);
  }

  /// Get redirect route for logged in user
  static String getRedirectRouteForLoggedInUser() {
    return '/main';
  }
}
