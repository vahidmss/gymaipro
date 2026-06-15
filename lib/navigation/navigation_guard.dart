import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/theme/app_theme.dart';

class NavigationGuard {
  static DateTime? _lastBackPressed;

  static void resetBackPress() {
    _lastBackPressed = null;
  }

  /// Handle back button press with navigation guard.
  /// Uses PopScope at the shell level — does not return a pop decision.
  static Future<void> handleBackPress(BuildContext context) async {
    try {
      final authService = AuthStateService();
      final isLoggedIn = await authService.isLoggedIn();

      if (!isLoggedIn) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }

      final now = DateTime.now();
      const maxDuration = Duration(seconds: 2);
      final isFirstPress =
          _lastBackPressed == null ||
          now.difference(_lastBackPressed!) > maxDuration;

      if (isFirstPress) {
        _lastBackPressed = now;
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'برای خروج دوباره دکمه بازگشت را بزنید',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      _lastBackPressed = null;

      if (!context.mounted) return;
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text(
              'خروج از برنامه',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            content: const Text(
              'آیا می‌خواهید از برنامه خارج شوید؟',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(
                  'خیر',
                  style: TextStyle(fontFamily: AppTheme.fontFamily),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(
                  'بله',
                  style: TextStyle(fontFamily: AppTheme.fontFamily),
                ),
              ),
            ],
          );
        },
      );

      if (shouldExit ?? false) {
        await SystemNavigator.pop();
      }
    } catch (e) {
      debugPrint('Error in handleBackPress: $e');
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
