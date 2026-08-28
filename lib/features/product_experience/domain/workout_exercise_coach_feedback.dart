import 'dart:math' as math;

import 'package:gymaipro/features/product_experience/domain/exercise_coach_decision.dart';
import 'package:gymaipro/workout_log/models/previous_exercise_performance.dart';
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
    this.assisted = false,
  });

  final int? targetReps;
  final double? targetWeightKg;
  final int actualReps;
  final double actualWeightKg;
  final int? actualSeconds;
  final int? targetSeconds;

  /// Perceived effort 1–10 (app label: شدت / RPE).
  final int? rpe;

  /// Spotter-assisted reps — never count as an independent PR.
  final bool assisted;

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
    this.decision,
  });

  final String? analysis;
  final String? nextSession;
  final String? formTip;

  /// Structured decision for Decision Card + LLM lock context.
  final ExerciseDecision? decision;

  bool get isEmpty =>
      (analysis == null || analysis!.isEmpty) &&
      (nextSession == null || nextSession!.isEmpty) &&
      (formTip == null || formTip!.isEmpty) &&
      decision == null;

  List<String> get lines {
    return <String>[
      if (decision?.previousComparison != null &&
          decision!.previousComparison!.isNotEmpty)
        decision!.previousComparison!,
      if (analysis != null && analysis!.isNotEmpty) analysis!,
      if (nextSession != null && nextSession!.isNotEmpty) nextSession!,
      if (formTip != null && formTip!.isNotEmpty) formTip!,
    ];
  }
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
    this.prescribedSetCount,
  });

  final ExerciseCoachPattern pattern;
  final double workingWeight;
  final double peakWeight;
  final double minWeight;
  final int? targetReps;
  final double? probeWeight;
  final int? probeReps;

  /// Representative intensity for this exercise (max logged RPE).
  final int? effortRpe;
  final int? prescribedSetCount;

  _Assessment withPrescription(int? n) {
    return _Assessment(
      pattern: pattern,
      workingWeight: workingWeight,
      peakWeight: peakWeight,
      minWeight: minWeight,
      targetReps: targetReps,
      probeWeight: probeWeight,
      probeReps: probeReps,
      effortRpe: effortRpe,
      prescribedSetCount: n,
    );
  }
}

class _LiftCompare {
  const _LiftCompare({
    required this.summary,
    required this.alreadyJumpedLoad,
    this.repeatedSameLoads = false,
  });

  final String summary;
  final bool alreadyJumpedLoad;
  final bool repeatedSameLoads;
}

class _SetDelta {
  const _SetDelta({
    required this.index,
    required this.weightDelta,
    required this.repsDelta,
  });

  final int index;
  final double weightDelta;
  final int repsDelta;
}

/// Builds short Persian coach copy from logged sets — no LLM, no session stop advice.
///
/// Coaching model:
/// - Completing the prescribed sets/reps IS a successful session.
/// - Double progression: add weight only after the same working load was
///   already logged complete in a previous session, RPE ≤7, all sets done.
/// - First log of an exercise: consolidate the load, do not bump.
/// - Missed/faded reps: stay on the weight and chase reps, not kilos.
/// - RPE 8+ with full reps: hold. Never call that "missed reps".
/// - Incomplete volume: never increase.
abstract final class WorkoutExerciseCoachFeedbackEngine {
  /// RPE ≤ this can progress after completing all target reps.
  static const int _progressRpeMax = 7;

  /// RPE at/above this is a hard but successful set → hold load.
  static const int _hardRpeMin = 8;

  static WorkoutExerciseCoachFeedback? build({
    required List<LoggedSetPerformance> sets,
    required bool isTimedStyle,
    String? formTipSource,
    List<PreviousExerciseSet>? previousSets,
    int? prescribedSetCount,
  }) {
    if (sets.isEmpty) return null;

    // Assisted last-rep sets are logged for honesty but capped for progression.
    final scored = sets
        .map(
          (s) => s.assisted
              ? LoggedSetPerformance(
                  actualReps: math.max(0, s.actualReps - 1),
                  actualWeightKg: s.actualWeightKg,
                  targetReps: s.targetReps,
                  targetWeightKg: s.targetWeightKg,
                  actualSeconds: s.actualSeconds,
                  targetSeconds: s.targetSeconds,
                  rpe: s.rpe,
                  assisted: true,
                )
              : s,
        )
        .toList(growable: false);

    final assessment = isTimedStyle
        ? null
        : _assess(scored, prescribedSetCount: prescribedSetCount);
    final compare = _compareWithPrevious(scored, previousSets);
    final analysis = isTimedStyle
        ? _timedAnalysis(scored, prescribedSetCount: prescribedSetCount)
        : _repsAnalysis(scored, assessment!, compare);
    final nextSession = isTimedStyle
        ? _timedNextSession(
            scored,
            prescribedSetCount: prescribedSetCount,
            previousSets: previousSets,
          )
        : _repsNextSession(scored, assessment!, compare);
    final formTip = _formTip(formTipSource);
    final decision = isTimedStyle
        ? _timedDecision(
            scored,
            previousSets: previousSets,
            prescribedSetCount: prescribedSetCount,
          )
        : _repsDecision(scored, assessment!, compare);

    final feedback = WorkoutExerciseCoachFeedback(
      analysis: analysis,
      nextSession: nextSession,
      formTip: formTip,
      decision: decision,
    );
    return feedback.isEmpty ? null : feedback;
  }

  static WorkoutExerciseCoachFeedback? fromControllers({
    required List<ExerciseSet> prescription,
    required List<Map<String, String>> setValues,
    required List<bool> savedStatus,
    required ExerciseStyle style,
    String? formTipSource,
    List<PreviousExerciseSet>? previousSets,
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
      final assisted = _parseAssisted(values['assisted']);
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
          assisted: assisted,
        ),
      );
    }

    return build(
      sets: sets,
      isTimedStyle: style == ExerciseStyle.setsTime,
      formTipSource: formTipSource,
      previousSets: previousSets,
      prescribedSetCount: prescription.length,
    );
  }

  static bool _parseAssisted(String? raw) {
    if (raw == null) return false;
    final v = raw.trim().toLowerCase();
    return v == '1' || v == 'true' || v == 'yes' || v == 'assisted';
  }

  static ExerciseCoachPattern _effectivePattern(
    _Assessment a,
    _LiftCompare? compare,
  ) {
    if (a.pattern == ExerciseCoachPattern.stableReady && compare == null) {
      return ExerciseCoachPattern.stableHoldFirstSession;
    }
    return a.pattern;
  }

  static String? _repsAnalysis(
    List<LoggedSetPerformance> sets,
    _Assessment a,
    _LiftCompare? compare,
  ) {
    final pattern = _effectivePattern(a, compare);
    if (compare != null &&
        pattern == ExerciseCoachPattern.stableReady &&
        compare.alreadyJumpedLoad) {
      return 'امروز نسبت به قبل وزنه اومد بالا و ست‌ها کامل شد. '
          'همین وزنه جدید رو یک جلسه تثبیت کن؛ پشت‌سرهم زیادش نکن.';
    }

    switch (pattern) {
      case ExerciseCoachPattern.heavyProbeFailed:
        return 'ست‌های ${_formatWeight(a.workingWeight)} کیلو را کامل زدی، '
            'ولی ${_formatWeight(a.probeWeight!)} کیلو فقط '
            '${a.probeReps} تکرار شد؛ '
            'یعنی ${_formatWeight(a.probeWeight!)} هنوز برای همه ست‌ها سنگینه.';
      case ExerciseCoachPattern.heavyProbeEarned:
        final probeSet = _heavierSetIndex(sets, a.workingWeight);
        final setHint = probeSet == null ? 'ست آخر' : 'ست ${_faInt(probeSet)}';
        if (compare != null && compare.repeatedSameLoads) {
          return 'ست آخر دوباره ${_formatWeight(a.peakWeight)} کیلو و کامل شد. '
              'پایه هنوز ${_formatWeight(a.workingWeight)} است — '
              'یعنی ${_formatWeight(a.peakWeight)} مال همه ست‌ها نیست.';
        }
        return 'پایه ${_formatWeight(a.workingWeight)} کیلو کامل شد. '
            '$setHint رفت ${_formatWeight(a.peakWeight)} و '
            '${a.probeReps ?? 0} تکرار زد — این سنگین‌ترین ست امروز بود. '
            'ولی ${_formatWeight(a.peakWeight)} هنوز پایهٔ هر سه ست نیست.';
      case ExerciseCoachPattern.dropBailout:
        return 'روی ${_formatWeight(a.workingWeight)} کیلو خوب پیش رفتی، '
            'ولی ست آخر سبک‌تر شد؛ به سقف همون وزنه نزدیک شدی.';
      case ExerciseCoachPattern.mixed:
        return 'وزنه‌ها یکدست نبود '
            '(${_formatWeight(a.minWeight)} تا ${_formatWeight(a.peakWeight)}). '
            'با این پراکندگی نمی‌شه پایهٔ درستی برای پیشرفت گذاشت.';
      case ExerciseCoachPattern.stableHoldFirstSession:
        return 'هر ${sets.length} ست را با ${_formatWeight(a.workingWeight)} کیلو '
            'کامل زدی. برای اولین ثبت، همین وزنه موفقیت است — '
            'لازم نیست همین حالا سنگین‌ترش کنی.';
      case ExerciseCoachPattern.stableReady:
        final effort = a.effortRpe;
        if (effort != null && effort <= _progressRpeMax) {
          return 'دوباره هر ${sets.length} ست را با ${_formatWeight(a.workingWeight)} کیلو '
              'کامل زدی و شدت حدود $effort بود؛ این وزنه جا افتاده.';
        }
        return 'دوباره هر ${sets.length} ست را با ${_formatWeight(a.workingWeight)} کیلو '
            'و تکرار کامل زدی؛ وزنه تثبیت شده.';
      case ExerciseCoachPattern.stableHoldHighRpe:
        final rpe = a.effortRpe ?? _hardRpeMin;
        if (rpe >= 9) {
          return 'تکرارها کامل بود، ولی شدت $rpe خیلی بالا بود؛ '
              'یعنی ${_formatWeight(a.workingWeight)} کیلو نزدیک حداکثرت است.';
        }
        return 'هر ${sets.length} ست را با ${_formatWeight(a.workingWeight)} کیلو کامل زدی، '
            'ولی شدت حدود $rpe بود (حدود ۱–۲ تکرار در ذخیره)؛ '
            'برای این جلسه وزنه درست بوده، هنوز برای افزایش زود است.';
      case ExerciseCoachPattern.stableHoldFaded:
        return 'وزنه ${_formatWeight(a.workingWeight)} ثابت بود، '
            'ولی تکرارها در ست‌های آخر افت کرد؛ نزدیک سقف این وزنه‌ای.';
      case ExerciseCoachPattern.stableHoldMissedReps:
        final target = a.targetReps;
        if (target != null && target > 0) {
          return 'تکرارها به $target نرسید. '
              'پیشرفت این حرکت فعلاً با کامل کردن تکرار است، نه با وزنه بیشتر.';
        }
        return 'تکرارها کمتر از هدف بود؛ '
            '${_formatWeight(a.workingWeight)} کیلو را فعلاً نگه دار.';
      case ExerciseCoachPattern.noWeight:
        return 'ست‌ها ثبت شد؛ برای این حرکت پایهٔ خوبی داری.';
      case ExerciseCoachPattern.incompleteVolume:
        return _incompleteAnalysis(sets, a);
      case ExerciseCoachPattern.timedReady:
      case ExerciseCoachPattern.timedHold:
        return null;
    }
  }

  static String? _repsNextSession(
    List<LoggedSetPerformance> sets,
    _Assessment a,
    _LiftCompare? compare,
  ) {
    final pattern = _effectivePattern(a, compare);
    if (compare != null &&
        pattern == ExerciseCoachPattern.stableReady &&
        compare.alreadyJumpedLoad) {
      return 'جلسه بعد هر ${sets.length} ست را با '
          '${_formatWeight(a.workingWeight)} کیلو بزن. '
          'وقتی این وزنه برای همه ست‌ها راحت شد، بعد زیادش کن.';
    }

    switch (pattern) {
      case ExerciseCoachPattern.heavyProbeFailed:
        return 'جلسه بعد هر ${sets.length} ست را با '
            '${_formatWeight(a.workingWeight)} کیلو بزن. '
            'تا وقتی همه ست‌ها با همین وزنه کامل نشد، '
            'از ${_formatWeight(a.probeWeight!)} شروع نکن.';
      case ExerciseCoachPattern.heavyProbeEarned:
        final bridge = _bridgeWeight(a.workingWeight, a.peakWeight);
        if (bridge <= a.workingWeight + 0.01) {
          return 'جلسه بعد همه ست‌ها را ${_formatWeight(a.peakWeight)} نکن. '
              'دوباره دو ست ${_formatWeight(a.workingWeight)} و ست آخر '
              '${_formatWeight(a.peakWeight)}. '
              'وقتی ${_formatWeight(a.peakWeight)} روی دو ست نشست، بعد می‌شود پایه‌اش کرد.';
        }
        return 'جلسه بعد ست‌های اول را ${_formatWeight(bridge)} بزن، '
            'ست آخر ${_formatWeight(a.peakWeight)}. '
            'از ${_formatWeight(a.peakWeight)} برای همه ست‌ها شروع نکن.';
      case ExerciseCoachPattern.dropBailout:
        return 'جلسه بعد همه ست‌ها را با ${_formatWeight(a.workingWeight)} کیلو بزن. '
            'تا ست آخر هم کامل نشد، وزنه را زیاد نکن.';
      case ExerciseCoachPattern.mixed:
        return 'جلسه بعد روی ${_formatWeight(a.workingWeight)} کیلو ثابت بمان '
            'تا ببینیم با وزنه یکدست چند تکرار می‌زنی.';
      case ExerciseCoachPattern.stableHoldFirstSession:
        return 'جلسه بعد دوباره هر ${sets.length} ست را با '
            '${_formatWeight(a.workingWeight)} کیلو بزن. '
            'اگر باز کامل شد، آن‌وقت یک پله وزنه را زیاد می‌کنیم.';
      case ExerciseCoachPattern.stableReady:
        final next = a.workingWeight + _incrementFor(a.workingWeight);
        return 'جلسه بعد ${_formatWeight(next)} کیلو را امتحان کن '
            'و ببین همه ست‌ها را با فرم درست کامل می‌کنی.';
      case ExerciseCoachPattern.stableHoldHighRpe:
        return 'جلسه بعد همین ${_formatWeight(a.workingWeight)} کیلو را نگه دار. '
            'وقتی همه ست‌ها با شدت ۶–۷ کامل شد، بعد وزنه را زیاد کن.';
      case ExerciseCoachPattern.stableHoldFaded:
        final fadeTarget = a.targetReps;
        if (fadeTarget != null && fadeTarget > 0) {
          return 'جلسه بعد همین ${_formatWeight(a.workingWeight)} کیلو را نگه دار '
              'و ست آخر را هم به $fadeTarget برسان. وزنه را زیاد نکن.';
        }
        return 'جلسه بعد همین ${_formatWeight(a.workingWeight)} کیلو را نگه دار '
            'تا تکرارها در همه ست‌ها پایدار بماند.';
      case ExerciseCoachPattern.stableHoldMissedReps:
        final missTarget = a.targetReps;
        if (missTarget != null && missTarget > 0) {
          return 'جلسه بعد همین ${_formatWeight(a.workingWeight)} کیلو را بزن '
              'و سعی کن به $missTarget تکرار برسی. وزنه را زیاد نکن.';
        }
        return 'جلسه بعد همین ${_formatWeight(a.workingWeight)} کیلو را نگه دار '
            'تا تکرارها در همه ست‌ها پایدار بماند.';
      case ExerciseCoachPattern.noWeight:
        if (_allHitTargets(sets) &&
            _effortAllowsProgress(sets) &&
            !_repsFaded(sets) &&
            compare != null) {
          return 'جلسه بعد یک تکرار بیشتر روی آخرین ست امتحان کن.';
        }
        return 'جلسه بعد همین تکرارها را با فرم تمیز تکرار کن.';
      case ExerciseCoachPattern.incompleteVolume:
        return _incompleteNextSession(sets, a);
      case ExerciseCoachPattern.timedReady:
      case ExerciseCoachPattern.timedHold:
        return null;
    }
  }

  static ExerciseDecision _repsDecision(
    List<LoggedSetPerformance> sets,
    _Assessment a,
    _LiftCompare? compare,
  ) {
    final pattern = _effectivePattern(a, compare);
    final comparison = compare?.summary;
    final assistedNote = sets.any((s) => s.assisted)
        ? 'تکرار کمکی در رکورد مستقل حساب نشد.'
        : null;
    final note = comparison ?? assistedNote;

    if (pattern == ExerciseCoachPattern.incompleteVolume) {
      return ExerciseDecision(
        pattern: a.pattern,
        action: ExerciseCoachAction.hold,
        actionLabel: 'اول همه ست‌ها را کامل کن',
        workingWeightKg: a.workingWeight > 0 ? a.workingWeight : null,
        nextWeightKg: a.workingWeight > 0 ? a.workingWeight : null,
        targetReps: a.targetReps,
        effortRpe: a.effortRpe,
        previousComparison: note,
        setCount: sets.length,
        prescribedSetCount: a.prescribedSetCount,
      );
    }

    ExerciseDecision finish(ExerciseDecision d) {
      return d.copyWith(prescribedSetCount: a.prescribedSetCount);
    }

    if (pattern == ExerciseCoachPattern.stableReady &&
        compare != null &&
        compare.alreadyJumpedLoad) {
      return finish(
        ExerciseDecision(
          pattern: a.pattern,
          action: ExerciseCoachAction.hold,
          actionLabel: 'وزنه جدید رو تثبیت کن',
          workingWeightKg: a.workingWeight,
          nextWeightKg: a.workingWeight,
          targetReps: a.targetReps,
          effortRpe: a.effortRpe,
          previousComparison: note,
          setCount: sets.length,
        ),
      );
    }

    switch (pattern) {
      case ExerciseCoachPattern.stableHoldFirstSession:
        return finish(
          ExerciseDecision(
            pattern: pattern,
            action: ExerciseCoachAction.hold,
            actionLabel: 'وزنه‌ت را تثبیت کن',
            workingWeightKg: a.workingWeight,
            nextWeightKg: a.workingWeight,
            targetReps: a.targetReps,
            effortRpe: a.effortRpe,
            previousComparison: note,
            setCount: sets.length,
          ),
        );
      case ExerciseCoachPattern.stableReady:
        final next = a.workingWeight + _incrementFor(a.workingWeight);
        return finish(
          ExerciseDecision(
            pattern: a.pattern,
            action: ExerciseCoachAction.increase,
            actionLabel: 'وزنه را افزایش بده',
            workingWeightKg: a.workingWeight,
            nextWeightKg: next,
            targetReps: a.targetReps,
            effortRpe: a.effortRpe,
            previousComparison: note,
            setCount: sets.length,
          ),
        );
      case ExerciseCoachPattern.heavyProbeEarned:
        final bridge = _bridgeWeight(a.workingWeight, a.peakWeight);
        final repeated = compare?.repeatedSameLoads == true;
        return finish(
          ExerciseDecision(
            pattern: a.pattern,
            action: ExerciseCoachAction.bridge,
            actionLabel: repeated
                ? 'ست‌های اول را یک پله بالا بیاور'
                : 'دو ست پایه، ست آخر سنگین',
            workingWeightKg: a.workingWeight,
            nextWeightKg: a.peakWeight,
            bridgeWeightKg: bridge,
            probeWeightKg: a.probeWeight,
            targetReps: a.targetReps,
            effortRpe: a.effortRpe,
            previousComparison: note,
            setCount: sets.length,
          ),
        );
      case ExerciseCoachPattern.noWeight:
        final canProgress =
            compare != null &&
            _allHitTargets(sets) &&
            _effortAllowsProgress(sets) &&
            !_repsFaded(sets);
        return finish(
          ExerciseDecision(
            pattern: a.pattern,
            action: canProgress
                ? ExerciseCoachAction.bodyProgress
                : ExerciseCoachAction.hold,
            actionLabel: canProgress
                ? 'یک تکرار به ست آخر اضافه کن'
                : 'همین تکرارها را نگه دار',
            targetReps: a.targetReps,
            effortRpe: a.effortRpe,
            previousComparison: note,
            setCount: sets.length,
          ),
        );
      case ExerciseCoachPattern.heavyProbeFailed:
      case ExerciseCoachPattern.dropBailout:
      case ExerciseCoachPattern.mixed:
      case ExerciseCoachPattern.stableHoldMissedReps:
      case ExerciseCoachPattern.stableHoldFaded:
      case ExerciseCoachPattern.stableHoldHighRpe:
      case ExerciseCoachPattern.incompleteVolume:
        return finish(
          ExerciseDecision(
            pattern: pattern,
            action: ExerciseCoachAction.hold,
            actionLabel: pattern == ExerciseCoachPattern.incompleteVolume
                ? 'اول همه ست‌ها را کامل کن'
                : pattern == ExerciseCoachPattern.stableHoldMissedReps ||
                      pattern == ExerciseCoachPattern.stableHoldFaded
                ? 'اول تکرارها را کامل کن'
                : 'همین وزنه را نگه دار',
            workingWeightKg: a.workingWeight,
            nextWeightKg: a.workingWeight,
            probeWeightKg: a.probeWeight,
            targetReps: a.targetReps,
            effortRpe: a.effortRpe,
            previousComparison: note,
            setCount: sets.length,
          ),
        );
      case ExerciseCoachPattern.timedReady:
      case ExerciseCoachPattern.timedHold:
        return finish(
          ExerciseDecision(
            pattern: a.pattern,
            action: ExerciseCoachAction.hold,
            actionLabel: 'همین هدف را نگه دار',
            previousComparison: note,
            setCount: sets.length,
          ),
        );
    }
  }

  static ExerciseDecision _timedDecision(
    List<LoggedSetPerformance> sets, {
    List<PreviousExerciseSet>? previousSets,
    int? prescribedSetCount,
  }) {
    if (_isIncompleteVolume(sets.length, prescribedSetCount)) {
      final weighted = sets.where((s) => s.hasWeight).toList();
      final working = weighted.isEmpty
          ? 0.0
          : _computeWorkingWeight(weighted, _primaryTargetReps(sets));
      return ExerciseDecision(
        pattern: ExerciseCoachPattern.incompleteVolume,
        action: ExerciseCoachAction.hold,
        actionLabel: 'اول همه ست‌ها را کامل کن',
        workingWeightKg: working > 0 ? working : null,
        nextWeightKg: working > 0 ? working : null,
        effortRpe: _effortRpe(sets),
        previousComparison: _compareWithPrevious(sets, previousSets)?.summary,
        setCount: sets.length,
        prescribedSetCount: prescribedSetCount,
      );
    }
    final withTargets = sets.where(
      (s) => (s.targetSeconds ?? 0) > 0 && s.hasTimedPerformance,
    );
    final allHit =
        withTargets.isNotEmpty &&
        withTargets.every((s) => (s.actualSeconds ?? 0) >= s.targetSeconds!);
    final hasHistory = _compareWithPrevious(sets, previousSets) != null;
    final canProgress =
        allHit &&
        hasHistory &&
        _effortAllowsProgress(sets) &&
        !_repsFaded(sets);
    final pattern = canProgress
        ? ExerciseCoachPattern.timedReady
        : ExerciseCoachPattern.timedHold;
    return ExerciseDecision(
      pattern: pattern,
      action: canProgress
          ? ExerciseCoachAction.bodyProgress
          : ExerciseCoachAction.hold,
      actionLabel: canProgress
          ? '۵–۱۰ ثانیه به ست آخر اضافه کن'
          : 'همان زمان هدف را تکرار کن',
      effortRpe: _effortRpe(sets),
      previousComparison: _compareWithPrevious(sets, previousSets)?.summary,
      setCount: sets.length,
      prescribedSetCount: prescribedSetCount,
    );
  }

  static _LiftCompare? _compareWithPrevious(
    List<LoggedSetPerformance> today,
    List<PreviousExerciseSet>? previousSets,
  ) {
    if (previousSets == null || previousSets.isEmpty || today.isEmpty) {
      return null;
    }
    final prev = previousSets.where((s) => s.hasMeaningfulData).toList();
    if (prev.isEmpty) return null;

    final paired = math.min(today.length, prev.length);
    final deltas = <_SetDelta>[];
    for (var i = 0; i < paired; i++) {
      deltas.add(
        _SetDelta(
          index: i + 1,
          weightDelta: today[i].actualWeightKg - (prev[i].weight ?? 0),
          repsDelta: today[i].actualReps - (prev[i].reps ?? 0),
        ),
      );
    }

    final lines = <String>[_collapsedDeltaStory(deltas, today, prev)];

    final todayPeak = _heaviestToday(today);
    final prevPeak = _heaviestPrevious(prev);
    if (todayPeak != null &&
        prevPeak != null &&
        todayPeak.actualWeightKg > (prevPeak.weight ?? 0) + 0.01) {
      final idx = today.indexOf(todayPeak) + 1;
      lines.add(
        'رکورد امروز ${_labelLogged(todayPeak)} بود؛ روی ست ${_faInt(idx)}.',
      );
    }

    final prevVol = _volumePrevious(prev);
    final todayVol = _volumeToday(today);
    if (prevVol > 0 && todayVol > prevVol * 1.08) {
      lines.add('حجم کار نسبت به قبل بیشتر شد.');
    } else if (prevVol > 0 && todayVol < prevVol * 0.92) {
      lines.add('حجم کار نسبت به قبل کمتر شد.');
    }

    final prevWorking = _modalWeight(
      prev.map((s) => s.weight ?? 0).where((w) => w > 0).toList(),
    );
    final todayWorking = _modalWeight(
      today.map((s) => s.actualWeightKg).where((w) => w > 0).toList(),
    );
    final jumped = todayWorking >= prevWorking + 2.5;
    final repeated =
        deltas.isNotEmpty &&
        deltas.every((d) => d.weightDelta.abs() < 0.5 && d.repsDelta == 0);

    return _LiftCompare(
      summary: lines.where((l) => l.trim().isNotEmpty).join('\n'),
      alreadyJumpedLoad: jumped,
      repeatedSameLoads: repeated,
    );
  }

  static String _collapsedDeltaStory(
    List<_SetDelta> deltas,
    List<LoggedSetPerformance> today,
    List<PreviousExerciseSet> prev,
  ) {
    if (today.length != prev.length) {
      return 'قبل ${prev.length} ست، امروز ${today.length} ست.';
    }
    if (deltas.isEmpty) return '';

    if (deltas.every((d) => d.weightDelta.abs() < 0.5 && d.repsDelta == 0)) {
      return 'هر ${deltas.length} ست مثل جلسه قبل بود.';
    }

    final first = deltas.first;
    final allSameW = deltas.every(
      (d) => (d.weightDelta - first.weightDelta).abs() < 0.5,
    );
    final allSameR = deltas.every((d) => d.repsDelta == first.repsDelta);
    if (allSameW && allSameR) {
      return 'هر ${deltas.length} ست ${_deltaPhrase(first)}.';
    }

    if (deltas.length >= 2) {
      final head = deltas.sublist(0, deltas.length - 1);
      final last = deltas.last;
      final headSame = head.every(
        (d) =>
            (d.weightDelta - head.first.weightDelta).abs() < 0.5 &&
            d.repsDelta == head.first.repsDelta,
      );
      if (headSame) {
        final headLabel = head.length == 1 ? 'ست اول' : 'ست‌های اول';
        return '$headLabel ${_deltaPhrase(head.first)}. '
            'ست آخر ${_deltaPhrase(last)}.';
      }
    }

    return deltas
        .map((d) => 'ست ${_faInt(d.index)} ${_deltaPhrase(d)}')
        .join(' ');
  }

  static String _deltaPhrase(_SetDelta delta) {
    final bits = <String>[];
    if (delta.weightDelta >= 0.5) {
      bits.add('${_formatWeight(delta.weightDelta)} کیلو اومد بالا');
    } else if (delta.weightDelta <= -0.5) {
      bits.add('${_formatWeight(-delta.weightDelta)} کیلو اومد پایین');
    }
    if (delta.repsDelta > 0) {
      bits.add('${delta.repsDelta} تکرار بیشتر');
    } else if (delta.repsDelta < 0) {
      bits.add('${-delta.repsDelta} تکرار کمتر');
    }
    if (bits.isEmpty) return 'بدون تغییر بود';
    return bits.join(' و ');
  }

  static String _labelLogged(LoggedSetPerformance set) {
    return PreviousExerciseSet(
      reps: set.actualReps > 0 ? set.actualReps : null,
      weight: set.actualWeightKg > 0 ? set.actualWeightKg : null,
      seconds: set.actualSeconds,
    ).summaryLabel;
  }

  static LoggedSetPerformance? _heaviestToday(List<LoggedSetPerformance> sets) {
    LoggedSetPerformance? best;
    for (final set in sets) {
      if (!set.hasWeight) continue;
      if (best == null ||
          set.actualWeightKg > best.actualWeightKg + 0.01 ||
          ((set.actualWeightKg - best.actualWeightKg).abs() < 0.01 &&
              set.actualReps > best.actualReps)) {
        best = set;
      }
    }
    return best;
  }

  static PreviousExerciseSet? _heaviestPrevious(
    List<PreviousExerciseSet> sets,
  ) {
    PreviousExerciseSet? best;
    for (final set in sets) {
      if (!set.hasMeaningfulData) continue;
      final w = set.weight ?? 0;
      final bestW = best?.weight ?? 0;
      if (best == null ||
          w > bestW + 0.01 ||
          ((w - bestW).abs() < 0.01 && (set.reps ?? 0) > (best.reps ?? 0))) {
        best = set;
      }
    }
    return best;
  }

  static double _volumeToday(List<LoggedSetPerformance> sets) {
    var total = 0.0;
    for (final set in sets) {
      total += set.actualReps * set.actualWeightKg;
    }
    return total;
  }

  static double _volumePrevious(List<PreviousExerciseSet> sets) {
    var total = 0.0;
    for (final set in sets) {
      total += (set.reps ?? 0) * (set.weight ?? 0);
    }
    return total;
  }

  static int? _heavierSetIndex(
    List<LoggedSetPerformance> sets,
    double workingWeight,
  ) {
    for (var i = sets.length - 1; i >= 0; i--) {
      if (sets[i].actualWeightKg >= workingWeight + 2.5) return i + 1;
    }
    return null;
  }

  static _Assessment _assess(
    List<LoggedSetPerformance> sets, {
    int? prescribedSetCount,
  }) {
    if (_isIncompleteVolume(sets.length, prescribedSetCount)) {
      final weighted = sets.where((s) => s.hasWeight).toList();
      final targetReps = _primaryTargetReps(sets);
      final working = weighted.isEmpty
          ? 0.0
          : _computeWorkingWeight(weighted, targetReps);
      final peak = weighted.isEmpty
          ? 0.0
          : weighted.map((s) => s.actualWeightKg).reduce(math.max);
      final minW = weighted.isEmpty
          ? 0.0
          : weighted.map((s) => s.actualWeightKg).reduce(math.min);
      return _Assessment(
        pattern: ExerciseCoachPattern.incompleteVolume,
        workingWeight: working,
        peakWeight: peak,
        minWeight: minW,
        targetReps: targetReps,
        effortRpe: _effortRpe(sets),
        prescribedSetCount: prescribedSetCount,
      );
    }

    final weighted = sets.where((s) => s.hasWeight).toList();
    final targetReps = _primaryTargetReps(sets);
    final effort = _effortRpe(sets);

    if (weighted.isEmpty) {
      return _Assessment(
        pattern: ExerciseCoachPattern.noWeight,
        workingWeight: 0,
        peakWeight: 0,
        minWeight: 0,
        targetReps: targetReps,
        effortRpe: effort,
      ).withPrescription(prescribedSetCount);
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
          pattern: ExerciseCoachPattern.heavyProbeFailed,
          workingWeight: working,
          peakWeight: peak,
          minWeight: minW,
          targetReps: targetReps,
          probeWeight: probe.actualWeightKg,
          probeReps: probe.actualReps,
          effortRpe: effort,
        ).withPrescription(prescribedSetCount);
      }
      if (probe.actualWeightKg > working + 0.5) {
        return _Assessment(
          pattern: ExerciseCoachPattern.heavyProbeEarned,
          workingWeight: working,
          peakWeight: peak,
          minWeight: minW,
          targetReps: targetReps,
          probeWeight: probe.actualWeightKg,
          probeReps: probe.actualReps,
          effortRpe: effort,
        ).withPrescription(prescribedSetCount);
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
        ).withPrescription(prescribedSetCount);
      }

      final last = weighted.last;
      final earlier = weighted.sublist(0, weighted.length - 1);
      final earlierPeak = earlier.isEmpty
          ? last.actualWeightKg
          : earlier.map((s) => s.actualWeightKg).reduce(math.max);

      if (last.actualWeightKg <= earlierPeak - 2.5 &&
          (earlierPeak - last.actualWeightKg) / earlierPeak >= 0.12) {
        return _Assessment(
          pattern: ExerciseCoachPattern.dropBailout,
          workingWeight: working,
          peakWeight: peak,
          minWeight: minW,
          targetReps: targetReps,
          effortRpe: effort,
        ).withPrescription(prescribedSetCount);
      }

      return _Assessment(
        pattern: ExerciseCoachPattern.mixed,
        workingWeight: working,
        peakWeight: peak,
        minWeight: minW,
        targetReps: targetReps,
        effortRpe: effort,
      ).withPrescription(prescribedSetCount);
    }

    return _Assessment(
      pattern: _stableOutcome(sets, workingWeight: working),
      workingWeight: working,
      peakWeight: peak,
      minWeight: minW,
      targetReps: targetReps,
      effortRpe: effort,
    ).withPrescription(prescribedSetCount);
  }

  /// Decide ready vs hold — and *why* we hold (reps vs RPE).
  static ExerciseCoachPattern _stableOutcome(
    List<LoggedSetPerformance> sets, {
    required double workingWeight,
  }) {
    if (workingWeight <= 0) return ExerciseCoachPattern.stableHoldMissedReps;

    final hit = _allHitTargets(sets);
    final faded = _repsFaded(sets);

    if (!hit) {
      // Prefer fade copy when later sets drop after a strong first set.
      if (faded) return ExerciseCoachPattern.stableHoldFaded;
      return ExerciseCoachPattern.stableHoldMissedReps;
    }
    if (faded) return ExerciseCoachPattern.stableHoldFaded;
    if (!_effortAllowsProgress(sets))
      return ExerciseCoachPattern.stableHoldHighRpe;
    return ExerciseCoachPattern.stableReady;
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
      return _modalWeight(sustainable.map((s) => s.actualWeightKg).toList());
    }
    final sorted = weighted.map((s) => s.actualWeightKg).toList()..sort();
    return sorted[sorted.length ~/ 2];
  }

  static List<LoggedSetPerformance> _sustainableSets(
    List<LoggedSetPerformance> weighted,
    int? targetReps,
  ) {
    if (targetReps != null && targetReps > 0) {
      final hit = weighted.where((s) => s.actualReps >= targetReps).toList();
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
      final heavier = set.actualWeightKg >= workingWeight + 2.5;
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
    if (weights.isEmpty) return 0;
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
    // Pyramid / all-unique loads: median is the working base, not the peak.
    if (bestCount == 1 && weights.length >= 3) {
      final sorted = List<double>.from(weights)..sort();
      return sorted[sorted.length ~/ 2];
    }
    return bestWeight;
  }

  static double _bridgeWeight(double working, double peak) {
    if (peak <= working) return working;
    final step = _incrementFor(working);
    final nextWorking = working + step;
    // One increment toward the probe — never jump working sets all the way
    // to a single heavy top set, and never treat that top set as the new base.
    if (nextWorking >= peak - 0.01) return working;
    return nextWorking;
  }

  static bool _isMonotonicUp(List<double> values) {
    for (var i = 1; i < values.length; i++) {
      if (values[i] + 0.01 < values[i - 1]) return false;
    }
    return values.last > values.first + 0.01;
  }

  static String? _timedAnalysis(
    List<LoggedSetPerformance> sets, {
    int? prescribedSetCount,
  }) {
    if (_isIncompleteVolume(sets.length, prescribedSetCount)) {
      return _incompleteAnalysis(
        sets,
        _Assessment(
          pattern: ExerciseCoachPattern.incompleteVolume,
          workingWeight: 0,
          peakWeight: 0,
          minWeight: 0,
          targetReps: null,
          prescribedSetCount: prescribedSetCount,
        ),
      );
    }
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

  static String? _timedNextSession(
    List<LoggedSetPerformance> sets, {
    int? prescribedSetCount,
    List<PreviousExerciseSet>? previousSets,
  }) {
    if (_isIncompleteVolume(sets.length, prescribedSetCount)) {
      return _incompleteNextSession(
        sets,
        _Assessment(
          pattern: ExerciseCoachPattern.incompleteVolume,
          workingWeight: 0,
          peakWeight: 0,
          minWeight: 0,
          targetReps: null,
          prescribedSetCount: prescribedSetCount,
        ),
      );
    }
    final withTargets = sets.where(
      (s) => (s.targetSeconds ?? 0) > 0 && s.hasTimedPerformance,
    );
    if (withTargets.isEmpty) return null;
    final allHit = withTargets.every(
      (s) => (s.actualSeconds ?? 0) >= s.targetSeconds!,
    );
    final hasHistory = _compareWithPrevious(sets, previousSets) != null;
    if (allHit &&
        hasHistory &&
        _effortAllowsProgress(sets) &&
        !_repsFaded(sets)) {
      return 'جلسه بعد ۵ تا ۱۰ ثانیه به ست آخر اضافه کن.';
    }
    if (allHit && !hasHistory) {
      return 'جلسه بعد همان زمان هدف را تکرار کن تا تثبیت شود.';
    }
    return 'جلسه بعد همان زمان هدف را با فرم تمیز تکرار کن.';
  }

  static bool _isIncompleteVolume(int logged, int? prescribed) {
    return prescribed != null && prescribed > 0 && logged < prescribed;
  }

  static String _incompleteAnalysis(
    List<LoggedSetPerformance> sets,
    _Assessment a,
  ) {
    final prescribed = a.prescribedSetCount ?? sets.length;
    final weight = a.workingWeight;
    if (weight > 0) {
      return 'از $prescribed ست برنامه فقط ${sets.length} تا ثبت شد '
          '(${_formatWeight(weight)} کیلو). '
          'تا وقتی هر $prescribed ست کامل نشده، وزنه را زیاد نکن.';
    }
    return 'از $prescribed ست برنامه فقط ${sets.length} تا ثبت شد. '
        'تا وقتی همه ست‌ها کامل نشده، پیشرفت نده.';
  }

  static String _incompleteNextSession(
    List<LoggedSetPerformance> sets,
    _Assessment a,
  ) {
    final prescribed = a.prescribedSetCount ?? sets.length;
    final weight = a.workingWeight;
    if (weight > 0) {
      return 'جلسه بعد هر $prescribed ست را با ${_formatWeight(weight)} کیلو بزن '
          'و همه را ثبت کن. با ${sets.length} ست نمی‌شود وزنه همه ست‌ها را بالا برد.';
    }
    return 'جلسه بعد هر $prescribed ست را کامل کن؛ بعد از یک جلسه کامل می‌شود پیشرفت داد.';
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

  static String _faInt(int value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return value.toString().split('').map((c) {
      final i = int.tryParse(c);
      return i == null ? c : digits[i];
    }).join();
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
