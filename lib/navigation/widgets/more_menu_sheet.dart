import 'package:flutter/material.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';

/// سازگاری عقب‌رو: قبلاً شیت «بیشتر» بود؛ حالا تب بیشتر را باز می‌کند.
Future<void> showMoreMenuSheet(BuildContext context) async {
  if (MainNavigationScreen.isShellActive) {
    MainNavigationScreen.navigateToTab(NavigationConstants.moreIndex);
    return;
  }
  // Fallback when shell isn't mounted — shouldn't normally happen.
  MainNavigationScreen.navigateToTab(NavigationConstants.moreIndex);
}
