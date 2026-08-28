import 'package:gymaipro/features/product_experience/domain/session_debrief.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// Coded, evidence-backed coach observation (no clinical diagnosis).
enum CoachObservationCode {
  cardioSkipped3x,
  coreSkipped3x,
  volumeTooHigh,
  incompleteSessions,
  returningAfterBreak,
  progressOnLifts,
}

enum CoachObservationSeverity { info, watch, action }

class CoachObservation {
  const CoachObservation({
    required this.code,
    required this.severity,
    required this.evidence,
    required this.severityLabel,
    required this.message,
  });

  final CoachObservationCode code;
  final CoachObservationSeverity severity;
  final List<String> evidence;
  final String severityLabel;
  final String message;

  Map<String, Object?> toLockJson() {
    return <String, Object?>{
      'code': code.name,
      'severity': severity.name,
      'severity_label': severityLabel,
      'evidence': evidence,
      'message': message,
    };
  }

  static CoachObservation? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.map((k, v) => MapEntry(k.toString(), v));
    final codeMatches = CoachObservationCode.values.where(
      (e) => e.name == json['code']?.toString(),
    );
    if (codeMatches.isEmpty) return null;
    final severityMatches = CoachObservationSeverity.values.where(
      (e) => e.name == json['severity']?.toString(),
    );
    final evidenceRaw = json['evidence'];
    return CoachObservation(
      code: codeMatches.first,
      severity: severityMatches.isEmpty
          ? CoachObservationSeverity.info
          : severityMatches.first,
      evidence: evidenceRaw is List
          ? evidenceRaw.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      severityLabel: json['severity_label']?.toString() ??
          json['severity']?.toString() ??
          '',
      message: json['message']?.toString() ?? '',
    );
  }
}

/// Deterministic multi-session observation detector.
abstract final class CoachObservationDetector {
  static List<CoachObservation> fromDebrief(SessionDebrief debrief) {
    final out = <CoachObservation>[];
    if (debrief.volumeTooHigh) {
      out.add(
        const CoachObservation(
          code: CoachObservationCode.volumeTooHigh,
          severity: CoachObservationSeverity.action,
          severityLabel: 'اقدام',
          evidence: <String>['skipped_count>=2', 'completion_ratio<0.85'],
          message:
              'چند تا حرکت موند؛ برنامه سنگین بوده، نه اینکه تو کم گذاشته باشی.',
        ),
      );
    }
    if (debrief.improvedCount > 0) {
      out.add(
        CoachObservation(
          code: CoachObservationCode.progressOnLifts,
          severity: CoachObservationSeverity.info,
          severityLabel: 'خبر خوب',
          evidence: <String>['improved=${debrief.improvedCount}'],
          message: debrief.improvedCount == 1
              ? 'یه حرکت امروز آمادهٔ پیشرفت جلسه بعد شد.'
              : 'امروز ${debrief.improvedCount} حرکت آمادهٔ پیشرفت جلسه بعد شدن.',
        ),
      );
    }
    return out;
  }

  /// Inspect recent daily logs (newest first) for repeatable patterns.
  static List<CoachObservation> fromRecentLogs(
    List<WorkoutDailyLog> logs, {
    int lookbackSessions = 5,
  }) {
    if (logs.isEmpty) return const <CoachObservation>[];

    final sessions = <_SessionFlags>[];
    for (final log in logs) {
      for (final session in log.sessions) {
        sessions.add(_flagsFor(session));
        if (sessions.length >= lookbackSessions) break;
      }
      if (sessions.length >= lookbackSessions) break;
    }
    if (sessions.isEmpty) return const <CoachObservation>[];

    final out = <CoachObservation>[];
    final cardioSkips =
        sessions.where((s) => s.hadCardioPlanned && !s.cardioDone).length;
    final coreSkips =
        sessions.where((s) => s.hadCorePlanned && !s.coreDone).length;
    final incomplete =
        sessions.where((s) => s.completionRatio < 0.75).length;

    if (cardioSkips >= 3) {
      out.add(
        CoachObservation(
          code: CoachObservationCode.cardioSkipped3x,
          severity: CoachObservationSeverity.watch,
          severityLabel: 'پیگیری',
          evidence: <String>['cardio_skipped=$cardioSkips/${sessions.length}'],
          message:
              'در $cardioSkips جلسه اخیر هوازی حذف شده؛ یا جایش را جلوتر بیاور یا حجم را کم کن.',
        ),
      );
    }
    if (coreSkips >= 3) {
      out.add(
        CoachObservation(
          code: CoachObservationCode.coreSkipped3x,
          severity: CoachObservationSeverity.watch,
          severityLabel: 'پیگیری',
          evidence: <String>['core_skipped=$coreSkips/${sessions.length}'],
          message:
              'در $coreSkips جلسه اخیر شکم حذف شده؛ آن را زودتر در جلسه بگذار.',
        ),
      );
    }
    if (incomplete >= 3) {
      out.add(
        CoachObservation(
          code: CoachObservationCode.incompleteSessions,
          severity: CoachObservationSeverity.action,
          severityLabel: 'اقدام',
          evidence: <String>['incomplete=$incomplete/${sessions.length}'],
          message:
              'چند جلسه اخیر نیمه‌کاره مانده؛ تعداد حرکات را کم کن تا کامل اجرا شود.',
        ),
      );
    }

    // Gap between newest and previous session dates (if available).
    if (logs.length >= 2) {
      final newest = logs.first.logDate;
      final older = logs[1].logDate;
      final gap = newest.difference(older).inDays;
      if (gap >= 6) {
        out.add(
          CoachObservation(
            code: CoachObservationCode.returningAfterBreak,
            severity: CoachObservationSeverity.info,
            severityLabel: 'یادآوری',
            evidence: <String>['gap_days=$gap'],
            message:
                '$gap روز بین دو جلسه فاصله بوده؛ برگشت را با شدت متوسط شروع کن.',
          ),
        );
      }
    }

    return out;
  }

  static List<CoachObservation> merge({
    List<CoachObservation> fromSession = const <CoachObservation>[],
    List<CoachObservation> fromHistory = const <CoachObservation>[],
    int limit = 4,
  }) {
    final byCode = <CoachObservationCode, CoachObservation>{};
    for (final item in [...fromHistory, ...fromSession]) {
      byCode[item.code] = item;
    }
    final ranked = byCode.values.toList()
      ..sort((a, b) => _rank(b.severity).compareTo(_rank(a.severity)));
    return ranked.take(limit).toList(growable: false);
  }

  static int _rank(CoachObservationSeverity severity) {
    switch (severity) {
      case CoachObservationSeverity.action:
        return 3;
      case CoachObservationSeverity.watch:
        return 2;
      case CoachObservationSeverity.info:
        return 1;
    }
  }

  static _SessionFlags _flagsFor(WorkoutSessionLog session) {
    var planned = 0;
    var done = 0;
    var hadCore = false;
    var coreDone = false;
    var hadCardio = false;
    var cardioDone = false;

    for (final exercise in session.exercises) {
      if (exercise is NormalExerciseLog) {
        planned++;
        final worked = _setsHaveWork(exercise.sets);
        if (worked) done++;
        final core = _nameLooksCore(exercise.exerciseName, exercise.tag);
        final cardio = _nameLooksCardio(exercise.exerciseName, exercise.tag);
        if (core) {
          hadCore = true;
          if (worked) coreDone = true;
        }
        if (cardio) {
          hadCardio = true;
          if (worked) cardioDone = true;
        }
      } else if (exercise is SupersetExerciseLog) {
        for (final item in exercise.exercises) {
          planned++;
          final worked = _setsHaveWork(item.sets);
          if (worked) done++;
        }
      }
    }

    return _SessionFlags(
      hadCorePlanned: hadCore,
      coreDone: coreDone,
      hadCardioPlanned: hadCardio,
      cardioDone: cardioDone,
      completionRatio: planned == 0 ? 1.0 : done / planned,
    );
  }

  static bool _setsHaveWork(List<ExerciseSetLog> sets) {
    for (final set in sets) {
      final reps = set.reps ?? 0;
      final weight = set.weight ?? 0;
      final seconds = set.seconds ?? 0;
      if (reps > 0 || weight > 0 || seconds > 0) return true;
    }
    return false;
  }

  static bool _nameLooksCore(String name, String tag) {
    final hay = '$name $tag'.toLowerCase();
    return hay.contains('شکم') ||
        hay.contains('کرانچ') ||
        hay.contains('crunch') ||
        hay.contains('abs') ||
        hay.contains('core') ||
        hay.contains('plank') ||
        hay.contains('پلانک');
  }

  static bool _nameLooksCardio(String name, String tag) {
    final hay = '$name $tag'.toLowerCase();
    return hay.contains('تردمیل') ||
        hay.contains('هوازی') ||
        hay.contains('کاردیو') ||
        hay.contains('cardio') ||
        hay.contains('treadmill') ||
        hay.contains('دوچرخه') ||
        hay.contains('elliptical');
  }
}

class _SessionFlags {
  const _SessionFlags({
    required this.hadCorePlanned,
    required this.coreDone,
    required this.hadCardioPlanned,
    required this.cardioDone,
    required this.completionRatio,
  });

  final bool hadCorePlanned;
  final bool coreDone;
  final bool hadCardioPlanned;
  final bool cardioDone;
  final double completionRatio;
}
