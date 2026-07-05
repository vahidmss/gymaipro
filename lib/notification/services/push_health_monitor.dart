import 'package:flutter/foundation.dart';
import 'package:gymaipro/notification/gateway/notification_delivery_gateway.dart';
import 'package:gymaipro/notification/push_notification_policy.dart';

/// Runtime source of truth for "can FCM push actually reach THIS device on the
/// current network?".
///
/// Firebase is filtered on some Iranian networks, so a build-time flag alone
/// cannot decide between push and in-app delivery. This monitor probes the live
/// delivery health (Firebase ready + fresh FCM token + backend reachable) when
/// the app opens / resumes and caches the result. Consumers then route each
/// alert to exactly one channel:
///   • [canReceivePushNow] == true  → let FCM show the tray (suppress local).
///   • [canReceivePushNow] == false → show the in-app/local tray fallback.
///
/// This guarantees the user never gets both at once and never gets nothing.
class PushHealthMonitor {
  PushHealthMonitor._();

  static final PushHealthMonitor instance = PushHealthMonitor._();

  /// Emits whenever the cached health flips, so widgets/badges can react.
  final ValueNotifier<bool> healthy = ValueNotifier<bool>(false);

  DateTime? _lastProbeAt;
  bool _probing = false;

  /// Raw device push health (ignores whether the app is allowed to send push).
  bool get isPushHealthy => healthy.value;

  /// The routing decision used across the app: push is both enabled AND this
  /// device can actually receive it right now.
  bool get canReceivePushNow =>
      PushNotificationPolicy.shouldAttemptServerPush && healthy.value;

  DateTime? get lastProbeAt => _lastProbeAt;

  /// Feed a health snapshot computed elsewhere (e.g. the foreground fallback
  /// sync already runs a [NotificationDeliveryGateway.healthCheck]) so we avoid
  /// a duplicate probe.
  void update(NotificationDeliveryHealth health) {
    _lastProbeAt = DateTime.now();
    final next =
        PushNotificationPolicy.isFcmPushEnabled && health.canDeliverPush;
    if (healthy.value != next) {
      healthy.value = next;
      if (kDebugMode) {
        debugPrint('🔔 Push health → ${next ? 'HEALTHY (FCM)' : 'DEGRADED (in-app)'}');
      }
    }
  }

  /// Actively probe push health. Throttled so repeated resume events are cheap.
  Future<bool> refresh({
    NotificationDeliveryGateway? gateway,
    Duration minInterval = const Duration(seconds: 20),
    bool force = false,
  }) async {
    if (kIsWeb) return false;
    if (_probing) return healthy.value;

    final now = DateTime.now();
    if (!force &&
        _lastProbeAt != null &&
        now.difference(_lastProbeAt!) < minInterval) {
      return healthy.value;
    }

    // Push disabled at build/config level → always in-app, skip the probe.
    if (!PushNotificationPolicy.isFcmPushEnabled) {
      _lastProbeAt = now;
      if (healthy.value) healthy.value = false;
      return false;
    }

    _probing = true;
    try {
      final g = gateway ?? FcmNotificationDeliveryGateway();
      // Best-effort: make sure the FCM token/provider state is fresh on this
      // network before reading the health snapshot.
      await g.ensureProviderState().timeout(
        const Duration(seconds: 6),
        onTimeout: () {},
      );
      final health = await g.healthCheck().timeout(
        const Duration(seconds: 6),
        onTimeout: () => NotificationDeliveryHealth(
          backendReachable: false,
          hasPushToken: false,
          providerReady: false,
        ),
      );
      update(health);
    } catch (e) {
      if (kDebugMode) debugPrint('PushHealthMonitor probe error: $e');
    } finally {
      _probing = false;
    }
    return healthy.value;
  }
}
