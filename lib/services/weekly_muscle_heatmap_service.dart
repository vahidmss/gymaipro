import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/muscle_heatmap_aggregate.dart';
import 'package:gymaipro/services/muscle_heatmap_insights.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';

/// نتیجهٔ تجمیع هیت‌مپ هفتگی — فقط نمایش بصری.
class WeeklyMuscleHeatmapResult {
  const WeeklyMuscleHeatmapResult({
    required this.targets,
    required this.previousWeekTargets,
    required this.workoutDays,
    required this.sessionCount,
    required this.previousSessionCount,
    required this.hasHeatmapData,
    required this.hasPreviousWeekData,
    this.balanceLine,
    this.weekTrendLine,
    this.programGapLine,
  });

  factory WeeklyMuscleHeatmapResult.empty() => const WeeklyMuscleHeatmapResult(
        targets: {},
        previousWeekTargets: {},
        workoutDays: 0,
        sessionCount: 0,
        previousSessionCount: 0,
        hasHeatmapData: false,
        hasPreviousWeekData: false,
      );

  final Map<String, int> targets;
  final Map<String, int> previousWeekTargets;
  final int workoutDays;
  final int sessionCount;
  final int previousSessionCount;
  final bool hasHeatmapData;
  final bool hasPreviousWeekData;
  final String? balanceLine;
  final String? weekTrendLine;
  final String? programGapLine;

  bool get hasAnyWorkout => sessionCount > 0;

  String? get topMuscleLabel => MuscleHeatmapInsights.topMuscleLabel(targets);

  String? get lightMuscleLabel => MuscleHeatmapInsights.lightMuscleLabel(targets);

  String get activityLine => MuscleHeatmapInsights.activityLine(
        workoutDays: workoutDays,
        sessionCount: sessionCount,
      );
}

/// تجمیع `muscle_targets` — ۷ روز اخیر + مقایسه و پوشش برنامه.
class WeeklyMuscleHeatmapService {
  WeeklyMuscleHeatmapService({
    WorkoutDailyLogService? logService,
    ExerciseService? exerciseService,
    ActiveProgramService? activeProgramService,
    WorkoutProgramService? programService,
  })  : _logService = logService ?? WorkoutDailyLogService(),
        _exerciseService = exerciseService ?? ExerciseService(),
        _activeProgramService = activeProgramService ?? ActiveProgramService(),
        _programService = programService ?? WorkoutProgramService();

  final WorkoutDailyLogService _logService;
  final ExerciseService _exerciseService;
  final ActiveProgramService _activeProgramService;
  final WorkoutProgramService _programService;

  static const int _currentDays = 7;
  static const int _compareDays = 14;

  Future<WeeklyMuscleHeatmapResult> loadForUser(String userId) async {
    if (userId.isEmpty) return WeeklyMuscleHeatmapResult.empty();

    final today = _dateOnly(DateTime.now());
    final currentStart = today.subtract(const Duration(days: _currentDays - 1));
    final previousStart = today.subtract(const Duration(days: _compareDays - 1));
    final previousEnd = currentStart.subtract(const Duration(days: 1));

    final logs = await _logService.getUserDailyLogs(userId);
    if (logs.isEmpty) return WeeklyMuscleHeatmapResult.empty();

    var exercises = _exerciseService.cachedExercisesSync;
    if (exercises.isEmpty) {
      exercises = await _exerciseService.getExercises();
    }
    final byId = {for (final e in exercises) e.id: e};

    final current = _aggregateWindow(
      logs: logs,
      start: currentStart,
      end: today,
      byId: byId,
    );
    final previous = _aggregateWindow(
      logs: logs,
      start: previousStart,
      end: previousEnd,
      byId: byId,
    );

    final targets = current.targets;
    final hasHeatmap = MuscleTargets.hasData(targets);
    final hasPrev = MuscleTargets.hasData(previous.targets);

    final programKeys = await _programMuscleKeys(byId);
    final gapLine = hasHeatmap
        ? MuscleHeatmapInsights.programGapLine(
            programMuscleKeys: programKeys,
            weekTargets: targets,
          )
        : null;

    return WeeklyMuscleHeatmapResult(
      targets: targets,
      previousWeekTargets: previous.targets,
      workoutDays: current.days.length,
      sessionCount: current.sessionCount,
      previousSessionCount: previous.sessionCount,
      hasHeatmapData: hasHeatmap,
      hasPreviousWeekData: hasPrev,
      balanceLine: hasHeatmap
          ? MuscleHeatmapInsights.balanceLine(targets)
          : null,
      weekTrendLine: hasHeatmap || current.sessionCount > 0
          ? MuscleHeatmapInsights.weekTrendLine(
              current: targets,
              previous: previous.targets,
              currentSessions: current.sessionCount,
              previousSessions: previous.sessionCount,
            )
          : null,
      programGapLine: gapLine,
    );
  }

  Future<Set<String>> _programMuscleKeys(Map<int, Exercise> byId) async {
    try {
      final state = await _activeProgramService.getActiveProgramState();
      final programId = state?['active_program_id'] as String?;
      if (programId == null || programId.isEmpty) return {};

      final program = await _programService.getProgramById(programId);
      if (program == null) return {};

      final keys = <String>{};
      for (final session in program.sessions) {
        for (final exercise in session.exercises) {
          if (exercise is NormalExercise) {
            _addExerciseMuscles(keys, byId, exercise.exerciseId);
          } else if (exercise is SupersetExercise) {
            for (final item in exercise.exercises) {
              _addExerciseMuscles(keys, byId, item.exerciseId);
            }
          }
        }
      }
      return keys;
    } catch (_) {
      return {};
    }
  }

  void _addExerciseMuscles(
    Set<String> keys,
    Map<int, Exercise> byId,
    int exerciseId,
  ) {
    final exercise = byId[exerciseId];
    if (exercise == null) return;
    final mt = exercise.muscleTargets;
    if (!MuscleTargets.hasData(mt)) return;
    for (final e in mt.entries) {
      if (e.value > 0) keys.add(e.key);
    }
  }

  _WindowAggregate _aggregateWindow({
    required List<WorkoutDailyLog> logs,
    required DateTime start,
    required DateTime end,
    required Map<int, Exercise> byId,
  }) {
    final combined = <String, double>{};
    var sessionCount = 0;
    final days = <String>{};

    for (final log in logs) {
      final d = _dateOnly(log.logDate);
      if (d.isBefore(start) || d.isAfter(end)) continue;

      days.add(log.logDate.toIso8601String().substring(0, 10));
      for (final session in log.sessions) {
        sessionCount++;
        final snap = MuscleHeatmapAggregate.fromExerciseLogs(
          session.exercises,
          byId,
          catalogFallback: _exerciseService.cachedExercisesSync,
        );
        for (final e in snap.targets.entries) {
          combined[e.key] = (combined[e.key] ?? 0) + e.value;
        }
      }
    }

    return _WindowAggregate(
      targets: _normalize(combined),
      sessionCount: sessionCount,
      days: days,
    );
  }

  static Map<String, int> _normalize(Map<String, double> raw) {
    if (raw.isEmpty) return {};
    final max = raw.values.fold<double>(0, (a, b) => a > b ? a : b);
    if (max <= 0) return {};
    final out = <String, int>{};
    for (final e in raw.entries) {
      out[e.key] = ((e.value / max) * 100).round().clamp(0, 100);
    }
    return out;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _WindowAggregate {
  const _WindowAggregate({
    required this.targets,
    required this.sessionCount,
    required this.days,
  });

  final Map<String, int> targets;
  final int sessionCount;
  final Set<String> days;
}
