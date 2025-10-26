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

      // User is logged in, implement double back to exit
      final now = DateTime.now();
      const maxDuration = Duration(seconds: 2);
      final isWarning =
          _lastBackPressed == null ||
          now.difference(_lastBackPressed!) > maxDuration;

      if (isWarning) {
        _lastBackPressed = now;

        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('برای خروج دوباره back بزنید'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );

        return false; // Don't exit
      } else {
        // Double back pressed, exit app
        SystemNavigator.pop();
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
