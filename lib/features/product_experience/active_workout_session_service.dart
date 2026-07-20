import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_store.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart'
    as live;
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Port for shared session-day selection across coach workout surfaces.
abstract class WorkoutSessionSelectionGateway {
  Future<ActiveWorkoutSessionContext> loadContext({
    required String programId,
    String? userId,
  });

  Future<void> saveSelection({
    required String programId,
    required String sessionDay,
    String? userId,
  });

  Future<void> clearSelection({String? userId});

  SessionChangeEvaluation evaluateSessionChange({
    required ActiveWorkoutSessionContext context,
    required String newSessionDay,
    String? currentSessionDay,
  });

  SessionChangeEvaluation evaluateProgramChange({
    required ActiveWorkoutSessionContext context,
  });

  Future<void> applySessionChangeCleanup({
    required String sessionDayToDelete,
    String? userId,
  });
}

/// Shared session-day selection for Workout Today, Live Workout, and Workout Log.
class ActiveWorkoutSessionService implements WorkoutSessionSelectionGateway {
  ActiveWorkoutSessionService({
    WorkoutProgramService? programService,
    WorkoutDailyLogService? logService,
    LiveWorkoutSessionStore? draftStore,
  }) : _programService = programService ?? WorkoutProgramService(),
       _logService = logService ?? WorkoutDailyLogService(),
       _draftStore = draftStore ?? LiveWorkoutSessionStore();

  final WorkoutProgramService _programService;
  final WorkoutDailyLogService _logService;
  final LiveWorkoutSessionStore _draftStore;

  static String prefsKey(String userId) => 'coach_workout_session_$userId';

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String dateKey(DateTime value) {
    final d = dateOnly(value);
    return d.toIso8601String().substring(0, 10);
  }

  Future<ActiveWorkoutSessionContext> loadContext({
    required String programId,
    String? userId,
  }) async {
    final effectiveUserId =
        userId ?? await AuthHelper.getCurrentUserId() ?? '';
    final program = await _programService.getProgramById(programId);
    final sessions = program == null
        ? const <WorkoutSession>[]
        : program.sessions
              .where((session) => session.exercises.isNotEmpty)
              .toList(growable: false);

    final today = dateOnly(DateTime.now());
    String? loggedSessionDay;
    var hasSavedLog = false;

    if (effectiveUserId.isNotEmpty) {
      final dailyLog = await _logService.getDailyLogByDate(
        effectiveUserId,
        today,
        preferRemote: true,
      );
      if (dailyLog != null && _logMatchesDate(dailyLog, today)) {
        if (dailyLog.hasMeaningfulLoggedSets) {
          final saved = dailyLog.sessions
              .where(_sessionLogHasSavedSets)
              .toList(growable: false);
          if (saved.isNotEmpty) {
            loggedSessionDay = saved.last.day;
            hasSavedLog = true;
          }
        } else {
          // Ghost / empty shell in cache — do not treat as a real log.
          await _logService.deleteLogLocal(effectiveUserId, today);
        }
      }
    }

    final prefsDay = await _readPrefsSelection(
      userId: effectiveUserId,
      programId: programId,
      date: today,
    );

    final selectedSessionDay = loggedSessionDay ?? prefsDay;
    var hasLiveDraft = false;
    String? draftSessionDay;
    if (effectiveUserId.isNotEmpty) {
      final draft = await _draftStore.loadDraft(effectiveUserId);
      if (draft != null) {
        final draftDay = dateOnly(draft.session.startedAt);
        final isToday = draftDay == today;
        final hasProgress = draft.session.exercises.isNotEmpty &&
            draftHasProgress(draft.session);

        if (!isToday || !hasProgress) {
          // Stale day or empty shell — never block session switches.
          await _draftStore.clearDraft(effectiveUserId);
          if (kDebugMode) {
            debugPrint(
              '[ActiveWorkoutSession] cleared draft '
              'isToday=$isToday hasProgress=$hasProgress '
              'focus=${draft.session.focus} '
              'startedAt=${draft.session.startedAt.toIso8601String()}',
            );
          }
        } else {
          hasLiveDraft = true;
          draftSessionDay = draft.session.focus;
          if (kDebugMode) {
            debugPrint(
              '[ActiveWorkoutSession] live draft in progress '
              'focus=$draftSessionDay '
              'completedSets=${draft.session.completedSets}/'
              '${draft.session.totalSets}',
            );
          }
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[ActiveWorkoutSession] loadContext '
        'hasSavedLog=$hasSavedLog loggedDay=$loggedSessionDay '
        'hasLiveDraft=$hasLiveDraft draftDay=$draftSessionDay '
        'prefsDay=$prefsDay',
      );
    }

    return ActiveWorkoutSessionContext(
      programId: programId,
      programName: program?.name ?? '',
      sessions: sessions,
      selectedSessionDay: selectedSessionDay,
      loggedSessionDay: loggedSessionDay,
      hasSavedLog: hasSavedLog,
      hasLiveDraft: hasLiveDraft,
      draftSessionDay: draftSessionDay,
    );
  }

  Future<void> saveSelection({
    required String programId,
    required String sessionDay,
    String? userId,
  }) async {
    final effectiveUserId =
        userId ?? await AuthHelper.getCurrentUserId() ?? '';
    if (effectiveUserId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      prefsKey(effectiveUserId),
      jsonEncode(<String, Object?>{
        'date': dateKey(DateTime.now()),
        'programId': programId,
        'sessionDay': sessionDay,
      }),
    );
  }

  Future<void> clearSelection({String? userId}) async {
    final effectiveUserId =
        userId ?? await AuthHelper.getCurrentUserId() ?? '';
    if (effectiveUserId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey(effectiveUserId));
  }

  @override
  SessionChangeEvaluation evaluateSessionChange({
    required ActiveWorkoutSessionContext context,
    required String newSessionDay,
    String? currentSessionDay,
  }) {
    final current = currentSessionDay ?? context.selectedSessionDay;
    if (current == newSessionDay) {
      return const SessionChangeEvaluation.none();
    }

    // Selecting the same session the live draft already belongs to is resume,
    // not a destructive change — even when prefs selection is still null.
    if (context.hasLiveDraft &&
        context.draftSessionDay != null &&
        context.draftSessionDay == newSessionDay) {
      return const SessionChangeEvaluation.none();
    }

    final conflictWithSavedLog = context.hasSavedLog &&
        context.loggedSessionDay != null &&
        context.loggedSessionDay != newSessionDay;

    final conflictWithDraft = context.hasLiveDraft &&
        (context.draftSessionDay == null ||
            context.draftSessionDay != newSessionDay);

    if (!conflictWithSavedLog && !conflictWithDraft) {
      return const SessionChangeEvaluation.none();
    }

    return SessionChangeEvaluation.needConfirm(
      sessionDayToDelete:
          context.loggedSessionDay ?? context.draftSessionDay ?? current,
      loggedSessionDayForDialog:
          current ??
          context.draftSessionDay ??
          context.loggedSessionDay ??
          '',
      hasUnsavedData: conflictWithDraft,
      hasSavedLog: conflictWithSavedLog,
    );
  }

  @override
  SessionChangeEvaluation evaluateProgramChange({
    required ActiveWorkoutSessionContext context,
  }) {
    if (!context.hasSavedLog && !context.hasLiveDraft) {
      return const SessionChangeEvaluation.none();
    }

    return SessionChangeEvaluation.needConfirm(
      sessionDayToDelete:
          context.loggedSessionDay ?? context.selectedSessionDay,
      loggedSessionDayForDialog:
          context.selectedSessionDay ?? context.loggedSessionDay ?? '',
      hasUnsavedData: context.hasLiveDraft,
      hasSavedLog: context.hasSavedLog,
    );
  }

  @override
  Future<void> applySessionChangeCleanup({
    required String sessionDayToDelete,
    String? userId,
  }) async {
    final effectiveUserId =
        userId ?? await AuthHelper.getCurrentUserId() ?? '';
    if (effectiveUserId.isEmpty) return;

    if (sessionDayToDelete.isNotEmpty) {
      await deleteTodaySessionLog(
        userId: effectiveUserId,
        sessionDay: sessionDayToDelete,
      );
    }
    await _draftStore.clearDraft(effectiveUserId);
  }

  /// Draft focus is the program session day label (`session.day`).
  static bool draftMatchesSelection({
    required String programId,
    required String sessionDay,
    required String? draftProgramId,
    required String draftFocus,
  }) {
    if (programId.isEmpty || sessionDay.isEmpty) return false;
    if (draftProgramId == null || draftProgramId.isEmpty) return false;
    return draftProgramId == programId && draftFocus == sessionDay;
  }

  Future<void> deleteTodaySessionLog({
    required String userId,
    required String sessionDay,
  }) async {
    final today = dateOnly(DateTime.now());
    await _logService.deleteLogLocal(userId, today);

    final dailyLog = await _logService.getDailyLogByDate(
      userId,
      today,
      preferRemote: true,
    );

    if (dailyLog == null || !_logMatchesDate(dailyLog, today)) return;

    final updatedSessions = dailyLog.sessions
        .where((session) => session.day != sessionDay)
        .toList(growable: false);

    if (updatedSessions.isEmpty) {
      await _logService.deleteDailyLog(dailyLog.id);
      return;
    }

    await _logService.updateDailyLog(
      WorkoutDailyLog(
        id: dailyLog.id,
        userId: dailyLog.userId,
        logDate: dailyLog.logDate,
        sessions: updatedSessions,
        createdAt: dailyLog.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  WorkoutSession? sessionByDay(
    List<WorkoutSession> sessions,
    String sessionDay,
  ) {
    for (final session in sessions) {
      if (session.day == sessionDay) return session;
    }
    return null;
  }

  Future<String?> _readPrefsSelection({
    required String userId,
    required String programId,
    required DateTime date,
  }) async {
    if (userId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['date']?.toString() != dateKey(date)) return null;
      if (decoded['programId']?.toString() != programId) return null;
      return decoded['sessionDay']?.toString();
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[ActiveWorkoutSession] prefs decode error: $error');
      }
      return null;
    }
  }

  /// True when the user has entered or completed at least one set.
  /// Pending/current pointer alone does not count — opening live workout
  /// creates that shell immediately.
  static bool draftHasProgress(live.WorkoutSession session) {
    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        final hasEnteredValues =
            (set.actualReps != null && set.actualReps! > 0) ||
            (set.actualWeightKg != null && set.actualWeightKg! > 0) ||
            (set.rpe != null && set.rpe! > 0) ||
            (set.durationSeconds != null && set.durationSeconds! > 0);
        if (hasEnteredValues) return true;
        // Completed/failed without values still means the user acted on a set.
        if (set.status == WorkoutSetSessionStatus.completed ||
            set.status == WorkoutSetSessionStatus.failed) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _logMatchesDate(WorkoutDailyLog log, DateTime expected) {
    return dateOnly(log.logDate) == dateOnly(expected);
  }

  static bool _sessionLogHasSavedSets(WorkoutSessionLog session) {
    for (final exercise in session.exercises) {
      if (exercise is NormalExerciseLog) {
        if (exercise.sets.any(_setHasData)) return true;
      } else if (exercise is SupersetExerciseLog) {
        for (final item in exercise.exercises) {
          if (item.sets.any(_setHasData)) return true;
        }
      }
    }
    return false;
  }

  static bool _setHasData(ExerciseSetLog set) {
    return (set.reps != null && set.reps! > 0) ||
        (set.seconds != null && set.seconds! > 0) ||
        (set.weight != null && set.weight! > 0) ||
        (set.rpe != null && set.rpe! > 0);
  }
}

class ActiveWorkoutSessionContext {
  const ActiveWorkoutSessionContext({
    required this.programId,
    required this.programName,
    required this.sessions,
    required this.selectedSessionDay,
    required this.loggedSessionDay,
    required this.hasSavedLog,
    required this.hasLiveDraft,
    this.draftSessionDay,
  });

  final String programId;
  final String programName;
  final List<WorkoutSession> sessions;
  final String? selectedSessionDay;
  final String? loggedSessionDay;
  final bool hasSavedLog;
  final bool hasLiveDraft;

  /// Program session day (`focus`) of the in-progress live draft, if any.
  final String? draftSessionDay;

  bool get needsSessionSelection =>
      selectedSessionDay == null || selectedSessionDay!.isEmpty;
}

class SessionChangeEvaluation {
  const SessionChangeEvaluation._({
    required this.requiresConfirmation,
    this.sessionDayToDelete,
    this.loggedSessionDayForDialog = '',
    this.hasUnsavedData = false,
    this.hasSavedLog = false,
  });

  const SessionChangeEvaluation.none()
    : this._(requiresConfirmation: false);

  factory SessionChangeEvaluation.needConfirm({
    required String? sessionDayToDelete,
    required String loggedSessionDayForDialog,
    required bool hasUnsavedData,
    required bool hasSavedLog,
  }) {
    return SessionChangeEvaluation._(
      requiresConfirmation: true,
      sessionDayToDelete: sessionDayToDelete,
      loggedSessionDayForDialog: loggedSessionDayForDialog,
      hasUnsavedData: hasUnsavedData,
      hasSavedLog: hasSavedLog,
    );
  }

  final bool requiresConfirmation;
  final String? sessionDayToDelete;
  final String loggedSessionDayForDialog;
  final bool hasUnsavedData;
  final bool hasSavedLog;
}
