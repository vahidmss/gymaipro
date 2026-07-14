import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';
import 'package:uuid/uuid.dart';

class LiveWorkoutPersistenceResult {
  const LiveWorkoutPersistenceResult({
    required this.synced,
    this.dailyLog,
  });

  final bool synced;
  final WorkoutDailyLog? dailyLog;
}

/// Persists live workout sessions into existing workout daily logs.
class LiveWorkoutSessionPersistence {
  LiveWorkoutSessionPersistence({
    WorkoutDailyLogService? logService,
  }) : _logService = logService ?? WorkoutDailyLogService();

  final WorkoutDailyLogService _logService;

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
    final existing = await _logService.getDailyLogByDate(userId, today);
    final dailyLog = existing == null
        ? WorkoutDailyLog(
            userId: userId,
            logDate: today,
            sessions: <WorkoutSessionLog>[sessionLog],
          )
        : WorkoutDailyLog(
            id: existing.id,
            userId: userId,
            logDate: today,
            sessions: <WorkoutSessionLog>[...existing.sessions, sessionLog],
            createdAt: existing.createdAt,
          );

    final saved = await _logService.saveDailyLog(dailyLog);
    return LiveWorkoutPersistenceResult(
      synced: saved != null,
      dailyLog: saved ?? dailyLog,
    );
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
      id: const Uuid().v4(),
      day: session.focus,
      programId: session.programId,
      notes: 'live_workout:${session.id}',
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
