import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

/// Read-only adapter for active program and workout history.
class WorkoutContextAdapter {
  WorkoutContextAdapter({
    ActiveProgramService? activeProgramService,
    WorkoutDailyLogService? workoutLogService,
    ActiveWorkoutSessionService? sessionService,
  }) : _activeProgramService = activeProgramService ?? ActiveProgramService(),
       _workoutLogService = workoutLogService ?? WorkoutDailyLogService(),
       _sessionService = sessionService ?? ActiveWorkoutSessionService();

  final ActiveProgramService _activeProgramService;
  final WorkoutDailyLogService _workoutLogService;
  final ActiveWorkoutSessionService _sessionService;

  /// Returns the current active program state enriched with today's session.
  Future<Map<String, Object?>?> getActiveProgram() async {
    final state = await _activeProgramService.getActiveProgramState();
    if (state == null) return null;

    final enriched = Map<String, Object?>.from(state);
    final programId = state['active_program_id']?.toString().trim();
    if (programId == null || programId.isEmpty) return enriched;

    try {
      final context = await _sessionService.loadContext(programId: programId);
      enriched['program_name'] = context.programName;
      enriched['session_count'] = context.sessions.length;
      enriched['selected_session_day'] = context.selectedSessionDay;
      enriched['has_saved_log_today'] = context.hasSavedLog;
      enriched['has_live_draft'] = context.hasLiveDraft;
      enriched['needs_session_selection'] = context.needsSessionSelection;

      final todaySession = _pickTodaySession(context);
      if (todaySession != null) {
        enriched['today_session'] = <String, Object?>{
          'day': todaySession.day,
          'exercise_count': todaySession.exercises.length,
          'exercises': <Object?>[
            for (final exercise in todaySession.exercises.take(12))
              _summarizeExercise(exercise),
          ],
          if (todaySession.notes != null && todaySession.notes!.trim().isNotEmpty)
            'notes': todaySession.notes,
        };
      } else if (context.sessions.isNotEmpty) {
        enriched['available_session_days'] = <Object?>[
          for (final session in context.sessions.take(7)) session.day,
        ];
      }
    } on Object {
      // Keep the thin pointer if session enrichment fails.
    }

    return enriched;
  }

  /// Returns workout logs for [userId] without transforming log behavior.
  Future<List<WorkoutDailyLog>> getWorkoutHistory(String userId) {
    return _workoutLogService.getUserDailyLogs(userId);
  }

  WorkoutSession? _pickTodaySession(ActiveWorkoutSessionContext context) {
    final day = context.selectedSessionDay?.trim();
    if (day == null || day.isEmpty) return null;
    for (final session in context.sessions) {
      if (session.day.trim() == day) return session;
    }
    return null;
  }

  Map<String, Object?> _summarizeExercise(WorkoutExercise exercise) {
    if (exercise is NormalExercise) {
      return <String, Object?>{
        'type': 'normal',
        'name': exercise.tag,
        'exercise_id': exercise.exerciseId,
        'sets': exercise.sets.length,
      };
    }
    if (exercise is SupersetExercise) {
      return <String, Object?>{
        'type': 'superset',
        'name': exercise.tag,
        'items': exercise.exercises.length,
      };
    }
    if (exercise is TrisetExercise) {
      return <String, Object?>{
        'type': 'triset',
        'name': exercise.tag,
        'items': exercise.exercises.length,
      };
    }
    return <String, Object?>{
      'type': exercise.type.name,
      'name': exercise.tag,
    };
  }
}
