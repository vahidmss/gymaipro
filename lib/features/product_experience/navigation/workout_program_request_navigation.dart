import 'package:flutter/material.dart';
import 'package:gymaipro/features/workout_program_request/application/workout_program_token_service.dart';
import 'package:gymaipro/features/workout_program_request/presentation/screens/workout_program_gap_fill_screen.dart';
import 'package:gymaipro/features/workout_program_request/presentation/widgets/workout_program_access_sheet.dart';

/// Opens the adaptive program-request flow (gap-fill + Coach generator).
///
/// Not chat. Not the legacy 20-question questionnaire.
/// Gates on subscription + generation token before opening the form.
abstract final class WorkoutProgramRequestNavigation {
  const WorkoutProgramRequestNavigation._();

  static Future<T?> open<T extends Object?>(BuildContext context) async {
    final access = await WorkoutProgramTokenService().checkAccess();
    if (!context.mounted) return null;

    if (!access.canBuild) {
      final purchased = await showWorkoutProgramAccessSheet(
        context,
        access: access,
      );
      if (purchased != true || !context.mounted) return null;

      final again = await WorkoutProgramTokenService().checkAccess();
      if (!context.mounted) return null;
      if (!again.canBuild) {
        await showWorkoutProgramAccessSheet(context, access: again);
        return null;
      }
    }

    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => const WorkoutProgramGapFillScreen(),
      ),
    );
  }
}
