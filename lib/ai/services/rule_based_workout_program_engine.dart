import 'dart:math';

import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/services/ai_workout_generator_service.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

/// تولید برنامه تمرین بدون LLM — با تنوع و بدون تکرار حرکت در یک برنامه.
class RuleBasedWorkoutProgramEngine {
  static const int _maxRecentHistory = 48;

  WorkoutProgram? build({
    required Map<String, dynamic> userProfile,
    required UserAnalysis analysis,
    required List<Exercise> exercises,
    required String programName,
    required String sessionVolumeHint,
    required int daysPerWeek,
    Set<int> recentlyUsedExerciseIds = const {},
    int? varietySeed,
    String priorityMuscleText = '',
  }) {
    if (exercises.isEmpty) return null;

    final rng = Random(
      varietySeed ?? DateTime.now().microsecondsSinceEpoch,
    );
    final goal = WorkoutScience.goalFromProfile(
      analysis.goals,
      userProfile.values.join(' '),
    );
    final dayLabels = WorkoutScience.dayLabels(daysPerWeek);
    final bucketsPerDay = WorkoutScience.bucketsPerDay(daysPerWeek);
    final priorityBuckets =
        WorkoutScience.priorityBucketsFromText(priorityMuscleText);
    final perSession = WorkoutScience.exercisesPerSession(sessionVolumeHint);
    final usedInProgram = <int>{};
    final sessions = <WorkoutSession>[];

    final recentCap = recentlyUsedExerciseIds.take(_maxRecentHistory).toSet();

    for (var i = 0; i < dayLabels.length; i++) {
      final targetBuckets = bucketsPerDay[i];
      final dayPriority = priorityBuckets
          .where(targetBuckets.contains)
          .toSet();
      final picked = _pickExercisesForDay(
        all: exercises,
        targetBuckets: targetBuckets,
        count: perSession + (dayPriority.isNotEmpty ? 1 : 0),
        usedInProgram: usedInProgram,
        recentIds: recentCap,
        experience: analysis.experience,
        goal: goal,
        rng: rng,
        dayIndex: i,
        priorityBuckets: dayPriority,
      );

      if (picked.isEmpty) continue;

      final capped = picked.length > perSession + 1
          ? picked.sublist(0, perSession + 1)
          : picked;
      final ordered = _orderExercisesInSession(capped, rng);

      final normalExercises = ordered.map((ex) {
        final compound = WorkoutScience.isCompoundExercise(
          ex.name,
          ex.exerciseType,
        );
        final setCount = WorkoutScience.setCountForExercise(
          goal,
          analysis.experience,
          compound,
        );
        final style = ex.exerciseType.contains('کاردیو') ||
                ex.exerciseType.contains('هوازی')
            ? ExerciseStyle.setsTime
            : ExerciseStyle.setsReps;
        final sets = List<ExerciseSet>.generate(setCount, (si) {
          if (style == ExerciseStyle.setsTime) {
            final sec = 45 + (si * 10) + rng.nextInt(8);
            return ExerciseSet(timeSeconds: sec.clamp(30, 120));
          }
          return ExerciseSet(
            reps: WorkoutScience.repsForGoal(
              goal,
              analysis.desiredIntensity,
              si,
            ),
          );
        });

        return NormalExercise(
          exerciseId: ex.id,
          tag: ex.name,
          style: style,
          sets: sets,
          note: _exerciseNote(ex, analysis, goal, rng),
        );
      }).toList();

      sessions.add(
        WorkoutSession(
          day: dayLabels[i],
          exercises: normalExercises,
          notes: _sessionNotes(
            goal,
            analysis,
            dayLabels[i],
            priorityBuckets: dayPriority,
          ),
        ),
      );
    }

    if (sessions.isEmpty) return null;

    return WorkoutProgram(
      name: programName,
      sessions: sessions,
    );
  }

  /// حرکت‌های انتخاب‌شده در برنامه (برای ذخیره تاریخچه تنوع).
  static Set<int> collectExerciseIds(WorkoutProgram program) {
    final ids = <int>{};
    for (final session in program.sessions) {
      for (final ex in session.exercises) {
        if (ex is NormalExercise && ex.exerciseId > 0) {
          ids.add(ex.exerciseId);
        }
      }
    }
    return ids;
  }

  List<Exercise> _pickExercisesForDay({
    required List<Exercise> all,
    required Set<MuscleBucket> targetBuckets,
    required int count,
    required Set<int> usedInProgram,
    required Set<int> recentIds,
    required String experience,
    required TrainingGoal goal,
    required Random rng,
    required int dayIndex,
    Set<MuscleBucket> priorityBuckets = const {},
  }) {
    final byBucket = <MuscleBucket, List<Exercise>>{};
    for (final bucket in targetBuckets) {
      byBucket[bucket] = [];
    }
    byBucket[MuscleBucket.other] = [];

    for (final e in all) {
      if (usedInProgram.contains(e.id)) continue;
      final bucket = WorkoutScience.muscleBucket(e.mainMuscle);
      if (!targetBuckets.contains(bucket) && bucket != MuscleBucket.other) {
        continue;
      }
      final key = targetBuckets.contains(bucket) ? bucket : MuscleBucket.other;
      byBucket.putIfAbsent(key, () => []).add(e);
    }

    for (final entry in byBucket.entries) {
      entry.value.sort((a, b) {
        final ac = WorkoutScience.isCompoundExercise(a.name, a.exerciseType);
        final bc = WorkoutScience.isCompoundExercise(b.name, b.exerciseType);
        if (ac != bc) return ac ? -1 : 1;
        return _difficultyRank(a.difficulty, experience)
            .compareTo(_difficultyRank(b.difficulty, experience));
      });
      entry.value
        ..sort((a, b) {
          final aRecent = recentIds.contains(a.id) ? 1 : 0;
          final bRecent = recentIds.contains(b.id) ? 1 : 0;
          return aRecent.compareTo(bRecent);
        })
        ..shuffle(rng);
      if (entry.value.length > 1) {
        final rotate = (dayIndex + rng.nextInt(entry.value.length)) %
            entry.value.length;
        entry.value.setAll(
          0,
          [...entry.value.sublist(rotate), ...entry.value.sublist(0, rotate)],
        );
      }
    }

    final result = <Exercise>[];
    final bucketsFilled = <MuscleBucket>{};

    final bucketOrder = targetBuckets.toList();
    if (priorityBuckets.isNotEmpty) {
      final prioritized =
          bucketOrder.where(priorityBuckets.contains).toList()..shuffle(rng);
      final rest =
          bucketOrder.where((b) => !priorityBuckets.contains(b)).toList()
            ..shuffle(rng);
      bucketOrder
        ..clear()
        ..addAll(prioritized)
        ..addAll(rest);
    } else {
      bucketOrder.shuffle(rng);
    }

    // مرحله ۱: یک حرکت چندمفصلی از هر گروه (در صورت وجود)
    for (final bucket in bucketOrder) {
      if (result.length >= count) break;
      final list = byBucket[bucket] ?? [];
      final compound = list.where(
        (e) =>
            WorkoutScience.isCompoundExercise(e.name, e.exerciseType) &&
            !result.any((r) => r.id == e.id),
      );
      if (compound.isEmpty) continue;
      final pick = compound.first;
      result.add(pick);
      usedInProgram.add(pick.id);
      bucketsFilled.add(bucket);
    }

    // مرحله ۲: round-robin بین گروه‌ها برای تکمیل (ایزوله / متنوع)
    var safety = 0;
    while (result.length < count && safety < count * bucketOrder.length * 3) {
      safety++;
      var addedThisRound = false;
      for (final bucket in bucketOrder) {
        if (result.length >= count) break;
        final list = byBucket[bucket] ?? [];
        Exercise? next;
        for (final e in list) {
          if (result.any((r) => r.id == e.id)) continue;
          next = e;
          break;
        }
        if (next == null) continue;
        if (bucketsFilled.contains(bucket) &&
            result.length >= count - 1 &&
            !WorkoutScience.isCompoundExercise(next.name, next.exerciseType)) {
          continue;
        }
        result.add(next);
        usedInProgram.add(next.id);
        bucketsFilled.add(bucket);
        addedThisRound = true;
      }
      if (!addedThisRound) break;
    }

    return result;
  }

  List<Exercise> _orderExercisesInSession(List<Exercise> picked, Random rng) {
    final compounds = picked
        .where((e) => WorkoutScience.isCompoundExercise(e.name, e.exerciseType))
        .toList()
      ..shuffle(rng);
    final isolations = picked
        .where((e) => !WorkoutScience.isCompoundExercise(e.name, e.exerciseType))
        .toList()
      ..shuffle(rng);
    return [...compounds, ...isolations];
  }

  String _bucketLabelFa(MuscleBucket b) {
    switch (b) {
      case MuscleBucket.chest:
        return 'سینه';
      case MuscleBucket.back:
        return 'پشت';
      case MuscleBucket.shoulders:
        return 'شانه';
      case MuscleBucket.quads:
        return 'ران';
      case MuscleBucket.hamstrings:
        return 'همسترینگ';
      case MuscleBucket.glutes:
        return 'باسن';
      case MuscleBucket.biceps:
        return 'دوسر';
      case MuscleBucket.triceps:
        return 'سه‌سر';
      case MuscleBucket.core:
        return 'میان‌تنه';
      case MuscleBucket.calves:
        return 'ساق';
      case MuscleBucket.fullBody:
        return 'تمام‌بدن';
      case MuscleBucket.cardio:
        return 'کاردیو';
      case MuscleBucket.other:
        return 'سایر';
    }
  }

  int _difficultyRank(String d, String experience) {
    if (WorkoutScience.isBeginnerExperience(experience)) {
      if (d.contains('آسان') || d.contains('مبتدی')) return 0;
      if (d.contains('سخت') || d.contains('پیشرفته')) return 2;
      return 1;
    }
    if (d.contains('سخت') || d.contains('پیشرفته')) return 0;
    if (d.contains('آسان')) return 2;
    return 1;
  }

  String _sessionNotes(
    TrainingGoal goal,
    UserAnalysis analysis,
    String dayLabel, {
    Set<MuscleBucket> priorityBuckets = const {},
  }) {
    final buf = StringBuffer();
    buf.writeln('📋 $dayLabel');
    if (priorityBuckets.isNotEmpty) {
      buf.writeln(
        '🎯 اولویت این جلسه: ${priorityBuckets.map(_bucketLabelFa).join('، ')}',
      );
    }
    buf.writeln(WorkoutScience.restGuidance(goal));
    buf.writeln('🔥 گرم‌کردن: ۵–۸ دقیقه حرکت پویا + ۱–۲ ست سبک.');
    buf.writeln('🧊 سردکردن: ۳–۵ دقیقه کشش ملایم.');
    buf.writeln(
      '🔄 تنوع: حرکات این هفته با برنامه قبلی متفاوت انتخاب شده‌اند؛ همان حرکت در دو روز پیاپی تکرار نمی‌شود.',
    );
    if (analysis.hasInjuries) {
      buf.writeln(
        '⚠️ با توجه به ${analysis.injuries.join('، ')}: در صورت درد، حجم را کم کنید.',
      );
    }
    if (goal == TrainingGoal.fatLoss) {
      buf.writeln('💡 اولویت: فرم صحیح + استراحت کوتاه؛ وزنه متوسط.');
    }
    return buf.toString().trim();
  }

  String _exerciseNote(
    Exercise ex,
    UserAnalysis analysis,
    TrainingGoal goal,
    Random rng,
  ) {
    final parts = <String>[];
    if (ex.tips.isNotEmpty) {
      final tip = ex.tips[rng.nextInt(ex.tips.length)];
      parts.add(tip);
    }
    if (goal == TrainingGoal.strength &&
        WorkoutScience.isCompoundExercise(ex.name, ex.exerciseType)) {
      parts.add('آخرین ست سنگین: ۱–۲ تکرار در ذخیره (RIR 1–2).');
    }
    if (WorkoutScience.isBeginnerExperience(analysis.experience)) {
      parts.add('تمرکز روی فرم؛ افزایش وزن فقط وقتی فرم پایدار است.');
    }
    return parts.join('\n');
  }
}
