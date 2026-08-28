import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists an in-flight coach/trainer gateway payment so web/PWA (and native)
/// can still call verifyDirectPayment after return even if the deeplink is lost.
class PendingDirectPaymentTracker {
  PendingDirectPaymentTracker._();
  static final PendingDirectPaymentTracker instance =
      PendingDirectPaymentTracker._();

  static const _kType = 'pending_direct_payment_type';
  static const _kTx = 'pending_direct_payment_tx';
  static const _kTrack = 'pending_direct_payment_track';
  static const _kTrainer = 'pending_direct_payment_trainer';
  static const _kReturnTarget = 'pending_direct_payment_return_target';
  static const _kAt = 'pending_direct_payment_at';

  /// Resume the workout program builder after coach-plan gateway return.
  static const returnTargetWorkoutBuilder = 'workout_program_builder';

  /// Max age before we stop auto-verifying (avoid stale retries).
  static const maxAge = Duration(hours: 6);

  Future<void> track({
    required String type,
    required String transactionId,
    required String trackId,
    String? trainerId,
    String? returnTarget,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kType, type);
    await prefs.setString(_kTx, transactionId);
    await prefs.setString(_kTrack, trackId);
    if (trainerId != null && trainerId.isNotEmpty) {
      await prefs.setString(_kTrainer, trainerId);
    } else {
      await prefs.remove(_kTrainer);
    }
    if (returnTarget != null && returnTarget.isNotEmpty) {
      await prefs.setString(_kReturnTarget, returnTarget);
    } else {
      await prefs.remove(_kReturnTarget);
    }
    await prefs.setInt(_kAt, DateTime.now().millisecondsSinceEpoch);
    if (kDebugMode) {
      debugPrint(
        'PendingDirectPaymentTracker: tracked type=$type tx=$transactionId '
        'track=$trackId return=$returnTarget',
      );
    }
  }

  Future<PendingDirectPayment?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString(_kType);
    final tx = prefs.getString(_kTx);
    final track = prefs.getString(_kTrack);
    if (type == null || tx == null || track == null) return null;

    final atMs = prefs.getInt(_kAt) ?? 0;
    final at = DateTime.fromMillisecondsSinceEpoch(atMs);
    if (DateTime.now().difference(at) > maxAge) {
      await clear();
      return null;
    }

    return PendingDirectPayment(
      type: type,
      transactionId: tx,
      trackId: track,
      trainerId: prefs.getString(_kTrainer),
      returnTarget: prefs.getString(_kReturnTarget),
    );
  }

  /// Read return target without requiring a full pending payment payload.
  Future<String?> peekReturnTarget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kReturnTarget);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kType);
    await prefs.remove(_kTx);
    await prefs.remove(_kTrack);
    await prefs.remove(_kTrainer);
    await prefs.remove(_kReturnTarget);
    await prefs.remove(_kAt);
  }
}

class PendingDirectPayment {
  const PendingDirectPayment({
    required this.type,
    required this.transactionId,
    required this.trackId,
    this.trainerId,
    this.returnTarget,
  });

  final String type;
  final String transactionId;
  final String trackId;
  final String? trainerId;
  final String? returnTarget;

  bool get isCoachPlan => type == 'coach_plan' || type == 'coach-plan';
  bool get isTrainer => type == 'trainer';
  bool get shouldOpenWorkoutBuilder =>
      returnTarget == PendingDirectPaymentTracker.returnTargetWorkoutBuilder;
}
