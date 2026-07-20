import 'package:flutter/material.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/workout_log/widgets/session_change_dialog.dart';

/// Confirms session change and applies cleanup (same rules as Workout Log).
class WorkoutSessionSelectionHelper {
  const WorkoutSessionSelectionHelper._();

  static Future<bool> confirmAndApply({
    required BuildContext context,
    required SessionChangeEvaluation evaluation,
    required String newSessionDay,
    required WorkoutSessionSelectionGateway sessionGateway,
  }) async {
    final shouldWarn = evaluation.requiresConfirmation &&
        (evaluation.hasSavedLog || evaluation.hasUnsavedData);

    if (!shouldWarn) {
      // Empty live-workout shells / ghost flags should not warn, but still
      // clear so the next session does not resume a stale empty draft.
      await sessionGateway.applySessionChangeCleanup(
        sessionDayToDelete: '',
      );
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => SessionChangeDialog(
        dateTime: DateTime.now(),
        loggedSessionDay: evaluation.loggedSessionDayForDialog,
        newSessionDay: newSessionDay,
        hasUnsavedData: evaluation.hasUnsavedData,
      ),
    );

    if (confirmed != true) return false;

    await sessionGateway.applySessionChangeCleanup(
      sessionDayToDelete: evaluation.sessionDayToDelete ?? '',
    );
    return true;
  }
}
