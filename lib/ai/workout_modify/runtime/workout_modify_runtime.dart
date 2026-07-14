import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout_modify/modifier/workout_modify_engine.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_request.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_result.dart';

/// Runtime entry for workout program modification.
///
/// Not wired to CoachPipeline — prepared for future integration.
class WorkoutModifyRuntime {
  const WorkoutModifyRuntime({
    WorkoutModifyEngine? engine,
    this.enforceCoachV2Gate = true,
  }) : _engine = engine;

  final WorkoutModifyEngine? _engine;
  final bool enforceCoachV2Gate;

  WorkoutModifyEngine get engine =>
      _engine ?? WorkoutModifyEngine(enforceCoachV2Gate: enforceCoachV2Gate);

  /// Modifies an existing [program] according to [modifications].
  WorkoutModificationResult modify({
    required WorkoutProgram program,
    required List<WorkoutModificationType> modifications,
    CoachContext? context,
    List<ExerciseProfile>? catalogProfiles,
    Map<String, Object?> options = const <String, Object?>{},
  }) {
    final request = WorkoutModificationRequest(
      program: program,
      context: context ?? CoachContext.empty(),
      modifications: modifications,
      catalogProfiles: catalogProfiles ?? const <ExerciseProfile>[],
      options: options,
    );
    return engine.modify(request);
  }
}
