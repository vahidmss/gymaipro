import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';

/// Single switch for server-side FCM push from the app.
///
/// To enable later (when Firebase works in Iran):
/// - Debug: set `FIREBASE_PUSH_ENABLED=true` in `.env`
/// - Release: `flutter build apk --dart-define=FIREBASE_PUSH_ENABLED=true`
class PushNotificationPolicy {
  PushNotificationPolicy._();

  /// Master toggle — off by default until Firebase is reachable for users.
  static bool get isFcmPushEnabled => AppConfig.firebasePushEnabled;

  /// Client may call Edge Functions that deliver via FCM.
  static bool get shouldAttemptServerPush =>
      isFcmPushEnabled && AppConfig.supabaseEdgeFunctionsEnabled;

  /// Local tray fallback when push is off or the device channel looks unhealthy.
  static bool shouldShowFallbackTray({required bool pushHealthy}) {
    if (!shouldAttemptServerPush) return true;
    return !pushHealthy;
  }

  /// Log once during notification init so QA can see the active mode quickly.
  static void logStartupStatus() {
    if (!kDebugMode) return;
    if (shouldAttemptServerPush) {
      debugPrint(
        '🔔 Push mode: hybrid — FCM when reachable, auto in-app fallback on '
        'filtered networks (runtime health via PushHealthMonitor)',
      );
    } else if (isFcmPushEnabled && !AppConfig.supabaseEdgeFunctionsEnabled) {
      debugPrint(
        '🔔 Push mode: FCM flag on but Edge Functions disabled — local fallback only',
      );
    } else {
      debugPrint(
        '🔔 Push mode: local/in-app only (FIREBASE_PUSH_ENABLED=false)',
      );
    }
  }
}
