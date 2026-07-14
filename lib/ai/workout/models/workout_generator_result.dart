import 'package:gymaipro/ai/workout/models/workout_follow_up_field.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_reason.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_selection_trace.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';

/// Outcome status for workout generation.
enum WorkoutGeneratorStatus {
  success,
  needsFollowUp,
  entitlementBlocked,
  validationFailed,
  blueprintInvalid,
  insufficientExercises,
}

/// Typed result from the Coach workout generator runtime.
class WorkoutGeneratorResult {
  const WorkoutGeneratorResult({
    required this.status,
    this.program,
    this.followUpFields = const <WorkoutFollowUpField>[],
    this.reasons = const <WorkoutGeneratorReason>[],
    this.validationIssues = const <String>[],
    this.selectionTrace,
    this.message,
  });

  factory WorkoutGeneratorResult.followUp({
    required List<WorkoutFollowUpField> fields,
    List<WorkoutGeneratorReason> reasons = const <WorkoutGeneratorReason>[],
  }) {
    return WorkoutGeneratorResult(
      status: WorkoutGeneratorStatus.needsFollowUp,
      followUpFields: fields,
      reasons: reasons,
      message: 'Need follow-up: ${fields.map((f) => f.name).join(', ')}',
    );
  }

  factory WorkoutGeneratorResult.blocked({
    required String message,
    List<WorkoutGeneratorReason> reasons = const <WorkoutGeneratorReason>[],
  }) {
    return WorkoutGeneratorResult(
      status: WorkoutGeneratorStatus.entitlementBlocked,
      reasons: reasons,
      message: message,
    );
  }

  final WorkoutGeneratorStatus status;
  final WorkoutProgram? program;
  final List<WorkoutFollowUpField> followUpFields;
  final List<WorkoutGeneratorReason> reasons;
  final List<String> validationIssues;
  final WorkoutGeneratorSelectionTrace? selectionTrace;
  final String? message;

  bool get isSuccess => status == WorkoutGeneratorStatus.success && program != null;

  bool get needsFollowUp => status == WorkoutGeneratorStatus.needsFollowUp;
}
