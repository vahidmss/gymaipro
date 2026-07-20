import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';

class LiveWorkoutPersistenceResult {
  const LiveWorkoutPersistenceResult({
    required this.synced,
    this.dailyLog,
  });

  final bool synced;
  final WorkoutDailyLog? dailyLog;
}

/// Persists live workout sessions into [workout_daily_logs].
///
/// Uses a stable session id so mid-workout saves upsert the same session
/// (same behavior as dashboard workout log), instead of appending duplicates
/// only at finish.
class LiveWorkoutSessionPersistence {
  LiveWorkoutSessionPersistence({
    WorkoutDailyLogService? logService,
  }) : _logService = logService ?? WorkoutDailyLogService();

  final WorkoutDailyLogService _logService;

  static String liveSessionNote(String sessionId) => 'live_workout:$sessionId';

  /// Upsert current live session into today's daily log (cache + Supabase).
  Future<LiveWorkoutPersistenceResult> persistSession({
    required WorkoutSession session,
    required String userId,
  }) async {
    final today = DateTime(
      session.startedAt.year,
      session.startedAt.month,
      session.startedAt.day,
    );
    final sessionLog = _toSessionLog(session);
    final existing = await _logService.getDailyLogByDate(
      userId,
      today,
      preferRemote: true,
    );

    final dailyLog = mergeSessionIntoDailyLog(
      existing: existing,
      sessionLog: sessionLog,
      userId: userId,
      logDate: today,
    );

    if (existing == null) {
      final saved = await _logService.saveDailyLog(dailyLog);
      return LiveWorkoutPersistenceResult(
        synced: saved != null,
        dailyLog: saved ?? dailyLog,
      );
    }

    final updated = await _logService.updateDailyLog(dailyLog);
    return LiveWorkoutPersistenceResult(
      synced: updated,
      dailyLog: dailyLog,
    );
  }

  /// Pure merge used by [persistSession] and unit tests.
  static WorkoutDailyLog mergeSessionIntoDailyLog({
    required WorkoutDailyLog? existing,
    required WorkoutSessionLog sessionLog,
    required String userId,
    required DateTime logDate,
  }) {
    if (existing == null) {
      return WorkoutDailyLog(
        userId: userId,
        logDate: logDate,
        sessions: <WorkoutSessionLog>[sessionLog],
      );
    }

    final sessions = List<WorkoutSessionLog>.of(existing.sessions);
    final index = sessions.indexWhere(
      (item) => _isSameLiveSession(item, sessionLog),
    );
    if (index >= 0) {
      sessions[index] = sessionLog;
    } else {
      sessions.add(sessionLog);
    }

    return WorkoutDailyLog(
      id: existing.id,
      userId: existing.userId,
      logDate: existing.logDate,
      sessions: sessions,
      createdAt: existing.createdAt,
    );
  }

  static bool _isSameLiveSession(
    WorkoutSessionLog existing,
    WorkoutSessionLog incoming,
  ) {
    if (existing.id == incoming.id) return true;
    final existingNote = existing.notes?.trim() ?? '';
    final incomingNote = incoming.notes?.trim() ?? '';
    if (existingNote.isNotEmpty && existingNote == incomingNote) {
      return true;
    }
    // Re-opening live workout creates a new session uuid; still upsert the
    // same program day instead of appending a duplicate empty/partial row.
    if (existing.day == incoming.day) {
      final sameProgram = existing.programId != null &&
          existing.programId!.isNotEmpty &&
          existing.programId == incoming.programId;
      final bothLive = existingNote.startsWith('live_workout:') &&
          incomingNote.startsWith('live_workout:');
      if (sameProgram || bothLive) return true;
    }
    return false;
  }

  Future<int> countCompletedSetsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final log = await _logService.getDailyLogByDate(userId, date);
    if (log == null) return 0;
    var total = 0;
    for (final session in log.sessions) {
      for (final exercise in session.exercises) {
        if (exercise is NormalExerciseLog) {
          total += exercise.sets.length;
        } else if (exercise is SupersetExerciseLog) {
          for (final item in exercise.exercises) {
            total += item.sets.length;
          }
        }
      }
    }
    return total;
  }

  WorkoutSessionLog _toSessionLog(WorkoutSession session) {
    return WorkoutSessionLog(
      // Stable id → mid-session upserts replace the same row, not append.
      id: session.id,
      day: session.focus,
      programId: session.programId,
      notes: liveSessionNote(session.id),
      exercises: session.exercises
          .map(_toExerciseLog)
          .toList(growable: false),
    );
  }

  NormalExerciseLog _toExerciseLog(WorkoutExerciseSession exercise) {
    final notes = exercise.sets
        .map((set) => set.notes)
        .whereType<String>()
        .where((note) => note.trim().isNotEmpty)
        .join(' | ');
    return NormalExerciseLog(
      id: exercise.id,
      exerciseId: exercise.exerciseId ?? 0,
      exerciseName: exercise.name,
      tag: exercise.primaryMuscle,
      style: 'sets_reps',
      note: notes.isEmpty ? null : notes,
      sets: exercise.sets
          .where(
            (set) =>
                set.status == WorkoutSetSessionStatus.completed ||
                set.status == WorkoutSetSessionStatus.failed,
          )
          .map(
            (set) => ExerciseSetLog(
              reps: set.effectiveReps,
              weight: set.effectiveWeightKg,
              seconds: set.durationSeconds,
              rpe: set.rpe,
              notes: set.notes,
            ),
          )
          .toList(growable: false),
    );
  }
}
