import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// یک ست از آخرین اجرای ثبت‌شدهٔ همان حرکت.
class PreviousExerciseSet {
  const PreviousExerciseSet({
    this.reps,
    this.weight,
    this.seconds,
  });

  final int? reps;
  final double? weight;
  final int? seconds;

  bool get hasMeaningfulData =>
      (reps != null && reps! > 0) ||
      (weight != null && weight! > 0) ||
      (seconds != null && seconds! > 0);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (seconds != null) 'seconds': seconds,
    };
  }

  static PreviousExerciseSet fromJson(Map<String, dynamic> json) {
    return PreviousExerciseSet(
      reps: json['reps'] is num ? (json['reps'] as num).round() : null,
      weight: json['weight'] is num ? (json['weight'] as num).toDouble() : null,
      seconds: json['seconds'] is num ? (json['seconds'] as num).round() : null,
    );
  }

  String get summaryLabel {
    if (seconds != null && seconds! > 0 && (reps == null || reps! <= 0)) {
      return '${seconds!}ث';
    }
    final r = (reps != null && reps! > 0) ? reps.toString() : null;
    final w = _formatWeight(weight);
    if (r != null && w != null) return '\u200E$r\u00D7$w';
    if (r != null) return r;
    if (w != null) return '${w}kg';
    return '—';
  }

  static String? _formatWeight(double? weight) {
    if (weight == null || weight <= 0) return null;
    if (weight == weight.roundToDouble()) return weight.toInt().toString();
    return weight.toString();
  }
}

/// آخرین عملکرد meaningful یک حرکت به‌همراه تاریخ لاگ مبدأ.
class PreviousExerciseRecord {
  const PreviousExerciseRecord({
    required this.sets,
    this.logDate,
  });

  final List<PreviousExerciseSet> sets;
  final DateTime? logDate;

  bool get hasData => sets.any((s) => s.hasMeaningfulData);
}

/// استخراج آخرین ست‌های meaningful برای هر exerciseId از لاگ‌های قدیمی‌تر.
class PreviousExercisePerformance {
  const PreviousExercisePerformance._();

  /// [logs] باید فقط قبل از روز جاری باشد.
  /// مرتب‌سازی جدید→قدیم اینجا هم harden می‌شود تا تقدم/تأخر خراب نشود.
  static Map<int, List<PreviousExerciseSet>> fromLogs({
    required List<WorkoutDailyLog> logs,
    required Set<int> exerciseIds,
  }) {
    final detailed = fromLogsWithMeta(logs: logs, exerciseIds: exerciseIds);
    return <int, List<PreviousExerciseSet>>{
      for (final e in detailed.entries) e.key: e.value.sets,
    };
  }

  static Map<int, PreviousExerciseRecord> fromLogsWithMeta({
    required List<WorkoutDailyLog> logs,
    required Set<int> exerciseIds,
  }) {
    if (exerciseIds.isEmpty || logs.isEmpty) return const {};

    final ordered = List<WorkoutDailyLog>.of(logs)
      ..sort((a, b) {
        final byDate = b.logDate.compareTo(a.logDate);
        if (byDate != 0) return byDate;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    final remaining = Set<int>.of(exerciseIds);
    final result = <int, PreviousExerciseRecord>{};

    for (final log in ordered) {
      if (remaining.isEmpty) break;
      final foundToday = <int, List<PreviousExerciseSet>>{};

      for (final session in log.sessions) {
        for (final exercise in session.exercises) {
          if (exercise is NormalExerciseLog) {
            _collect(
              into: foundToday,
              remaining: remaining,
              exerciseId: exercise.exerciseId,
              sets: exercise.sets,
            );
          } else if (exercise is SupersetExerciseLog) {
            for (final item in exercise.exercises) {
              _collect(
                into: foundToday,
                remaining: remaining,
                exerciseId: item.exerciseId,
                sets: item.sets,
              );
            }
          }
        }
      }

      final day = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      for (final entry in foundToday.entries) {
        if (!result.containsKey(entry.key)) {
          result[entry.key] = PreviousExerciseRecord(
            sets: entry.value,
            logDate: day,
          );
          remaining.remove(entry.key);
        }
      }
    }

    return result;
  }

  static void _collect({
    required Map<int, List<PreviousExerciseSet>> into,
    required Set<int> remaining,
    required int exerciseId,
    required List<ExerciseSetLog> sets,
  }) {
    if (!remaining.contains(exerciseId) || into.containsKey(exerciseId)) {
      return;
    }
    final meaningful = <PreviousExerciseSet>[];
    for (final set in sets) {
      final mapped = PreviousExerciseSet(
        reps: set.reps,
        weight: set.weight,
        seconds: set.seconds,
      );
      if (mapped.hasMeaningfulData) meaningful.add(mapped);
    }
    if (meaningful.isEmpty) return;
    into[exerciseId] = meaningful;
  }
}
