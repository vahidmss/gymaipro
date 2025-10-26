import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/chat/services/chat_presence_service.dart';
import 'package:gymaipro/notification/notification_service.dart';

class LifecycleObserver extends StatefulWidget {
  const LifecycleObserver({required this.child, super.key});
  final Widget child;

  @override
  State<LifecycleObserver> createState() => _LifecycleObserverState();

  /// بررسی اینکه آیا اپ در background است
  static bool get isAppInBackground =>
      _LifecycleObserverState._currentState == AppLifecycleState.paused ||
      _LifecycleObserverState._currentState == AppLifecycleState.detached;
}

class _LifecycleObserverState extends State<LifecycleObserver>
    with WidgetsBindingObserver {
  NotificationService? _notificationService;
  static AppLifecycleState _currentState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Only initialize notification service for non-web platforms
    if (!kIsWeb) {
      _notificationService = NotificationService();
    }

    _markActive('initState');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentState = state;

    if (state == AppLifecycleState.resumed) {
      _markActive('resumed');

      // چک کردن pending navigation وقتی اپ از background برمی‌گردد
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Navigation pending navigation will be handled in main.dart builder
      });
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _markInactive('$state');
    }
  }

  Future<void> _markActive(String source) async {
    try {
      if (kDebugMode) debugPrint('LifecycleObserver mark active from: $source');
      if (_notificationService != null) {
        await _notificationService!.markUserActive();
      }
    } catch (_) {}
  }

  Future<void> _markInactive(String source) async {
    try {
      if (kDebugMode) {
        debugPrint('LifecycleObserver mark INACTIVE from: $source');
      }
      // Best-effort: mark all presences inactive immediately
      await ChatPresenceService().markAllInactiveForCurrentUser();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
