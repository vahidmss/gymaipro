import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/dashboard/screens/dashboard_screen.dart' show DashboardScreen;
import 'package:gymaipro/services/simple_profile_service.dart';

/// Coordinates one-time, staggered post-login loads so startup work does not
/// pile onto the first frame. Safe to call multiple times — only runs once until
/// [resetOnLogout].
///
/// Gamification (achievements + activity score + streak) is owned by
/// [DashboardScreen._scheduleGamificationBootstrap] to avoid duplicate DB work.
class StartupBootstrap {
  StartupBootstrap._();

  static bool _scheduled = false;

  static void resetOnLogout() {
    _scheduled = false;
  }

  /// Warm profile cache for screens that read role/id during first paint.
  static void schedulePostLoginLoads() {
    if (_scheduled) return;
    _scheduled = true;

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 200), () async {
        try {
          await SimpleProfileService.getCurrentProfile();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('StartupBootstrap profile prefetch error: $e');
          }
        }
      }),
    );
  }
}
