/// Structured coach decision for one completed exercise (rule engine output).
///
/// Numbers live here — LLM may only cite them, never invent new loads.
enum ExerciseCoachPattern {
  stableReady,
  stableHoldMissedReps,
  stableHoldFaded,
  stableHoldHighRpe,
  dropBailout,
  heavyProbeFailed,
  heavyProbeEarned,
  mixed,
  noWeight,
  timedReady,
  timedHold,

  /// Logged fewer working sets than the program prescribed — never increase.
  incompleteVolume,

  /// First time this load/exercise is logged complete — consolidate, don't chase kg.
  stableHoldFirstSession,
}

enum ExerciseCoachAction {
  /// Increase working weight next session.
  increase,

  /// Keep the same working weight.
  hold,

  /// Bridge toward a successful probe (not a full jump).
  bridge,

  /// Stay on bodyweight / timed progression (reps or seconds).
  bodyProgress,
}

/// Deterministic next-session target for one exercise.
class ExerciseDecision {
  const ExerciseDecision({
    required this.pattern,
    required this.action,
    required this.actionLabel,
    this.workingWeightKg,
    this.nextWeightKg,
    this.bridgeWeightKg,
    this.probeWeightKg,
    this.targetReps,
    this.effortRpe,
    this.previousComparison,
    this.setCount,
    this.prescribedSetCount,
  });

  final ExerciseCoachPattern pattern;
  final ExerciseCoachAction action;
  final String actionLabel;
  final double? workingWeightKg;
  final double? nextWeightKg;
  final double? bridgeWeightKg;
  final double? probeWeightKg;
  final int? targetReps;
  final int? effortRpe;
  final String? previousComparison;

  /// Sets actually scored this session.
  final int? setCount;

  /// Sets the program asked for. If higher than [setCount], do not increase.
  final int? prescribedSetCount;

  bool get isIncompleteVolume =>
      pattern == ExerciseCoachPattern.incompleteVolume ||
      (prescribedSetCount != null &&
          setCount != null &&
          setCount! < prescribedSetCount!);

  ExerciseDecision copyWith({int? setCount, int? prescribedSetCount}) {
    return ExerciseDecision(
      pattern: pattern,
      action: action,
      actionLabel: actionLabel,
      workingWeightKg: workingWeightKg,
      nextWeightKg: nextWeightKg,
      bridgeWeightKg: bridgeWeightKg,
      probeWeightKg: probeWeightKg,
      targetReps: targetReps,
      effortRpe: effortRpe,
      previousComparison: previousComparison,
      setCount: setCount ?? this.setCount,
      prescribedSetCount: prescribedSetCount ?? this.prescribedSetCount,
    );
  }

  /// Short chip label for Decision Card UI.
  String get badgeLabel {
    switch (action) {
      case ExerciseCoachAction.increase:
        return 'افزایش';
      case ExerciseCoachAction.hold:
        return 'نگه دار';
      case ExerciseCoachAction.bridge:
        return 'پل بزن';
      case ExerciseCoachAction.bodyProgress:
        return 'پیشرفت سبک';
    }
  }

  /// Primary numeric line for the card (kg targets).
  String? get targetLine {
    switch (action) {
      case ExerciseCoachAction.increase:
        final next = nextWeightKg;
        if (next == null) return null;
        return 'جلسه بعد $_setsPhrase ${_formatWeight(next)} کیلو';
      case ExerciseCoachAction.hold:
        final w = workingWeightKg;
        if (w == null || w <= 0) {
          if (isIncompleteVolume) {
            return 'جلسه بعد $_setsPhrase را کامل کن';
          }
          return null;
        }
        return 'جلسه بعد $_setsPhrase ${_formatWeight(w)} کیلو';
      case ExerciseCoachAction.bridge:
        final bridge = bridgeWeightKg ?? workingWeightKg;
        final peak = probeWeightKg ?? nextWeightKg;
        if (bridge == null) return null;
        if (peak != null && peak > bridge + 0.01) {
          return '۲ ست ${_formatWeight(bridge)}، ست آخر ${_formatWeight(peak)}';
        }
        return 'جلسه بعد ${_formatWeight(bridge)} کیلو';
      case ExerciseCoachAction.bodyProgress:
        return null;
    }
  }

  String get _setsPhrase {
    final n = prescribedSetCount ?? setCount;
    if (n == null || n <= 0) return 'همه ست‌ها';
    if (n == 1) return 'همان ۱ ست';
    return 'هر $n ست';
  }

  /// Locked JSON for LLM context — model must cite only these numbers.
  Map<String, Object?> toLockJson() {
    return <String, Object?>{
      'pattern': pattern.name,
      'action': action.name,
      'action_label': actionLabel,
      if (workingWeightKg != null) 'working_weight_kg': workingWeightKg,
      if (nextWeightKg != null) 'next_weight_kg': nextWeightKg,
      if (bridgeWeightKg != null) 'bridge_weight_kg': bridgeWeightKg,
      if (probeWeightKg != null) 'probe_weight_kg': probeWeightKg,
      if (targetReps != null) 'target_reps': targetReps,
      if (effortRpe != null) 'effort_rpe': effortRpe,
      if (previousComparison != null) 'previous_comparison': previousComparison,
      if (setCount != null) 'set_count': setCount,
      if (prescribedSetCount != null)
        'prescribed_set_count': prescribedSetCount,
      'incomplete_volume': isIncompleteVolume,
      'first_session': pattern == ExerciseCoachPattern.stableHoldFirstSession,
      'chase_load': action == ExerciseCoachAction.increase,
    };
  }

  static ExerciseDecision? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.map((k, v) => MapEntry(k.toString(), v));
    final patternName = json['pattern']?.toString();
    final actionName = json['action']?.toString();
    final patternMatches = ExerciseCoachPattern.values.where(
      (e) => e.name == patternName,
    );
    final actionMatches = ExerciseCoachAction.values.where(
      (e) => e.name == actionName,
    );
    if (patternMatches.isEmpty || actionMatches.isEmpty) return null;
    return ExerciseDecision(
      pattern: patternMatches.first,
      action: actionMatches.first,
      actionLabel: json['action_label']?.toString() ?? '',
      workingWeightKg: _asDouble(json['working_weight_kg']),
      nextWeightKg: _asDouble(json['next_weight_kg']),
      bridgeWeightKg: _asDouble(json['bridge_weight_kg']),
      probeWeightKg: _asDouble(json['probe_weight_kg']),
      targetReps: _asInt(json['target_reps']),
      effortRpe: _asInt(json['effort_rpe']),
      previousComparison: json['previous_comparison']?.toString(),
      setCount: _asInt(json['set_count']),
      prescribedSetCount: _asInt(json['prescribed_set_count']),
    );
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _formatWeight(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
