import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/chat/services/chat_presence_service.dart';
import 'package:gymaipro/academy/services/music_player_service.dart';
import 'package:gymaipro/core/foreground_resume_coordinator.dart';
import 'package:gymaipro/core/app_initializer.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/notification/services/notification_fallback_sync_service.dart';
import 'package:gymaipro/notification/services/push_health_monitor.dart';
import 'package:gymaipro/payment/services/payment_resume_tracker.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/wallet_refresh_notifier.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (!kIsWeb) {
      _notificationService = NotificationService();
    }

    // Defer so Supabase is definitely ready when markUserActive runs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _markActive('initState');
      });
    });
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
      if (ForegroundResumeCoordinator.isPaymentReturnGraceActive) {
        // Deeplink handler already refreshed wallet; avoid duplicate resume work.
        unawaited(_markActive('resumed', light: true));
        return;
      }
      _markActive('resumed');
      unawaited(_pollPendingWalletTopup());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _markInactive('$state');
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

  Future<void> _markActive(String source, {bool light = false}) async {
    if (!AppInitializer.isSupabaseReady) return;
    try {
      if (kDebugMode) debugPrint('LifecycleObserver mark active from: $source');
      if (_notificationService != null &&
          ForegroundResumeCoordinator.shouldBumpPresence(source)) {
        await _notificationService!.markUserActive(source: source);
      }
      if (!light &&
          ForegroundResumeCoordinator.shouldRunFallbackSync(source)) {
        unawaited(
          NotificationFallbackSyncService().syncOnForeground(reason: source),
        );
      }
      // Re-check on every open whether FCM push works on the current network so
      // alerts route to push (when healthy) or in-app fallback (when filtered).
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
      await ChatPresenceService().markAllInactiveForCurrentUser();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
