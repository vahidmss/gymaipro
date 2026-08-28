import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/product_experience/domain/coach_decision_lock.dart';
import 'package:gymaipro/features/product_experience/domain/coach_observation.dart';
import 'package:gymaipro/features/product_experience/domain/exercise_coach_decision.dart';
import 'package:gymaipro/features/product_experience/domain/session_debrief.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_eligibility.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_snapshot.dart';
import 'package:gymaipro/features/session_analysis/domain/workout_calorie_estimator.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/workout_log/models/previous_exercise_performance.dart';

/// Builds [SessionAnalysisSnapshot] from a finished live-domain session.
abstract final class SessionAnalysisAssembler {
  static SessionAnalysisSnapshot assemble({
    required WorkoutSession session,
    required SessionAnalysisProgramKind programKind,
    required SessionDebrief debrief,
    Map<int, Exercise> exerciseById = const <int, Exercise>{},
    Map<String, WorkoutExerciseCoachFeedback> feedbackByExerciseKey =
        const <String, WorkoutExerciseCoachFeedback>{},
    Map<int, List<PreviousExerciseSet>> previousByExerciseId =
        const <int, List<PreviousExerciseSet>>{},
    Map<int, DateTime> previousLogDateByExerciseId = const <int, DateTime>{},
    List<CoachObservation> observations = const <CoachObservation>[],
    String? programTitle,
    String? sessionDay,
    double? bodyWeightKg,
    DateTime? endedAt,
    bool synced = true,
  }) {
    final volume = _totalVolume(session);
    final workingSeconds = _workingSeconds(session);
    final wallClock = (endedAt ?? DateTime.now())
        .difference(session.startedAt)
        .inSeconds
        .clamp(0, 6 * 3600);
    // Prefer measured work/wall time — never invent a fake "60 دقیقه".
    final durationMinutes = wallClock >= 60
        ? (wallClock / 60).round().clamp(1, 360)
        : workingSeconds >= 30
        ? (workingSeconds / 60).ceil().clamp(1, 360)
        : (session.estimatedMinutes > 0
              ? session.estimatedMinutes.clamp(1, 360)
              : 1);

    final calorieInputs = <ExerciseCalorieInput>[];
    for (final exercise in session.exercises) {
      if (!_hasMeaningfulWork(exercise)) continue;
      final catalog = exercise.exerciseId == null
          ? null
          : exerciseById[exercise.exerciseId!];
      calorieInputs.add(
        ExerciseCalorieInput.fromCatalog(
          exercise: catalog,
          volumeKg: _exerciseVolume(exercise),
          workingSeconds: _exerciseWorkingSeconds(exercise),
        ),
      );
    }

    final calories = WorkoutCalorieEstimator.estimateKcal(
      bodyWeightKg: bodyWeightKg,
      totalVolumeKg: volume,
      workingSeconds: workingSeconds,
      wallClockSeconds: wallClock,
      exercises: calorieInputs,
    );

    final comparisons = <SessionExerciseComparison>[];
    final suggestions = <SessionNextSuggestion>[];

    for (final exercise in session.exercises) {
      if (!_hasMeaningfulWork(exercise)) continue;
      final feedback =
          feedbackByExerciseKey[exercise.id] ??
          feedbackByExerciseKey['${exercise.exerciseId}'];
      final decision = feedback?.decision;
      final previous = exercise.exerciseId == null
          ? const <PreviousExerciseSet>[]
          : (previousByExerciseId[exercise.exerciseId!] ??
                const <PreviousExerciseSet>[]);
      final hasPrevious = previous.any((s) => s.hasMeaningfulData);
      final previousDate = exercise.exerciseId == null
          ? null
          : previousLogDateByExerciseId[exercise.exerciseId!];

      comparisons.add(
        SessionExerciseComparison(
          exerciseName: exercise.name,
          todaySets: _todaySets(exercise),
          previousSets: previous,
          previousLogDate: previousDate,
          badge: _displayBadge(decision: decision, hasPrevious: hasPrevious),
          comparisonLine: _comparisonLine(
            feedback: feedback,
            hasPrevious: hasPrevious,
          ),
          decision: decision,
          isFirstLogged: !hasPrevious,
        ),
      );

      if (decision != null) {
        suggestions.add(
          SessionNextSuggestion(
            title: exercise.name,
            body: decision.targetLine ?? decision.actionLabel,
          ),
        );
      } else if (feedback?.nextSession != null &&
          feedback!.nextSession!.trim().isNotEmpty) {
        suggestions.add(
          SessionNextSuggestion(
            title: exercise.name,
            body: feedback.nextSession!,
          ),
        );
      }
    }

    if (suggestions.isEmpty && debrief.nextFocus.trim().isNotEmpty) {
      suggestions.add(
        SessionNextSuggestion(title: 'تمرکز جلسه بعد', body: debrief.nextFocus),
      );
    }

    final mergedObservations = observations.isNotEmpty
        ? observations
        : CoachObservationDetector.fromDebrief(debrief);

    final lock = CoachDecisionLock.buildPackage(
      decisions: debrief.decisions,
      debrief: debrief,
      observations: mergedObservations,
    );

    return SessionAnalysisSnapshot(
      programKind: programKind,
      focus: session.focus,
      programTitle: (programTitle != null && programTitle.trim().isNotEmpty)
          ? programTitle.trim()
          : session.title,
      sessionDay: sessionDay,
      programId: session.programId,
      completedSets: session.completedSets,
      totalSets: session.totalSets,
      completedExercises: debrief.completedExercises,
      plannedExercises: debrief.plannedExercises,
      totalVolumeKg: volume,
      durationMinutes: durationMinutes,
      estimatedCaloriesKcal: calories,
      skippedExerciseNames: debrief.skippedExerciseNames,
      comparisons: comparisons,
      suggestions: suggestions,
      debrief: debrief,
      observations: mergedObservations,
      decisionLock: lock,
      synced: synced,
    );
  }

  static String? _displayBadge({
    required ExerciseDecision? decision,
    required bool hasPrevious,
  }) {
    if (!hasPrevious) return 'اولین ثبت';
    if (decision == null) return null;
    switch (decision.action) {
      case ExerciseCoachAction.increase:
        return 'وزنه بیشتر';
      case ExerciseCoachAction.hold:
        return decision.isIncompleteVolume
            ? 'ست ناقص'
            : (decision.actionLabel.contains('تثبیت')
                  ? 'تثبیت کن'
                  : 'همون وزنه');
      case ExerciseCoachAction.bridge:
        return 'دو ست پایه، آخر سنگین';
      case ExerciseCoachAction.bodyProgress:
        return 'سبک‌تر پیش برو';
    }
  }

  static String? _comparisonLine({
    required WorkoutExerciseCoachFeedback? feedback,
    required bool hasPrevious,
  }) {
    if (!hasPrevious) {
      return 'اولین باریه که این حرکت رو ثبت می‌کنی. '
          'هنوز چیزی برای مقایسه با قبل نداریم.';
    }
    final parts = <String>[
      if (feedback?.decision?.previousComparison?.trim().isNotEmpty == true)
        feedback!.decision!.previousComparison!.trim(),
      if (feedback?.analysis?.trim().isNotEmpty == true)
        feedback!.analysis!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  static double _totalVolume(WorkoutSession session) {
    var volume = 0.0;
    for (final exercise in session.exercises) {
      volume += _exerciseVolume(exercise);
    }
    return volume;
  }

  static double _exerciseVolume(WorkoutExerciseSession exercise) {
    var volume = 0.0;
    for (final set in exercise.sets) {
      if (set.status != WorkoutSetSessionStatus.completed &&
          set.status != WorkoutSetSessionStatus.failed) {
        continue;
      }
      volume += (set.actualReps ?? 0) * (set.actualWeightKg ?? 0);
    }
    return volume;
  }

  static int _workingSeconds(WorkoutSession session) {
    var total = 0;
    for (final exercise in session.exercises) {
      total += _exerciseWorkingSeconds(exercise);
    }
    return total;
  }

  static int _exerciseWorkingSeconds(WorkoutExerciseSession exercise) {
    var total = 0;
    for (final set in exercise.sets) {
      if (set.status != WorkoutSetSessionStatus.completed &&
          set.status != WorkoutSetSessionStatus.failed) {
        continue;
      }
      total += set.durationSeconds ?? 0;
    }
    return total;
  }

  static List<PreviousExerciseSet> _todaySets(WorkoutExerciseSession exercise) {
    final out = <PreviousExerciseSet>[];
    for (final set in exercise.sets) {
      if (set.status != WorkoutSetSessionStatus.completed &&
          set.status != WorkoutSetSessionStatus.failed) {
        continue;
      }
      final reps = set.actualReps ?? 0;
      final weight = set.actualWeightKg ?? 0;
      final seconds = set.durationSeconds;
      if ((reps <= 0) && (weight <= 0) && (seconds == null || seconds <= 0)) {
        continue;
      }
      out.add(
        PreviousExerciseSet(
          reps: reps > 0 ? reps : null,
          weight: weight > 0 ? weight : null,
          seconds: seconds,
        ),
      );
    }
    return out;
  }

  static bool _hasMeaningfulWork(WorkoutExerciseSession exercise) {
    if (exercise.sets.isEmpty) return false;
    return exercise.sets.any((set) {
      if (set.status == WorkoutSetSessionStatus.skipped) return false;
      final reps = set.actualReps ?? 0;
      final weight = set.actualWeightKg ?? 0;
      final seconds = set.durationSeconds ?? 0;
      return reps > 0 || weight > 0 || seconds > 0;
    });
  }
}
