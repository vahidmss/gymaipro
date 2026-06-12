import 'package:gymaipro/models/muscle_targets.dart';

/// متن‌های کوتاه و غیرپزشکی برای نقشهٔ عضلانی.
abstract final class MuscleHeatmapInsights {
  static String? topMuscleLabel(Map<String, int> targets) {
    final sorted = MuscleTargets.sortedEntries(targets);
    if (sorted.isEmpty) return null;
    return MuscleTargets.label(sorted.first.key);
  }

  static String? lightMuscleLabel(Map<String, int> targets) {
    final sorted = MuscleTargets.sortedEntries(targets);
    if (sorted.length < 2) return null;
    final minValue = sorted.last.value;
    if (minValue <= 0) return null;
    return MuscleTargets.label(sorted.last.key);
  }

  /// «بیشترین: سینه · کم‌رنگ: پا» — فقط اگر تفاوت معنی‌دار باشد.
  static String? balanceLine(Map<String, int> targets) {
    final sorted = MuscleTargets.sortedEntries(targets);
    if (sorted.length < 2) return null;

    final top = sorted.first;
    final low = sorted.last;
    if (top.value < 25 || low.value <= 0) return null;
    if (top.value < low.value * 1.35) return null;

    return 'بیشترین: ${MuscleTargets.label(top.key)} · کم‌رنگ: ${MuscleTargets.label(low.key)}';
  }

  /// مقایسهٔ ساده با هفته قبل (بدون نمودار دوم).
  static String? weekTrendLine({
    required Map<String, int> current,
    required Map<String, int> previous,
    required int currentSessions,
    required int previousSessions,
  }) {
    final curSum = current.values.fold<int>(0, (a, b) => a + b);
    final prevSum = previous.values.fold<int>(0, (a, b) => a + b);

    if (prevSum == 0 && curSum == 0) return null;

    if (prevSum == 0 && curSum > 0) {
      return 'اولین هفته با نقشهٔ پررنگ';
    }

    if (curSum > prevSum * 1.12) {
      return 'فعال‌تر از هفته قبل';
    }
    if (curSum < prevSum * 0.88 && curSum > 0) {
      return 'سبک‌تر از هفته قبل';
    }
    if (currentSessions > previousSessions + 1) {
      return 'جلسات بیشتر از هفته قبل';
    }
    if (currentSessions > 0 &&
        previousSessions > 0 &&
        currentSessions == previousSessions) {
      return 'هم‌تراز با هفته قبل';
    }
    return null;
  }

  static String activityLine({
    required int workoutDays,
    required int sessionCount,
  }) {
    final parts = <String>[];
    if (workoutDays > 0) {
      parts.add('$workoutDays روز');
    }
    if (sessionCount > 0) {
      parts.add('$sessionCount جلسه');
    }
    return parts.join(' · ');
  }

  /// یک عضله از برنامه که این هفته در لاگ نیامده (فقط آگاهی).
  static String? programGapLine({
    required Set<String> programMuscleKeys,
    required Map<String, int> weekTargets,
  }) {
    if (programMuscleKeys.isEmpty) return null;

    const activeThreshold = 18;
    final missing = <String>[];
    for (final key in programMuscleKeys) {
      final v = weekTargets[key] ?? 0;
      if (v < activeThreshold) {
        missing.add(key);
      }
    }
    if (missing.isEmpty) return null;

    missing.sort(
      (a, b) => MuscleTargets.label(a).compareTo(MuscleTargets.label(b)),
    );
    final label = MuscleTargets.label(missing.first);
    if (missing.length == 1) {
      return 'در برنامه‌ات $label هست؛ این هفته ثبت نشده';
    }
    return 'در برنامه‌ات $label و ${missing.length - 1} عضله دیگر هست؛ این هفته کم‌ثبت‌اند';
  }
}
