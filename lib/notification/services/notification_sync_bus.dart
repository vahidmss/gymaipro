import 'dart:async';

class NotificationSyncBus {
  NotificationSyncBus._internal();
  static final NotificationSyncBus _instance = NotificationSyncBus._internal();
  static NotificationSyncBus get instance => _instance;

  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void ping() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
