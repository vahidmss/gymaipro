import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';

class NotificationDeliveryHealth {
  NotificationDeliveryHealth({
    required this.backendReachable,
    required this.hasPushToken,
    required this.providerReady,
  });

  final bool backendReachable;
  final bool hasPushToken;
  final bool providerReady;

  /// FCM push can actually reach this device (not just a stale saved token).
  bool get canDeliverPush =>
      backendReachable && providerReady && hasPushToken;

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

  @override
  Future<void> ensureProviderState() async {
    await _notificationService.syncFCMTokenIfAvailable();
  }

  @override
  Future<NotificationDeliveryHealth> healthCheck() async {
    final backendReachable = await ConnectivityService.instance.canReachAppBackend();
    final savedToken = await _notificationService.getSavedFCMToken();
    final hasPushToken = savedToken != null && savedToken.isNotEmpty;
    final providerReady = await _notificationService.isFcmProviderReadyCached();

    return NotificationDeliveryHealth(
      backendReachable: backendReachable,
      hasPushToken: hasPushToken,
      providerReady: providerReady,
    );
  }
}
