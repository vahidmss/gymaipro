import 'dart:math' as math;

import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

/// One logged set compared against prescription targets.
class LoggedSetPerformance {
  const LoggedSetPerformance({
    required this.actualReps,
    required this.actualWeightKg,
    this.targetReps,
    this.targetWeightKg,
    this.actualSeconds,
    this.targetSeconds,
    this.rpe,
  });

  final int? targetReps;
  final double? targetWeightKg;
  final int actualReps;
  final double actualWeightKg;
  final int? actualSeconds;
  final int? targetSeconds;

  /// Perceived effort 1–10 (app label: شدت / RPE).
  final int? rpe;

  bool get hasRepPerformance => actualReps > 0;
  bool get hasWeight => actualWeightKg > 0;
  bool get hasTimedPerformance => (actualSeconds ?? 0) > 0;
}

/// Rule-based coach note after all sets of one exercise are logged.
class WorkoutExerciseCoachFeedback {
  const WorkoutExerciseCoachFeedback({
    this.analysis,
    this.nextSession,
    this.formTip,
  });

  final String? analysis;
  final String? nextSession;
  final String? formTip;

  bool get isEmpty =>
      (analysis == null || analysis!.isEmpty) &&
      (nextSession == null || nextSession!.isEmpty) &&
      (formTip == null || formTip!.isEmpty);

  List<String> get lines {
    return <String>[
      if (analysis != null && analysis!.isNotEmpty) analysis!,
      if (nextSession != null && nextSession!.isNotEmpty) nextSession!,
      if (formTip != null && formTip!.isNotEmpty) formTip!,
    ];
  }
}

/// Session pattern used for coaching decisions.
enum _Pattern {
  stableReady,
  stableHoldMissedReps,
  stableHoldFaded,
  stableHoldHighRpe,
  dropBailout,
  heavyProbeFailed,
  heavyProbeEarned,
  mixed,
  noWeight,
}

class _Assessment {
  const _Assessment({
    required this.pattern,
    required this.workingWeight,
    required this.peakWeight,
    required this.minWeight,
    required this.targetReps,
    this.probeWeight,
    this.probeReps,
    this.effortRpe,
  });

  final _Pattern pattern;
  final double workingWeight;
  final double peakWeight;
  final double minWeight;
  final int? targetReps;
  final double? probeWeight;
  final int? probeReps;

  /// Representative intensity for this exercise (max logged RPE).
  final int? effortRpe;
}

/// Builds short Persian coach copy from logged sets — no LLM, no session stop advice.
///
/// Coaching model:
/// - Double progression on reps/weight for the working load.
/// - RPE (شدت) autoregulates whether to add weight after hitting reps:
///   ≤7 → room to progress; 8 → productive hard set, hold; ≥9 → hold firmly.
/// - Never claim "missed reps" when reps were complete but RPE was high.
abstract final class WorkoutExerciseCoachFeedbackEngine {
  /// RPE ≤ this can progress after completing all target reps.
  static const int _progressRpeMax = 7;

  /// RPE at/above this is a hard but successful set → hold load.
  static const int _hardRpeMin = 8;

  static WorkoutExerciseCoachFeedback? build({
    required List<LoggedSetPerformance> sets,
    required bool isTimedStyle,
    String? formTipSource,
  }) {
    if (sets.isEmpty) return null;

    final analysis = isTimedStyle ? _timedAnalysis(sets) : _repsAnalysis(sets);
    final nextSession = isTimedStyle
        ? _timedNextSession(sets)
        : _repsNextSession(sets);
    final formTip = _formTip(formTipSource);

    final feedback = WorkoutExerciseCoachFeedback(
      analysis: analysis,
      nextSession: nextSession,
      formTip: formTip,
    );
    return feedback.isEmpty ? null : feedback;
  }

  static WorkoutExerciseCoachFeedback? fromControllers({
    required List<ExerciseSet> prescription,
    required List<Map<String, String>> setValues,
    required List<bool> savedStatus,
    required ExerciseStyle style,
    String? formTipSource,
  }) {
    if (prescription.isEmpty || setValues.isEmpty) return null;
    if (savedStatus.length < prescription.length) return null;
    if (!savedStatus.take(prescription.length).every((saved) => saved)) {
      return null;
    }

    final sets = <LoggedSetPerformance>[];
    for (var i = 0; i < prescription.length && i < setValues.length; i++) {
      final values = setValues[i];
      final weight = double.tryParse(values['weight'] ?? '') ?? 0;
      final reps = int.tryParse(values['reps'] ?? '') ?? 0;
      final seconds = int.tryParse(values['time'] ?? '') ?? 0;
      final rpe = int.tryParse(values['rpe'] ?? '');
      final target = prescription[i];

      final hasData = style == ExerciseStyle.setsTime
          ? seconds > 0 || weight > 0
          : reps > 0 || weight > 0;
      if (!hasData) return null;

      sets.add(
        LoggedSetPerformance(
          targetReps: target.reps,
          targetWeightKg: target.weight,
          actualReps: reps,
          actualWeightKg: weight,
          actualSeconds: seconds > 0 ? seconds : null,
          targetSeconds: target.timeSeconds,
          rpe: rpe,
        ),
      );
    }

    return build(
      sets: sets,
      isTimedStyle: style == ExerciseStyle.setsTime,
      formTipSource: formTipSource,
    );
  }

  static String? _repsAnalysis(List<LoggedSetPerformance> sets) {
    final a = _assess(sets);

    switch (a.pattern) {
      case _Pattern.heavyProbeFailed:
        return 'ست‌های ${_formatWeight(a.workingWeight)} کیلو را کامل زدی، '
            'ولی ${_formatWeight(a.probeWeight!)} کیلو فقط '
            '${a.probeReps} تکرار شد؛ '
            'یعنی ${_formatWeight(a.probeWeight!)} هنوز برای ست‌های کامل سنگینه.';
      case _Pattern.heavyProbeEarned:
        return 'به ${_formatWeight(a.peakWeight)} کیلو رسیدی و تکرار هدف را زدی؛ '
            'ولی فقط در یک ست. پایهٔ پایدار هنوز '
            '${_formatWeight(a.workingWeight)} کیلو است.';
      case _Pattern.dropBailout:
        return 'روی ${_formatWeight(a.workingWeight)} کیلو خوب پیش رفتی، '
            'ولی ست آخر سبک‌تر شد؛ به سقف همون وزنه نزدیک شدی.';
      case _Pattern.mixed:
        return 'وزنه‌ها یکدست نبود '
            '(${_formatWeight(a.minWeight)} تا ${_formatWeight(a.peakWeight)}). '
            'با این پراکندگی نمی‌شه پایهٔ درستی برای پیشرفت گذاشت.';
      case _Pattern.stableReady:
        final effort = a.effortRpe;
        if (effort != null && effort <= _progressRpeMax) {
          return 'هر ${sets.length} ست را با ${_formatWeight(a.workingWeight)} کیلو '
              'کامل زدی و شدت حدود $effort بود؛ جا برای پیشرفت داری.';
        }
        return 'هر ${sets.length} ست را با ${_formatWeight(a.workingWeight)} کیلو '
            'و تکرار کامل زدی؛ وزنه برای این جلسه مناسب بوده.';
      case _Pattern.stableHoldHighRpe:
        final rpe = a.effortRpe ?? _hardRpeMin;
        if (rpe >= 9) {
          return 'تکرارها کامل بود، ولی شدت $rpe خیلی بالا بود؛ '
              'یعنی ${_formatWeight(a.workingWeight)} کیلو نزدیک حداکثرت است.';
        }
        return 'هر ${sets.length} ست را با ${_formatWeight(a.workingWeight)} کیلو کامل زدی، '
            'ولی شدت حدود $rpe بود (حدود ۱–۲ تکرار در ذخیره)؛ '
            'برای این جلسه وزنه درست بوده، هنوز برای افزایش زود است.';
      case _Pattern.stableHoldFaded:
        return 'وزنه ${_formatWeight(a.workingWeight)} ثابت بود، '
            'ولی تکرارها در ست‌های آخر افت کرد؛ نزدیک سقف این وزنه‌ای.';
      case _Pattern.stableHoldMissedReps:
        return 'تکرارها کمتر از هدف بود؛ '
            '${_formatWeight(a.workingWeight)} کیلو را فعلاً نگه دار.';
      case _Pattern.noWeight:
        return 'ست‌ها ثبت شد؛ برای این حرکت پایهٔ خوبی داری.';
    }
  }

  static String? _repsNextSession(List<LoggedSetPerformance> sets) {
    final a = _assess(sets);

    switch (a.pattern) {
      case _Pattern.heavyProbeFailed:
        return 'جلسه بعد هر ${sets.length} ست را با '
            '${_formatWeight(a.workingWeight)} کیلو بزن. '
            'تا وقتی همه ست‌ها با همین وزنه کامل نشد، '
            'از ${_formatWeight(a.probeWeight!)} شروع نکن.';
      case _Pattern.heavyProbeEarned:
        final bridge = _bridgeWeight(a.workingWeight, a.peakWeight);
        return 'جلسه بعد از ${_formatWeight(a.peakWeight)} برای همه ست‌ها شروع نکن. '
            'دو ست اول ${_formatWeight(bridge)} و ست آخر '
            '${_formatWeight(a.peakWeight)} منطقی‌تره.';
      case _Pattern.dropBailout:
        return 'جلسه بعد همه ست‌ها را با ${_formatWeight(a.workingWeight)} کیلو بزن. '
            'تا ست آخر هم کامل نشد، وزنه را زیاد نکن.';
      case _Pattern.mixed:
        return 'جلسه بعد روی ${_formatWeight(a.workingWeight)} کیلو ثابت بمان '
            'تا ببینیم با وزنه یکدست چند تکرار می‌زنی.';
      case _Pattern.stableReady:
        final next = a.workingWeight + _incrementFor(a.workingWeight);
        return 'جلسه بعد ${_formatWeight(next)} کیلو را امتحان کن '
            'و ببین همه ست‌ها را با فرم درست کامل می‌کنی.';
      case _Pattern.stableHoldHighRpe:
        return 'جلسه بعد همین ${_formatWeight(a.workingWeight)} کیلو را نگه دار. '
            'وقتی همه ست‌ها با شدت ۶–۷ کامل شد، بعد وزنه را زیاد کن.';
      case _Pattern.stableHoldFaded:
      case _Pattern.stableHoldMissedReps:
        return 'جلسه بعد همین ${_formatWeight(a.workingWeight)} کیلو را نگه دار '
            'تا تکرارها در همه ست‌ها پایدار بماند.';
      case _Pattern.noWeight:
        if (_allHitTargets(sets) &&
            _effortAllowsProgress(sets) &&
            !_repsFaded(sets)) {
          return 'جلسه بعد یک تکرار بیشتر روی آخرین ست امتحان کن.';
        }
        return 'جلسه بعد همین تکرارها را با فرم تمیز تکرار کن.';
    }
  }

  static _Assessment _assess(List<LoggedSetPerformance> sets) {
    final weighted = sets.where((s) => s.hasWeight).toList();
    final targetReps = _primaryTargetReps(sets);
    final effort = _effortRpe(sets);

    if (weighted.isEmpty) {
      return _Assessment(
        pattern: _Pattern.noWeight,
        workingWeight: 0,
        peakWeight: 0,
        minWeight: 0,
        targetReps: targetReps,
        effortRpe: effort,
      );
    }

    final peak = weighted.map((s) => s.actualWeightKg).reduce(math.max);
    final minW = weighted.map((s) => s.actualWeightKg).reduce(math.min);
    final working = _computeWorkingWeight(weighted, targetReps);
    final weights = weighted.map((s) => s.actualWeightKg).toList();
    final loadSpread = peak - minW;
    final meaningfulSpread =
        loadSpread >= 2.5 || (peak > 0 && loadSpread / peak >= 0.12);

    final probe = _findProbe(weighted, working);
    if (probe != null) {
      final refReps = _referenceRepsAtWorking(weighted, working);
      final probeOk = _probeSucceeded(probe, targetReps, refReps);
      if (!probeOk) {
        return _Assessment(
          pattern: _Pattern.heavyProbeFailed,
          workingWeight: working,
          peakWeight: peak,
          minWeight: minW,
          targetReps: targetReps,
          probeWeight: probe.actualWeightKg,
          probeReps: probe.actualReps,
          effortRpe: effort,
        );
      }
      if (probe.actualWeightKg > working + 0.5) {
        return _Assessment(
          pattern: _Pattern.heavyProbeEarned,
          workingWeight: working,
          peakWeight: peak,
          minWeight: minW,
          targetReps: targetReps,
          probeWeight: probe.actualWeightKg,
          probeReps: probe.actualReps,
          effortRpe: effort,
        );
      }
    }

    if (meaningfulSpread) {
      if (_allQuality(weighted, targetReps) && _isMonotonicUp(weights)) {
        return _Assessment(
          pattern: _stableOutcome(sets, workingWeight: peak),
          workingWeight: peak,
          peakWeight: peak,
          minWeight: minW,
          targetReps: targetReps,
          effortRpe: effort,
        );
      }

      final last = weighted.last;
      final earlier = weighted.sublist(0, weighted.length - 1);
      final earlierPeak = earlier.isEmpty
          ? last.actualWeightKg
          : earlier.map((s) => s.actualWeightKg).reduce(math.max);

      if (last.actualWeightKg <= earlierPeak - 2.5 &&
          (earlierPeak - last.actualWeightKg) / earlierPeak >= 0.12) {
        return _Assessment(
          pattern: _Pattern.dropBailout,
          workingWeight: working,
          peakWeight: peak,
          minWeight: minW,
          targetReps: targetReps,
          effortRpe: effort,
        );
      }

      return _Assessment(
        pattern: _Pattern.mixed,
        workingWeight: working,
        peakWeight: peak,
        minWeight: minW,
        targetReps: targetReps,
        effortRpe: effort,
      );
    }

    return _Assessment(
      pattern: _stableOutcome(sets, workingWeight: working),
      workingWeight: working,
      peakWeight: peak,
      minWeight: minW,
      targetReps: targetReps,
      effortRpe: effort,
    );
  }

  /// Decide ready vs hold — and *why* we hold (reps vs RPE).
  static _Pattern _stableOutcome(
    List<LoggedSetPerformance> sets, {
    required double workingWeight,
  }) {
    if (workingWeight <= 0) return _Pattern.stableHoldMissedReps;

    final hit = _allHitTargets(sets);
    final faded = _repsFaded(sets);

    if (!hit) {
      // Prefer fade copy when later sets drop after a strong first set.
      if (faded) return _Pattern.stableHoldFaded;
      return _Pattern.stableHoldMissedReps;
    }
    if (faded) return _Pattern.stableHoldFaded;
    if (!_effortAllowsProgress(sets)) return _Pattern.stableHoldHighRpe;
    return _Pattern.stableReady;
  }

  /// Max logged RPE for the exercise (شدت).
  static int? _effortRpe(List<LoggedSetPerformance> sets) {
    final rpes = sets.map((s) => s.rpe).whereType<int>().where((r) => r > 0);
    if (rpes.isEmpty) return null;
    return rpes.reduce(math.max);
  }

  /// No RPE → reps-only progression. With RPE → only progress at ≤7.
  static bool _effortAllowsProgress(List<LoggedSetPerformance> sets) {
    final effort = _effortRpe(sets);
    if (effort == null) return true;
    return effort <= _progressRpeMax;
  }

  static double _computeWorkingWeight(
    List<LoggedSetPerformance> weighted,
    int? targetReps,
  ) {
    final sustainable = _sustainableSets(weighted, targetReps);
    if (sustainable.isNotEmpty) {
      return _modalWeight(
        sustainable.map((s) => s.actualWeightKg).toList(),
      );
    }
    final sorted = weighted.map((s) => s.actualWeightKg).toList()..sort();
    return sorted[sorted.length ~/ 2];
  }

  static List<LoggedSetPerformance> _sustainableSets(
    List<LoggedSetPerformance> weighted,
    int? targetReps,
  ) {
    if (targetReps != null && targetReps > 0) {
      final hit =
          weighted.where((s) => s.actualReps >= targetReps).toList();
      if (hit.isNotEmpty) return hit;
    }

    if (weighted.length < 2) return weighted;

    final sortedWeights = weighted.map((s) => s.actualWeightKg).toList()
      ..sort();
    final median = sortedWeights[sortedWeights.length ~/ 2];
    final bestReps = weighted.map((s) => s.actualReps).reduce(math.max);

    final kept = weighted.where((s) {
      final muchHeavier = s.actualWeightKg >= median + 2.5;
      final fewerReps =
          s.actualReps <= bestReps - 2 || s.actualReps < bestReps * 0.85;
      if (muchHeavier && fewerReps) return false;
      return true;
    }).toList();

    return kept.isNotEmpty ? kept : weighted;
  }

  static LoggedSetPerformance? _findProbe(
    List<LoggedSetPerformance> weighted,
    double workingWeight,
  ) {
    LoggedSetPerformance? best;
    for (final set in weighted) {
      final heavier =
          set.actualWeightKg >= workingWeight + 2.5 &&
          (workingWeight <= 0 ||
              (set.actualWeightKg - workingWeight) / workingWeight >= 0.1);
      if (!heavier) continue;
      if (best == null || set.actualWeightKg > best.actualWeightKg) {
        best = set;
      }
    }
    return best;
  }

  static int _referenceRepsAtWorking(
    List<LoggedSetPerformance> weighted,
    double workingWeight,
  ) {
    final atWorking = weighted.where(
      (s) => (s.actualWeightKg - workingWeight).abs() < 0.51,
    );
    if (atWorking.isEmpty) {
      return weighted.map((s) => s.actualReps).reduce(math.max);
    }
    return atWorking.map((s) => s.actualReps).reduce(math.max);
  }

  static bool _probeSucceeded(
    LoggedSetPerformance probe,
    int? targetReps,
    int referenceReps,
  ) {
    if (targetReps != null && targetReps > 0) {
      return probe.actualReps >= targetReps;
    }
    return probe.actualReps >= referenceReps - 1 &&
        probe.actualReps >= (referenceReps * 0.85);
  }

  static bool _allQuality(
    List<LoggedSetPerformance> weighted,
    int? targetReps,
  ) {
    if (targetReps != null && targetReps > 0) {
      return weighted.every((s) => s.actualReps >= targetReps);
    }
    if (weighted.length < 2) return true;
    final best = weighted.map((s) => s.actualReps).reduce(math.max);
    return weighted.every(
      (s) => s.actualReps >= best - 1 || s.actualReps >= best * 0.85,
    );
  }

  static int? _primaryTargetReps(List<LoggedSetPerformance> sets) {
    for (final set in sets) {
      final t = set.targetReps;
      if (t != null && t > 0) return t;
    }
    return null;
  }

  static bool _allHitTargets(List<LoggedSetPerformance> sets) {
    final withTargets = sets.where((s) => (s.targetReps ?? 0) > 0).toList();
    if (withTargets.isEmpty) {
      return !_repsFaded(sets);
    }
    return withTargets.every((s) => s.actualReps >= s.targetReps!);
  }

  static double _modalWeight(List<double> weights) {
    final counts = <double, int>{};
    for (final w in weights) {
      counts[w] = (counts[w] ?? 0) + 1;
    }
    var bestWeight = weights.first;
    var bestCount = 0;
    counts.forEach((weight, count) {
      if (count > bestCount || (count == bestCount && weight > bestWeight)) {
        bestCount = count;
        bestWeight = weight;
      }
    });
    return bestWeight;
  }

  static double _bridgeWeight(double working, double peak) {
    if (peak <= working) return working;
    final raw = working + (peak - working) / 2;
    final step = _incrementFor(working);
    final stepped = (raw / step).round() * step;
    if (stepped <= working) return working + step;
    if (stepped >= peak) {
      return peak - step > working ? peak - step : working;
    }
    return stepped;
  }

  static bool _isMonotonicUp(List<double> values) {
    for (var i = 1; i < values.length; i++) {
      if (values[i] + 0.01 < values[i - 1]) return false;
    }
    return values.last > values.first + 0.01;
  }

  static String? _timedAnalysis(List<LoggedSetPerformance> sets) {
    final withTargets = sets.where(
      (s) => (s.targetSeconds ?? 0) > 0 && s.hasTimedPerformance,
    );
    if (withTargets.isEmpty) {
      return 'ست‌های زمانی ثبت شد.';
    }
    final allHit = withTargets.every(
      (s) => (s.actualSeconds ?? 0) >= s.targetSeconds!,
    );
    if (!allHit) {
      return 'بعضی ست‌ها کوتاه‌تر از هدف بود؛ روی کنترل حرکت تمرکز کن.';
    }
    final effort = _effortRpe(sets);
    if (effort != null && effort >= _hardRpeMin) {
      return 'مدت هدف را زدی، ولی شدت $effort بالا بود؛ همین زمان را نگه دار.';
    }
    return 'مدت هدف را در ست‌ها زدی؛ اجرای تمیزی بوده.';
  }

  static String? _timedNextSession(List<LoggedSetPerformance> sets) {
    final withTargets = sets.where(
      (s) => (s.targetSeconds ?? 0) > 0 && s.hasTimedPerformance,
    );
    if (withTargets.isEmpty) return null;
    final allHit = withTargets.every(
      (s) => (s.actualSeconds ?? 0) >= s.targetSeconds!,
    );
    if (allHit && _effortAllowsProgress(sets) && !_repsFaded(sets)) {
      return 'جلسه بعد ۵ تا ۱۰ ثانیه به ست آخر اضافه کن.';
    }
    return 'جلسه بعد همان زمان هدف را با فرم تمیز تکرار کن.';
  }

  static String? _formTip(String? source) {
    final tip = _firstTipSentence(source);
    if (tip == null) return null;
    return 'نکته فرم: $tip';
  }

  static String? _firstTipSentence(String? source) {
    if (source == null) return null;
    var text = source.trim();
    if (text.isEmpty) return null;
    text = text
        .replaceAll(RegExp(r'^[\-•\*]\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return null;
    if (text.length > 110) {
      final cut = text.substring(0, 110);
      final lastSpace = cut.lastIndexOf(' ');
      text = '${(lastSpace > 60 ? cut.substring(0, lastSpace) : cut).trim()}…';
    }
    return text;
  }

  static bool _repsFaded(List<LoggedSetPerformance> sets) {
    final scored = sets.where((s) => s.actualReps > 0).toList();
    if (scored.length < 2) return false;
    final first = scored.first.actualReps;
    final last = scored.last.actualReps;
    return last <= first - 2 || last < first * 0.8;
  }

  static double _incrementFor(double weight) {
    if (weight <= 0) return 2.5;
    final isFiveKgStep = ((weight * 2).round() % 10) == 0;
    if (weight >= 20 && isFiveKgStep) return 5;
    if (weight >= 40) return 5;
    return 2.5;
  }

  static String _formatWeight(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  static String? resolveFormTipSource({
    List<String> tips = const <String>[],
    String? programNote,
  }) {
    for (final tip in tips) {
      final cleaned = tip.trim();
      if (cleaned.isNotEmpty) return cleaned;
    }
    final note = programNote?.trim();
    if (note != null && note.isNotEmpty && note.length <= 140) {
      return note;
    }
    return null;
  }
}
