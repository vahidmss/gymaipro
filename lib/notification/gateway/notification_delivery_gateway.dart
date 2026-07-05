import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';

class NotificationDeliveryHealth {
  NotificationDeliveryHealth({
    required this.backendReachable,
    required this.hasPushToken,
    required this.providerReady,
    this.pushEndpointReachable = true,
  });

  final bool backendReachable;
  final bool hasPushToken;
  final bool providerReady;

  /// FCM/Firebase endpoints are actually reachable on the current network.
  /// This is the key signal on filtered networks (e.g. some Iranian ISPs),
  /// where a stale saved token would otherwise make push look healthy.
  final bool pushEndpointReachable;

  /// FCM push can actually reach this device (not just a stale saved token).
  bool get canDeliverPush =>
      backendReachable &&
      providerReady &&
      hasPushToken &&
      pushEndpointReachable;

  /// @deprecated Use [canDeliverPush]. Kept for callers that already use this name.
  bool get canDeliverReliably => canDeliverPush;
}

abstract class NotificationDeliveryGateway {
  Future<NotificationDeliveryHealth> healthCheck();
  Future<void> ensureProviderState();
}

class FcmNotificationDeliveryGateway implements NotificationDeliveryGateway {
  FcmNotificationDeliveryGateway({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;

  /// FCM registration endpoint — cheap host to test real reachability.
  static const String _fcmProbeHost = 'firebaseinstallations.googleapis.com';

  @override
  Future<void> ensureProviderState() async {
    await _notificationService.syncFCMTokenIfAvailable();
  }

  @override
  Future<NotificationDeliveryHealth> healthCheck() async {
    final backendReachable =
        await ConnectivityService.instance.canReachAppBackend();
    final savedToken = await _notificationService.getSavedFCMToken();
    final hasPushToken = savedToken != null && savedToken.isNotEmpty;
    final providerReady = await _notificationService.isFcmProviderReadyCached();

    // Only bother probing the FCM endpoint when the cheaper signals already
    // look OK — avoids an extra request on obviously-offline states.
    final pushEndpointReachable = (backendReachable && providerReady)
        ? await _isFcmEndpointReachable()
        : false;

    return NotificationDeliveryHealth(
      backendReachable: backendReachable,
      hasPushToken: hasPushToken,
      providerReady: providerReady,
      pushEndpointReachable: pushEndpointReachable,
    );
  }

  /// Lightweight reachability check against a Firebase/FCM host. Any HTTP
  /// response (even 4xx) proves the endpoint is not filtered; a socket error or
  /// timeout means push is effectively blocked on this network.
  Future<bool> _isFcmEndpointReachable() async {
    if (kIsWeb) return true;
    io.HttpClient? client;
    try {
      client = io.HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
      final request = await client
          .getUrl(Uri.parse('https://$_fcmProbeHost/'))
          .timeout(const Duration(seconds: 3));
      final response = await request.close().timeout(
        const Duration(seconds: 3),
      );
      // Drain minimal to free the socket; status itself is enough of a signal.
      await response.drain<void>();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM endpoint unreachable (push filtered?): $e');
      }
      return false;
    } finally {
      client?.close(force: true);
    }
  }
}
