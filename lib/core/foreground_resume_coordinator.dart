import 'package:flutter/foundation.dart';

/// Coalesces foreground/resume side-effects (presence, FCM, wallet) so payment
/// return and rapid lifecycle transitions do not stampede the main thread.
class ForegroundResumeCoordinator {
  ForegroundResumeCoordinator._();

  static DateTime? _lastPresenceBumpAt;
  static DateTime? _lastFcmSyncAt;
  static DateTime? _lastTopicSubscribeAt;
  static DateTime? _paymentReturnGraceUntil;

  static const Duration presenceCooldown = Duration(seconds: 45);
  static const Duration fcmSyncCooldown = Duration(minutes: 3);
  static const Duration topicSubscribeCooldown = Duration(minutes: 30);
  static const Duration paymentReturnGrace = Duration(seconds: 15);

  static void markPaymentReturnHandling() {
    _paymentReturnGraceUntil =
        DateTime.now().add(paymentReturnGrace);
    if (kDebugMode) {
      debugPrint(
        'ForegroundResumeCoordinator: payment return grace active '
        '(${paymentReturnGrace.inSeconds}s)',
      );
    }
  }

  static bool get isPaymentReturnGraceActive {
    final until = _paymentReturnGraceUntil;
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _paymentReturnGraceUntil = null;
      return false;
    }
    return true;
  }

  /// Presence / last_active_at / device last_seen
  static bool shouldBumpPresence(String source) {
    if (source == 'manual') return true;

    final now = DateTime.now();
    if (_lastPresenceBumpAt != null &&
        now.difference(_lastPresenceBumpAt!) < presenceCooldown) {
      if (kDebugMode) {
        debugPrint(
          'ForegroundResumeCoordinator: presence skipped ($source, cooldown)',
        );
      }
      return false;
    }
    _lastPresenceBumpAt = now;
    return true;
  }

  static bool shouldSyncFcm({bool force = false}) {
    if (force) return true;
    if (isPaymentReturnGraceActive) {
      if (kDebugMode) {
        debugPrint(
          'ForegroundResumeCoordinator: FCM sync skipped (payment grace)',
        );
      }
      return false;
    }

    final now = DateTime.now();
    if (_lastFcmSyncAt != null &&
        now.difference(_lastFcmSyncAt!) < fcmSyncCooldown) {
      if (kDebugMode) {
        debugPrint('ForegroundResumeCoordinator: FCM sync skipped (cooldown)');
      }
      return false;
    }
    _lastFcmSyncAt = now;
    return true;
  }

  static bool shouldSubscribeTopics() {
    final now = DateTime.now();
    if (_lastTopicSubscribeAt != null &&
        now.difference(_lastTopicSubscribeAt!) < topicSubscribeCooldown) {
      if (kDebugMode) {
        debugPrint(
          'ForegroundResumeCoordinator: topic subscribe skipped (cooldown)',
        );
      }
      return false;
    }
    _lastTopicSubscribeAt = now;
    return true;
  }

  static bool shouldRunFallbackSync(String reason) {
    if (reason == 'manual_debug') return true;
    if (isPaymentReturnGraceActive && reason == 'resumed') {
      if (kDebugMode) {
        debugPrint(
          'ForegroundResumeCoordinator: fallback sync deferred (payment grace)',
        );
      }
      return false;
    }
    return true;
  }

  static void resetOnLogout() {
    _lastPresenceBumpAt = null;
    _lastFcmSyncAt = null;
    _lastTopicSubscribeAt = null;
    _paymentReturnGraceUntil = null;
  }
}
