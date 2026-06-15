import 'package:flutter/material.dart';
import 'package:gymaipro/my_club/index.dart' show MyClubMainScreen;
import 'package:gymaipro/my_club/my_club_main_screen.dart' show MyClubMainScreen;
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';

/// Shared navigator key for cross-feature navigation (MaterialApp root).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

NavigatorState? get rootNavigator => appNavigatorKey.currentState;

/// Sub-tab indices inside [MyClubMainScreen] (باشگاه من).
abstract final class MyClubTabs {
  static const int programs = 0;
  static const int trainers = 1;
  static const int friends = 2;
  static const int points = 3;
  static const int wallet = 4;
  static const int confidential = 5;
}

/// Closes routes pushed above the root [MainNavigationScreen] (e.g. chat screens).
void popRootNavigatorOverlays() {
  final navigator = rootNavigator;
  if (navigator == null || !navigator.canPop()) return;
  navigator.popUntil((route) => route.isFirst);
}

/// When `/` or `/main` is pushed while [MainNavigationScreen] is already the
/// first route, pop the duplicate overlay instead of showing a blank page.
void resolveDuplicateShellRoute(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final navigator = rootNavigator ?? Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    if (MainNavigationScreen.isShellActive) {
      MainNavigationScreen.navigateToTab(NavigationConstants.dashboardIndex);
    }
  });
}

/// Returns to the main shell and selects the dashboard tab without rebuilding `/main`.
void openMainDashboard() {
  popRootNavigatorOverlays();
  MainNavigationScreen.navigateToTab(NavigationConstants.dashboardIndex);
}

/// After login/registration: show main shell on dashboard without a blank overlay.
void goToMainApp([BuildContext? context]) {
  if (MainNavigationScreen.isShellActive) {
    openMainDashboard();
    return;
  }
  final rootNav = rootNavigator;
  if (rootNav != null) {
    rootNav.pushNamedAndRemoveUntil('/main', (route) => false);
    return;
  }
  if (context != null && context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }
}

/// باشگاه من (تب برنامه‌ها به‌صورت پیش‌فرض) — داخل shell، نه صفحه جدا.
void openMainMyClub({int initialTab = MyClubTabs.programs}) {
  popRootNavigatorOverlays();
  MainNavigationScreen.navigateToMyClub(initialTab: initialTab);
}

/// تب اجتماعی (پیام‌ها / چت‌روم) داخل shell.
void openMainSocial({int initialTab = 0}) {
  popRootNavigatorOverlays();
  MainNavigationScreen.navigateToSocial(initialTab: initialTab);
}

/// میز کار مربی (تب پایین / منوی همبرگری).
void openMainTrainerDashboard({int initialTab = 0}) {
  popRootNavigatorOverlays();
  MainNavigationScreen.navigateToTrainerDashboard(initialTab: initialTab);
}

String _normalizeRoutePath(String route) {
  final path = route.split('?').first.trim();
  if (path == '/my_programs') return '/my-club';
  if (path == '/my-programs') return '/my-club';
  return path;
}

/// Routes handled inside [MainNavigationScreen] (no standalone duplicate screens).
bool tryNavigateIntegratedRoute(
  String route, {
  Map<String, dynamic>? arguments,
}) {
  final path = _normalizeRoutePath(route);
  final subTab = arguments?['initialTab'] as int? ??
      arguments?['initialTabIndex'] as int? ??
      arguments?['subTab'] as int?;

  switch (path) {
    case '/main':
    case '/dashboard':
      openMainDashboard();
      return true;
    case '/my-club':
      openMainMyClub(initialTab: subTab ?? MyClubTabs.programs);
      return true;
    case '/achievements':
      openMainMyClub(initialTab: MyClubTabs.points);
      return true;
    case '/wallet':
    case '/wallet-charge':
      openMainMyClub(initialTab: MyClubTabs.wallet);
      return true;
    case '/chat-main':
      openMainSocial(initialTab: subTab ?? 0);
      return true;
    case '/trainer-dashboard':
      openMainTrainerDashboard(initialTab: subTab ?? 0);
      return true;
    default:
      return false;
  }
}

/// Routes that must not push a second shell screen (legacy alias).
bool isMainShellRoute(String route) {
  return tryNavigateIntegratedRoute(route);
}

/// Prefer this over [Navigator.pushNamed] for shell-integrated destinations.
Future<T?>? navigateAppRoute<T extends Object?>(
  String route, {
  Object? arguments,
}) {
  final args = arguments is Map<String, dynamic>?
      ? arguments
      : arguments is Map
          ? Map<String, dynamic>.from(arguments)
          : null;
  if (tryNavigateIntegratedRoute(route, arguments: args)) {
    return null;
  }
  final navigator = rootNavigator;
  if (navigator == null) return null;
  return navigator.pushNamed<T>(route, arguments: arguments);
}

/// Context-based variant (e.g. from a pushed screen like notifications).
Future<T?>? navigateAppRouteFrom<T extends Object?>(
  BuildContext context,
  String route, {
  Object? arguments,
}) {
  final args = arguments is Map<String, dynamic>?
      ? arguments
      : arguments is Map
          ? Map<String, dynamic>.from(arguments)
          : null;
  if (tryNavigateIntegratedRoute(route, arguments: args)) {
    return null;
  }
  return Navigator.pushNamed<T>(context, route, arguments: arguments);
}
