import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// Applies today's saved [WorkoutSessionLog] onto a live runtime session so
/// reopening the same day shows the sets the user already logged.
class LiveWorkoutSessionHydrator {
  const LiveWorkoutSessionHydrator();

  WorkoutSession applyLog({
    required WorkoutSession session,
    required WorkoutDailyLog? dailyLog,
  }) {
    if (dailyLog == null || dailyLog.sessions.isEmpty) return session;

    final match = _findMatchingSessionLog(session, dailyLog);
    if (match == null) return session;

    final updatedExercises = <WorkoutExerciseSession>[];
    for (var i = 0; i < session.exercises.length; i++) {
      final live = session.exercises[i];
      final logged = _matchExerciseLog(live, match.exercises, i);
      if (logged == null) {
        updatedExercises.add(live);
        continue;
      }
      updatedExercises.add(_hydrateExercise(live, logged));
    }

    return session.copyWith(
      id: match.id,
      exercises: updatedExercises,
    );
  }

  WorkoutSessionLog? _findMatchingSessionLog(
    WorkoutSession session,
    WorkoutDailyLog dailyLog,
  ) {
    // Prefer exact live-session id / note.
    for (final item in dailyLog.sessions) {
      if (item.id == session.id) return item;
      final note = item.notes?.trim() ?? '';
      if (note == 'live_workout:${session.id}') return item;
    }

    // Same program day label (focus == program session.day).
    for (final item in dailyLog.sessions.reversed) {
      if (item.day != session.focus) continue;
      if (session.programId != null &&
          session.programId!.isNotEmpty &&
          item.programId != null &&
          item.programId!.isNotEmpty &&
          item.programId != session.programId) {
        continue;
      }
      return item;
    }
    return null;
  }

  WorkoutExerciseLog? _matchExerciseLog(
    WorkoutExerciseSession live,
    List<WorkoutExerciseLog> logs,
    int index,
  ) {
    if (live.exerciseId != null && live.exerciseId! > 0) {
      for (final log in logs) {
        if (log is NormalExerciseLog && log.exerciseId == live.exerciseId) {
          return log;
        }
      }
    }
    if (index >= 0 && index < logs.length) return logs[index];
    return null;
  }

  WorkoutExerciseSession _hydrateExercise(
    WorkoutExerciseSession live,
    WorkoutExerciseLog logged,
  ) {
    final loggedSets = _setsFromLog(logged);
    if (loggedSets.isEmpty) return live;

    final updatedSets = <WorkoutSetSession>[];
    for (var i = 0; i < live.sets.length; i++) {
      final template = live.sets[i];
      if (i >= loggedSets.length) {
        updatedSets.add(template);
        continue;
      }
      final saved = loggedSets[i];
      final reps = saved.reps;
      final weight = saved.weight;
      final hasData =
          (reps != null && reps > 0) ||
          (weight != null && weight > 0) ||
          (saved.seconds != null && saved.seconds! > 0) ||
          (saved.rpe != null && saved.rpe! > 0);
      if (!hasData) {
        updatedSets.add(template);
        continue;
      }
      updatedSets.add(
        template.copyWith(
          actualReps: reps != null && reps > 0 ? reps : null,
          actualWeightKg: weight != null && weight > 0 ? weight : null,
          durationSeconds: saved.seconds,
          rpe: saved.rpe,
          notes: saved.notes,
          status: WorkoutSetSessionStatus.completed,
        ),
      );
    }
    return live.copyWith(sets: updatedSets);
  }

  List<ExerciseSetLog> _setsFromLog(WorkoutExerciseLog logged) {
    if (logged is NormalExerciseLog) return logged.sets;
    if (logged is SupersetExerciseLog && logged.exercises.isNotEmpty) {
      return logged.exercises.first.sets;
    }
    return const <ExerciseSetLog>[];
  }
}
