import 'dart:async';

/// سیگنال سبک برای همگام‌سازی فوری badge چت پس از resume، fallback sync یا mark-read.
class ChatUnreadSyncBus {
  ChatUnreadSyncBus._internal();
  static final ChatUnreadSyncBus _instance = ChatUnreadSyncBus._internal();
  static ChatUnreadSyncBus get instance => _instance;

  final StreamController<void> _controller =
      StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void ping() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
