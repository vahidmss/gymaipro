import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/product_experience/domain/exercise_coach_decision.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';

/// Rule-based end-of-session debrief (no LLM).
class SessionDebrief {
  const SessionDebrief({
    required this.headline,
    required this.bullets,
    required this.nextFocus,
    required this.skippedExerciseNames,
    required this.completedExercises,
    required this.plannedExercises,
    required this.volumeTooHigh,
    required this.coreDone,
    required this.cardioDone,
    required this.improvedCount,
    required this.heldCount,
    this.decisions = const <ExerciseDecision>[],
  });

  final String headline;
  final List<String> bullets;
  final String nextFocus;
  final List<String> skippedExerciseNames;
  final int completedExercises;
  final int plannedExercises;
  final bool volumeTooHigh;
  final bool coreDone;
  final bool cardioDone;
  final int improvedCount;
  final int heldCount;
  final List<ExerciseDecision> decisions;

  bool get hasContent =>
      headline.trim().isNotEmpty ||
      bullets.isNotEmpty ||
      nextFocus.trim().isNotEmpty;

  Map<String, Object?> toLockJson() {
    return <String, Object?>{
      'headline': headline,
      'bullets': bullets,
      'next_focus': nextFocus,
      'skipped': skippedExerciseNames,
      'completed_exercises': completedExercises,
      'planned_exercises': plannedExercises,
      'volume_too_high': volumeTooHigh,
      'core_done': coreDone,
      'cardio_done': cardioDone,
      'improved_count': improvedCount,
      'held_count': heldCount,
      'decisions': decisions.map((d) => d.toLockJson()).toList(growable: false),
    };
  }

  static SessionDebrief? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.map((k, v) => MapEntry(k.toString(), v));
    final decisionsRaw = json['decisions'];
    final decisions = <ExerciseDecision>[];
    if (decisionsRaw is List) {
      for (final item in decisionsRaw) {
        final parsed = ExerciseDecision.tryParse(item);
        if (parsed != null) decisions.add(parsed);
      }
    }
    return SessionDebrief(
      headline: json['headline']?.toString() ?? '',
      bullets: _stringList(json['bullets']),
      nextFocus: json['next_focus']?.toString() ?? '',
      skippedExerciseNames: _stringList(json['skipped']),
      completedExercises: _asInt(json['completed_exercises']) ?? 0,
      plannedExercises: _asInt(json['planned_exercises']) ?? 0,
      volumeTooHigh: json['volume_too_high'] == true,
      coreDone: json['core_done'] == true,
      cardioDone: json['cardio_done'] == true,
      improvedCount: _asInt(json['improved_count']) ?? 0,
      heldCount: _asInt(json['held_count']) ?? 0,
      decisions: decisions,
    );
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }
}

/// Builds [SessionDebrief] from the live session + per-exercise decisions.
abstract final class SessionDebriefEngine {
  static SessionDebrief build({
    required WorkoutSession session,
    Map<String, WorkoutExerciseCoachFeedback> feedbackByExerciseKey =
        const <String, WorkoutExerciseCoachFeedback>{},
  }) {
    final planned = session.exercises;
    final skipped = <WorkoutExerciseSession>[];
    final completed = <WorkoutExerciseSession>[];

    for (final exercise in planned) {
      if (_isEffectivelySkipped(exercise)) {
        skipped.add(exercise);
      } else if (_hasMeaningfulWork(exercise)) {
        completed.add(exercise);
      } else {
        skipped.add(exercise);
      }
    }

    final decisions = feedbackByExerciseKey.values
        .map((f) => f.decision)
        .whereType<ExerciseDecision>()
        .toList(growable: false);

    final improved = decisions
        .where(
          (d) =>
              !d.isIncompleteVolume &&
              (d.action == ExerciseCoachAction.increase ||
                  d.action == ExerciseCoachAction.bridge ||
                  d.action == ExerciseCoachAction.bodyProgress),
        )
        .length;
    final incomplete = decisions.where((d) => d.isIncompleteVolume).length;
    final held = decisions
        .where(
          (d) => d.action == ExerciseCoachAction.hold && !d.isIncompleteVolume,
        )
        .length;

    final corePlanned = planned.where(_looksLikeCore).toList();
    final cardioPlanned = planned.where(_looksLikeCardio).toList();
    final coreDone =
        corePlanned.isNotEmpty && corePlanned.any(_hasMeaningfulWork);
    final cardioDone =
        cardioPlanned.isNotEmpty && cardioPlanned.any(_hasMeaningfulWork);

    final completionRatio = planned.isEmpty
        ? 1.0
        : completed.length / planned.length;
    final volumeTooHigh =
        skipped.length >= 2 && completionRatio < 0.85 && planned.length >= 6;

    final skippedNames = skipped
        .map((e) => e.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    final loadIncreases = decisions
        .where(
          (d) =>
              d.action == ExerciseCoachAction.increase && !d.isIncompleteVolume,
        )
        .length;
    final bridges = decisions
        .where((d) => d.action == ExerciseCoachAction.bridge)
        .length;
    final bodyProgress = decisions
        .where((d) => d.action == ExerciseCoachAction.bodyProgress)
        .length;

    final bullets = <String>[];
    if (incomplete > 0) {
      bullets.add(
        incomplete == 1
            ? 'یه حرکت همه ست‌هاش ثبت نشد؛ وزنه‌ش رو زیاد نمی‌کنیم.'
            : '$incomplete حرکت ست ناقص داشتن؛ وزنه‌شون رو زیاد نمی‌کنیم.',
      );
    }
    if (loadIncreases > 0) {
      bullets.add(
        loadIncreases == 1
            ? 'یه حرکت آمادهٔ یک پله وزنه بیشتره.'
            : '$loadIncreases حرکت آمادهٔ یک پله وزنه بیشترن.',
      );
    }
    if (bridges > 0) {
      bullets.add('یه حرکت رو پل می‌زنیم؛ همه ست‌ها رو یک‌دفعه سنگین نکن.');
    }
    if (bodyProgress > 0) {
      bullets.add(
        'یه حرکت وزنه‌ای نیست؛ تکرار یا زمان رو یه پله بیشتر کن، کیلو نه.',
      );
    }
    if (held > 0) {
      bullets.add(
        held == 1
            ? 'یه حرکت رو فعلاً همون وزنه نگه می‌داریم تا تثبیت بشه.'
            : '$held حرکت رو فعلاً همون وزنه نگه می‌داریم.',
      );
    }
    if (skippedNames.isNotEmpty) {
      final preview = skippedNames.take(3).join('، ');
      final more = skippedNames.length > 3
          ? ' و ${skippedNames.length - 3} تای دیگه'
          : '';
      bullets.add('اینا رو نزدی: $preview$more.');
    }
    if (corePlanned.isNotEmpty) {
      bullets.add(
        coreDone ? 'شکم رو زدی.' : 'شکم تو برنامه بود، ولی نرسیدی بهش.',
      );
    }
    if (cardioPlanned.isNotEmpty) {
      bullets.add(
        cardioDone ? 'هوازی رو زدی.' : 'هوازی تو برنامه بود، ولی نرسیدی بهش.',
      );
    }
    if (volumeTooHigh) {
      bullets.add('برنامه کمی شلوغ بود؛ جلسه بعد سبک‌ترش می‌کنیم.');
    }
    if (bullets.isEmpty) {
      bullets.add('${completed.length} از ${planned.length} حرکت ثبت شد.');
    }

    final headline = _headline(
      plannedCount: planned.length,
      completedCount: completed.length,
      improved: improved,
      volumeTooHigh: volumeTooHigh,
    );

    final nextFocus = _nextFocus(
      volumeTooHigh: volumeTooHigh,
      corePlanned: corePlanned.isNotEmpty,
      coreDone: coreDone,
      cardioPlanned: cardioPlanned.isNotEmpty,
      cardioDone: cardioDone,
      improved: improved,
      incomplete: incomplete,
    );

    return SessionDebrief(
      headline: headline,
      bullets: bullets,
      nextFocus: nextFocus,
      skippedExerciseNames: skippedNames,
      completedExercises: completed.length,
      plannedExercises: planned.length,
      volumeTooHigh: volumeTooHigh,
      coreDone: coreDone,
      cardioDone: cardioDone,
      improvedCount: improved,
      heldCount: held + incomplete,
      decisions: decisions,
    );
  }

  static String _headline({
    required int plannedCount,
    required int completedCount,
    required int improved,
    required bool volumeTooHigh,
  }) {
    if (plannedCount > 0 && completedCount >= plannedCount) {
      return improved > 0
          ? 'جلسه کامل شد. چند تا حرکت امروز خوب جلو رفت.'
          : 'آفرین، جلسه رو کامل زدی.';
    }
    if (volumeTooHigh) {
      return 'جلسه نصفه موند — برنامه کمی شلوغ بود.';
    }
    return 'جلسه‌ت ثبت شد.';
  }

  static String _nextFocus({
    required bool volumeTooHigh,
    required bool corePlanned,
    required bool coreDone,
    required bool cardioPlanned,
    required bool cardioDone,
    required int improved,
    required int incomplete,
  }) {
    if (volumeTooHigh) {
      return 'جلسه بعد یکی‌دو تا حرکت کمکی رو بردار؛ شکم و هوازی رو زودتر بزن.';
    }
    if (incomplete > 0) {
      return 'جلسه بعد اول همه ست‌های هر حرکت رو کامل ثبت کن؛ بعد وزنه.';
    }
    if (corePlanned && !coreDone) {
      return 'جلسه بعد شکم رو بزن قبل از اینکه کامل خسته شی.';
    }
    if (cardioPlanned && !cardioDone) {
      return 'جلسه بعد همون هوازی کوتاه رو از برنامه ننداز.';
    }
    if (improved > 0) {
      return 'جلسه بعد برو سراغ پیشنهاد هر حرکت.';
    }
    return 'جلسه بعد همون وزنه‌ها رو با فرم تمیز تکرار کن.';
  }

  static bool _isEffectivelySkipped(WorkoutExerciseSession exercise) {
    if (exercise.sets.isEmpty) return true;
    final anyWork = exercise.sets.any((set) {
      if (set.status == WorkoutSetSessionStatus.skipped) return false;
      final reps = set.actualReps ?? 0;
      final weight = set.actualWeightKg ?? 0;
      final seconds = set.durationSeconds ?? 0;
      return reps > 0 || weight > 0 || seconds > 0;
    });
    return !anyWork;
  }

  static bool _hasMeaningfulWork(WorkoutExerciseSession exercise) {
    return !_isEffectivelySkipped(exercise);
  }

  static bool _looksLikeCore(WorkoutExerciseSession exercise) {
    final hay = '${exercise.name} ${exercise.primaryMuscle}'.toLowerCase();
    return hay.contains('شکم') ||
        hay.contains('کرانچ') ||
        hay.contains('crunch') ||
        hay.contains('abs') ||
        hay.contains('core') ||
        hay.contains('plank') ||
        hay.contains('پلانک');
  }

  static bool _looksLikeCardio(WorkoutExerciseSession exercise) {
    final hay = '${exercise.name} ${exercise.primaryMuscle}'.toLowerCase();
    return hay.contains('تردمیل') ||
        hay.contains('هوازی') ||
        hay.contains('کاردیو') ||
        hay.contains('cardio') ||
        hay.contains('treadmill') ||
        hay.contains('دوچرخه') ||
        hay.contains('elliptical') ||
        hay.contains('روئینگ') ||
        hay.contains('rowing');
  }
}
