import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';
import 'package:gymaipro/workout_log/utils/workout_day_identity.dart';

class LiveWorkoutPersistenceResult {
  const LiveWorkoutPersistenceResult({required this.synced, this.dailyLog});

  final bool synced;
  final WorkoutDailyLog? dailyLog;
}

/// Persists live workout sessions into [workout_daily_logs].
///
/// Uses a stable session id so mid-workout saves upsert the same session
/// (same behavior as dashboard workout log), instead of appending duplicates
/// only at finish.
class LiveWorkoutSessionPersistence {
  LiveWorkoutSessionPersistence({WorkoutDailyLogService? logService})
    : _logService = logService ?? WorkoutDailyLogService();

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
    return LiveWorkoutPersistenceResult(synced: updated, dailyLog: dailyLog);
  }

  /// Writes or clears the finished analysis on today's session without
  /// touching the logged sets.
  Future<LiveWorkoutPersistenceResult> attachSessionAnalysis({
    required WorkoutSession session,
    required String userId,
    Map<String, dynamic>? analysis,
  }) async {
    final today = DateTime(
      session.startedAt.year,
      session.startedAt.month,
      session.startedAt.day,
    );
    final existing = await _logService.getDailyLogByDate(
      userId,
      today,
      preferRemote: true,
    );
    if (existing == null || existing.sessions.isEmpty) {
      return const LiveWorkoutPersistenceResult(synced: false);
    }

    final incoming = _toSessionLog(session);
    var attached = false;
    final sessions = <WorkoutSessionLog>[];
    for (final item in existing.sessions) {
      if (_isSameLiveSession(item, incoming)) {
        sessions.add(
          item.copyWith(
            sessionAnalysis: analysis,
            clearSessionAnalysis: analysis == null,
          ),
        );
        attached = true;
      } else {
        sessions.add(item);
      }
    }
    if (!attached && sessions.length == 1) {
      sessions[0] = sessions[0].copyWith(
        sessionAnalysis: analysis,
        clearSessionAnalysis: analysis == null,
      );
      attached = true;
    }
    if (!attached) {
      return LiveWorkoutPersistenceResult(synced: false, dailyLog: existing);
    }

    final dailyLog = WorkoutDailyLog(
      id: existing.id,
      userId: existing.userId,
      logDate: existing.logDate,
      sessions: sessions,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    final updated = await _logService.updateDailyLog(dailyLog);
    return LiveWorkoutPersistenceResult(synced: updated, dailyLog: dailyLog);
  }

  /// Pure merge used by [persistSession] and unit tests.
  ///
  /// Enforces one meaningful workout identity per calendar day: upsert the
  /// same session/program day, replace ghost shells, never append a second
  /// meaningful identity (throws DayWorkoutConflictException).
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
      // Upsert and collapse to a single day identity (heal any legacy doubles).
      return WorkoutDailyLog(
        id: existing.id,
        userId: existing.userId,
        logDate: existing.logDate,
        sessions: <WorkoutSessionLog>[sessionLog],
        createdAt: existing.createdAt,
      );
    }

    if (!WorkoutDayIdentity.canUpsertSession(
      existing: existing,
      incoming: sessionLog,
    )) {
      throw const DayWorkoutConflictException();
    }

    // No meaningful identity yet — replace ghosts with the incoming session.
    return WorkoutDailyLog(
      id: existing.id,
      userId: existing.userId,
      logDate: existing.logDate,
      sessions: <WorkoutSessionLog>[sessionLog],
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
    // same program day — never match across different programs.
    if (existing.day == incoming.day) {
      final existingProgram = existing.programId?.trim() ?? '';
      final incomingProgram = incoming.programId?.trim() ?? '';
      if (existingProgram.isNotEmpty &&
          incomingProgram.isNotEmpty &&
          existingProgram == incomingProgram) {
        return true;
      }
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
      exercises: session.exercises.map(_toExerciseLog).toList(growable: false),
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
              reps: set.actualReps ?? 0,
              weight: set.actualWeightKg ?? 0,
              seconds: set.durationSeconds,
              rpe: set.rpe,
              notes: set.notes,
            ),
          )
          .toList(growable: false),
    );
  }
}
