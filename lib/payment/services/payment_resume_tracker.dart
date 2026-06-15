import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/services/payment_session_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';

/// Tracks an in-flight wallet top-up and polls session status when the app resumes.
class PaymentResumeTracker {
  PaymentResumeTracker._();
  static final PaymentResumeTracker instance = PaymentResumeTracker._();

  final PaymentSessionService _sessions = PaymentSessionService();
  final WalletService _walletService = WalletService();

  String? pendingSessionId;
  void Function(PaymentResumeResult result)? onResult;

  void track(String sessionId, {void Function(PaymentResumeResult)? callback}) {
    pendingSessionId = sessionId;
    onResult = callback;
  }

  void clear() {
    pendingSessionId = null;
    onResult = null;
  }

  Future<PaymentResumeResult?> pollIfPending() async {
    final sessionId = pendingSessionId;
    if (sessionId == null) return null;

    try {
      final session = await _sessions.getSessionStatus(sessionId);
      if (session == null) return null;

      final status = (session['status'] as String?)?.toLowerCase() ?? '';
      if (status == 'completed') {
        await _walletService.refreshUserWallet();
        const result = PaymentResumeResult.success;
        onResult?.call(result);
        clear();
        return result;
      }
      if (status == 'failed' || status == 'cancelled') {
        const result = PaymentResumeResult.failed;
        onResult?.call(result);
        clear();
        return result;
      }
    } catch (e) {
      if (kDebugMode) {
        print('PaymentResumeTracker poll error: $e');
      }
    }
    return null;
  }
}

enum PaymentResumeResult { success, failed }
