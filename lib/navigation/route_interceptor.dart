import 'package:flutter/material.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/navigation/navigation_guard.dart';

class RouteInterceptor {
  /// Intercept route generation and redirect if necessary
  static Future<Route<dynamic>?> interceptRoute(
    RouteSettings settings,
    Route<dynamic> Function(RouteSettings) routeBuilder,
  ) async {
    try {
      // Check if user is logged in
      final authService = AuthStateService();
      final isLoggedIn = await authService.isLoggedIn();

      if (isLoggedIn &&
          !NavigationGuard.isRouteAllowedForLoggedInUser(settings.name ?? '')) {
        print(
          '=== ROUTE INTERCEPTOR: Redirecting logged in user from ${settings.name} to ${NavigationGuard.getRedirectRouteForLoggedInUser()} ===',
        );

        // Return redirect route instead of the requested route
        return routeBuilder(
          RouteSettings(
            name: NavigationGuard.getRedirectRouteForLoggedInUser(),
            arguments: settings.arguments,
          ),
        );
      }

      // Allow normal route generation
      return routeBuilder(settings);
    } catch (e) {
      print('=== ROUTE INTERCEPTOR: Error in interceptRoute: $e ===');
      return routeBuilder(settings);
    }
  }
}
