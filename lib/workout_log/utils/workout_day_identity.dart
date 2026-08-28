import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// One meaningful workout identity per calendar day (passport rule).
///
/// Dashboard log and live workout share `workout_daily_logs`. Never allow a
/// second meaningful session (different program and/or session day) to append
/// for the same calendar date without an explicit cleanup first.
class WorkoutDayIdentity {
  const WorkoutDayIdentity({
    required this.sessionDay,
    this.programId,
  });

  final String sessionDay;
  final String? programId;

  /// Last meaningful session in [log], if any.
  static WorkoutDayIdentity? fromDailyLog(WorkoutDailyLog? log) {
    if (log == null || !log.hasMeaningfulLoggedSets) return null;
    WorkoutSessionLog? last;
    for (final session in log.sessions) {
      if (sessionHasMeaningfulSets(session)) {
        last = session;
      }
    }
    if (last == null) return null;
    final programId = last.programId?.trim();
    return WorkoutDayIdentity(
      sessionDay: last.day,
      programId: (programId == null || programId.isEmpty) ? null : programId,
    );
  }

  /// True when writing [programId]/[sessionDay] would create a second identity.
  bool conflictsWith({
    required String? programId,
    required String? sessionDay,
  }) {
    final incomingDay = sessionDay?.trim() ?? '';
    if (incomingDay.isNotEmpty &&
        this.sessionDay.isNotEmpty &&
        incomingDay != this.sessionDay) {
      return true;
    }

    final incomingProgram = programId?.trim();
    final loggedProgram = this.programId?.trim();
    if (incomingProgram != null &&
        incomingProgram.isNotEmpty &&
        loggedProgram != null &&
        loggedProgram.isNotEmpty &&
        incomingProgram != loggedProgram) {
      return true;
    }
    return false;
  }

  /// Whether [incoming] may upsert into [existing] without cleanup.
  static bool canUpsertSession({
    required WorkoutDailyLog? existing,
    required WorkoutSessionLog incoming,
  }) {
    final identity = fromDailyLog(existing);
    if (identity == null) return true;
    return !identity.conflictsWith(
      programId: incoming.programId,
      sessionDay: incoming.day,
    );
  }
}

/// True when the session has at least one set with real entered values.
bool sessionHasMeaningfulSets(WorkoutSessionLog session) {
  for (final exercise in session.exercises) {
    if (exercise is NormalExerciseLog) {
      if (exercise.sets.any(_setHasMeaningfulData)) return true;
    } else if (exercise is SupersetExerciseLog) {
      for (final item in exercise.exercises) {
        if (item.sets.any(_setHasMeaningfulData)) return true;
      }
    }
  }
  return false;
}

bool _setHasMeaningfulData(ExerciseSetLog set) {
  return (set.reps != null && set.reps! > 0) ||
      (set.seconds != null && set.seconds! > 0) ||
      (set.weight != null && set.weight! > 0) ||
      (set.rpe != null && set.rpe! > 0);
}

/// Thrown when persistence would create a second workout identity for a day.
class DayWorkoutConflictException implements Exception {
  const DayWorkoutConflictException([
    this.message =
        'برای این روز یک جلسه تمرین ثبت شده. اول همان را پاک کن یا ادامه بده.',
  ]);

  final String message;

  @override
  String toString() => message;
}
