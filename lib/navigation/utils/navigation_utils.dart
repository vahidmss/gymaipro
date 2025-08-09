import 'package:flutter/material.dart';
import '../constants/navigation_constants.dart';

/// Utility functions for navigation operations
class NavigationUtils {
  // Private constructor to prevent instantiation
  NavigationUtils._();

  /// Navigates to a route with optional arguments
  static Future<T?> navigateTo<T extends Object?>(
    BuildContext context,
    String route, {
    Object? arguments,
    bool replace = false,
  }) {
    if (replace) {
      return Navigator.pushReplacementNamed(context, route,
          arguments: arguments);
    }
    return Navigator.pushNamed(context, route, arguments: arguments);
  }

  /// Navigates to a route and removes all previous routes
  static Future<T?> navigateToAndClear<T extends Object?>(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Goes back to the previous screen
  static void goBack<T extends Object?>(
    BuildContext context, [
    T? result,
  ]) {
    Navigator.pop(context, result);
  }

  /// Goes back multiple times
  static void goBackMultiple(
    BuildContext context,
    int count,
  ) {
    for (int i = 0; i < count; i++) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        break;
      }
    }
  }

  /// Checks if navigation can go back
  static bool canGoBack(BuildContext context) {
    return Navigator.canPop(context);
  }

  /// Gets the current route name
  static String? getCurrentRoute(BuildContext context) {
    String? currentRoute;
    Navigator.popUntil(context, (route) {
      currentRoute = route.settings.name;
      return true;
    });
    return currentRoute;
  }

  /// Validates if a route exists in the app
  static bool isValidRoute(String route) {
    final validRoutes = [
      NavigationConstants.chatRoute,
      NavigationConstants.workoutProgramBuilderRoute,
      NavigationConstants.workoutLogRoute,
      NavigationConstants.exerciseListRoute,
      NavigationConstants.dashboardRoute,
      NavigationConstants.mealPlanBuilderRoute,
      NavigationConstants.mealLogRoute,
      NavigationConstants.foodListRoute,
      NavigationConstants.profileRoute,
    ];
    return validRoutes.contains(route);
  }

  /// Gets the navigation index for a given route
  static int? getIndexForRoute(String route) {
    switch (route) {
      case NavigationConstants.chatRoute:
        return NavigationConstants.chatIndex;
      case NavigationConstants.dashboardRoute:
        return NavigationConstants.dashboardIndex;
      case NavigationConstants.profileRoute:
        return NavigationConstants.profileIndex;
      default:
        return null;
    }
  }

  /// Gets the route for a given navigation index
  static String? getRouteForIndex(int index) {
    switch (index) {
      case NavigationConstants.chatIndex:
        return NavigationConstants.chatRoute;
      case NavigationConstants.dashboardIndex:
        return NavigationConstants.dashboardRoute;
      case NavigationConstants.profileIndex:
        return NavigationConstants.profileRoute;
      default:
        return null;
    }
  }

  /// Creates a smooth page transition animation
  static PageRouteBuilder<T> createPageRoute<T extends Object?>(
    Widget child, {
    String? routeName,
    Object? arguments,
    bool fullscreenDialog = false,
    bool maintainState = true,
    bool opaque = true,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve transitionCurve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(
        name: routeName,
        arguments: arguments,
      ),
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      opaque: opaque,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Shows a navigation error dialog
  static Future<void> showNavigationError(
    BuildContext context,
    String message, {
    String title = 'خطا در ناوبری',
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }

  /// Shows a navigation confirmation dialog
  static Future<bool> showNavigationConfirmation(
    BuildContext context,
    String message, {
    String title = 'تایید ناوبری',
    String confirmText = 'بله',
    String cancelText = 'خیر',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Handles navigation with error handling
  static Future<T?> safeNavigateTo<T extends Object?>(
    BuildContext context,
    String route, {
    Object? arguments,
    bool replace = false,
    bool showErrorDialog = true,
  }) async {
    try {
      if (!isValidRoute(route)) {
        if (showErrorDialog) {
          await showNavigationError(
            context,
            NavigationConstants.routeNotFoundError,
          );
        }
        return null;
      }

      return await navigateTo<T>(
        context,
        route,
        arguments: arguments,
        replace: replace,
      );
    } catch (e) {
      if (showErrorDialog) {
        await showNavigationError(
          context,
          'خطا در ناوبری: $e',
        );
      }
      return null;
    }
  }

  /// Creates a navigation action card widget
  static Widget createActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double padding = 20.0,
    double borderRadius = 16.0,
    double iconSize = 24.0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: iconSize,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a section header widget
  static Widget createSectionHeader({
    required String title,
    Color? backgroundColor,
    Color? textColor,
    double fontSize = 18.0,
    FontWeight fontWeight = FontWeight.bold,
    EdgeInsets padding = const EdgeInsets.all(16.0),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[900],
      ),
      child: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Debounces navigation calls to prevent rapid navigation
  static DateTime? _lastNavigationTime;

  /// Checks if enough time has passed since the last navigation
  static bool canNavigate(
      {Duration debounceTime = const Duration(milliseconds: 500)}) {
    final now = DateTime.now();
    if (_lastNavigationTime == null) {
      _lastNavigationTime = now;
      return true;
    }

    final timeSinceLastNavigation = now.difference(_lastNavigationTime!);
    if (timeSinceLastNavigation >= debounceTime) {
      _lastNavigationTime = now;
      return true;
    }

    return false;
  }

  /// Resets the navigation debounce timer
  static void resetNavigationDebounce() {
    _lastNavigationTime = null;
  }
}
