import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/academy/services/music_player_service.dart';
import 'package:gymaipro/chat/services/chat_presence_service.dart';
import 'package:gymaipro/core/app_initializer.dart';
import 'package:gymaipro/core/crash_report_service.dart';
import 'package:gymaipro/core/foreground_resume_coordinator.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/notification/services/notification_fallback_sync_service.dart';
import 'package:gymaipro/notification/services/push_health_monitor.dart';
import 'package:gymaipro/payment/services/payment_deeplink_service.dart';
import 'package:gymaipro/payment/services/payment_resume_tracker.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/wallet_refresh_notifier.dart';
import 'package:gymaipro/services/presence_service.dart';
import 'package:gymaipro/utils/external_url_launcher.dart';

class LifecycleObserver extends StatefulWidget {
  const LifecycleObserver({required this.child, super.key});
  final Widget child;

  @override
  State<LifecycleObserver> createState() => _LifecycleObserverState();

  static bool get isAppInBackground =>
      _LifecycleObserverState._currentState == AppLifecycleState.paused ||
      _LifecycleObserverState._currentState == AppLifecycleState.hidden ||
      _LifecycleObserverState._currentState == AppLifecycleState.detached;
}

class _LifecycleObserverState extends State<LifecycleObserver>
    with WidgetsBindingObserver {
  NotificationService? _notificationService;
  static AppLifecycleState _currentState = AppLifecycleState.resumed;
  Timer? _presenceHeartbeat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (!kIsWeb) {
      _notificationService = NotificationService();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (mounted) unawaited(_markActive('initState'));
      });
    });
  }

  @override
  void dispose() {
    _presenceHeartbeat?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startPresenceHeartbeat() {
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_currentState == AppLifecycleState.resumed) {
        unawaited(PresenceService.instance.bumpForeground(source: 'heartbeat'));
      }
    });
  }

  void _stopPresenceHeartbeat() {
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentState = state;

    if (state == AppLifecycleState.resumed) {
      if (ForegroundResumeCoordinator.isPaymentReturnGraceActive) {
        unawaited(_markActive('resumed', light: true));
        return;
      }
      unawaited(_markActive('resumed'));
      unawaited(CrashReportService.instance.flush());
      unawaited(_pollPendingWalletTopup());
      unawaited(_pollPendingDirectPayment());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_markInactive('$state'));
      if (state == AppLifecycleState.detached) {
        MusicPlayerService().handleAppDetached().catchError((Object e) {
          if (kDebugMode) {
            debugPrint('LifecycleObserver music stop on detach: $e');
          }
        });
      }
    }
  }

  Future<void> _pollPendingWalletTopup() async {
    if (ForegroundResumeCoordinator.isPaymentReturnGraceActive) return;
    if (PaymentResumeTracker.instance.pendingSessionId == null) return;

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (ForegroundResumeCoordinator.isPaymentReturnGraceActive) return;
    await ExternalUrlLauncher.closePaymentBrowserIfOpen();
    final result = await PaymentResumeTracker.instance.pollIfPending();
    if (result == PaymentResumeResult.success) {
      try {
        await WalletService().refreshUserWallet();
        WalletRefreshNotifier.notifyRefresh(balanceAlreadyRefreshed: true);
      } catch (_) {
        WalletRefreshNotifier.notifyRefresh();
      }
    }
  }

  Future<void> _pollPendingDirectPayment() async {
    if (ForegroundResumeCoordinator.isPaymentReturnGraceActive) return;
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (ForegroundResumeCoordinator.isPaymentReturnGraceActive) return;
    await ExternalUrlLauncher.closePaymentBrowserIfOpen();
    await PaymentDeeplinkService().resumePendingDirectPaymentIfAny();
  }

  Future<void> _markActive(String source, {bool light = false}) async {
    if (!AppInitializer.isSupabaseReady) return;
    try {
      if (kDebugMode) debugPrint('LifecycleObserver mark active from: $source');
      await PresenceService.instance.bumpForeground(source: source);
      _startPresenceHeartbeat();
      if (_notificationService != null) {
        unawaited(_notificationService!.touchDeviceLastSeen());
      }
      if (!light &&
          ForegroundResumeCoordinator.shouldRunFallbackSync(source)) {
        unawaited(
          NotificationFallbackSyncService().syncOnForeground(reason: source),
        );
      }
      unawaited(PushHealthMonitor.instance.refresh());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LifecycleObserver _markActive error: $e');
      }
    }
  }

  Future<void> _markInactive(String source) async {
    if (!AppInitializer.isSupabaseReady) return;
    try {
      if (kDebugMode) {
        debugPrint('LifecycleObserver mark INACTIVE from: $source');
      }
      _stopPresenceHeartbeat();
      await PresenceService.instance.markBackground(source: source);
      await ChatPresenceService().markAllInactiveForCurrentUser();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
