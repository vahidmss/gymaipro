import 'package:gymaipro/ai/workout/generator/llm_iran_gym_style.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_muscle_tags.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/ai/workout/models/workout_week.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:uuid/uuid.dart';

/// Silent post-processor: fix day focus / volume / silly names before validate.
/// Never surfaces internals to the user — engines only.
abstract final class LlmWorkoutProgramSanitizer {
  const LlmWorkoutProgramSanitizer._();

  static const _uuid = Uuid();

  static WorkoutProgram sanitize(
    WorkoutProgram program, {
    required List<Exercise> curatedCatalog,
    required Set<int> usedAcrossProgram,
  }) {
    final used = Set<int>.from(usedAcrossProgram);
    final days = <WorkoutDay>[
      for (final day in program.allDays)
        _sanitizeDay(
          day,
          curated: curatedCatalog,
          usedAcrossProgram: used,
        ),
    ];

    final name = _sanitizeName(program.name);
    return WorkoutProgram(
      id: program.id,
      userId: program.userId,
      name: name,
      version: program.version,
      status: program.status,
      source: program.source,
      goal: program.goal,
      experienceLevel: program.experienceLevel,
      daysPerWeek: program.daysPerWeek,
      sessionDurationMinutes: program.sessionDurationMinutes,
      weeks: <WorkoutWeek>[
        WorkoutWeek(
          id: program.weeks.isNotEmpty ? program.weeks.first.id : _uuid.v4(),
          weekIndex: 0,
          days: days,
        ),
      ],
      programReasons: program.programReasons,
      createdAt: program.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static String _sanitizeName(String raw) {
    var name = raw.trim();
    const banned = <String>[
      'حرکات آشنا',
      'با حرکات پایه',
      'حرکات پایه',
      'حرکت آشنا',
      'آشنای باشگاهی',
      'حرکات رایج',
      'حرکت رایج',
      'برنامه جذاب',
      'جذاب با',
    ];
    for (final token in banned) {
      name = name.replaceAll(token, '').trim();
    }
    name = name
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'[—\-–]\s*$'), '')
        .replaceAll(RegExp(r'^\s*[—\-–]'), '')
        .trim();
    if (name.isEmpty || name.length < 4) {
      return 'برنامه تمرینی باشگاهی';
    }
    if (name.length > 42) {
      name = '${name.substring(0, 40).trim()}…';
    }
    return name;
  }

  static WorkoutDay _sanitizeDay(
    WorkoutDay day, {
    required List<Exercise> curated,
    required Set<int> usedAcrossProgram,
  }) {
    final label = day.label;
    var kept = day.exercises
        .where((e) => _belongsOnDay(label, e.primaryMuscle))
        .where((e) => !usedAcrossProgram.contains(e.catalogExerciseId))
        .toList(growable: true);

    // De-dupe within the day (keep first occurrence).
    final seen = <int>{};
    kept = kept
        .where((e) => seen.add(e.catalogExerciseId))
        .toList(growable: true);

    kept = _capPushVolume(label, kept);
    kept = _capLegQuads(label, kept);

    const need = 5;
    if (kept.length < need) {
      kept = _fillDay(
        label: label,
        existing: kept,
        curated: curated,
        usedAcrossProgram: usedAcrossProgram,
        targetCount: need,
      );
      // Fill can reintroduce volume — cap again.
      kept = _capPushVolume(label, kept);
      kept = _capLegQuads(label, kept);
    }

    // Push days without triceps: force one in if catalog has it.
    if (_isPushDay(label) &&
        !kept.any((e) => _isTricep(e.primaryMuscle.toLowerCase()))) {
      kept = _ensureMuscleOnDay(
        label: label,
        existing: kept,
        curated: curated,
        usedAcrossProgram: usedAcrossProgram,
        muscleKey: 'triceps',
        maxTotal: 7,
      );
      kept = _capPushVolume(label, kept);
    }

    // Push days with only one chest move feel incomplete for gym PPL.
    if (_isPushDay(label)) {
      final chestCount = kept
          .where((e) => _isChest(e.primaryMuscle.toLowerCase()))
          .length;
      if (chestCount < 2 && kept.length < 7) {
        kept = _ensureMuscleOnDay(
          label: label,
          existing: kept,
          curated: curated,
          usedAcrossProgram: usedAcrossProgram,
          muscleKey: 'chest',
          maxTotal: 7,
        );
        kept = _capPushVolume(label, kept);
      }
    }

    // Leg days: ensure posterior chain + calves when missing.
    if (_isLegDay(label)) {
      final hasHam = kept.any((e) => _isHamstring(e.primaryMuscle.toLowerCase()));
      final hasGlute = kept.any((e) => _isGlute(e.primaryMuscle.toLowerCase()));
      if (!hasHam) {
        kept = _ensureMuscleOnDay(
          label: label,
          existing: kept,
          curated: curated,
          usedAcrossProgram: usedAcrossProgram,
          muscleKey: 'hamstrings',
          maxTotal: 7,
        );
      }
      if (!hasGlute &&
          !kept.any((e) => _isGlute(e.primaryMuscle.toLowerCase()))) {
        kept = _ensureMuscleOnDay(
          label: label,
          existing: kept,
          curated: curated,
          usedAcrossProgram: usedAcrossProgram,
          muscleKey: 'glutes',
          maxTotal: 7,
        );
      }
      final hasCalf = kept.any((e) => _isCalf(e.primaryMuscle.toLowerCase()));
      if (!hasCalf && kept.length < 7) {
        kept = _ensureMuscleOnDay(
          label: label,
          existing: kept,
          curated: curated,
          usedAcrossProgram: usedAcrossProgram,
          muscleKey: 'calves',
          maxTotal: 7,
        );
      }
      kept = _capLegQuads(label, kept);
    }

    if (kept.length < need) {
      kept = _fillDay(
        label: label,
        existing: kept,
        curated: curated,
        usedAcrossProgram: usedAcrossProgram,
        targetCount: need,
      );
      kept = _capPushVolume(label, kept);
      kept = _capLegQuads(label, kept);
    }

    // Gym-practical order: group muscles, compounds first, core/time last.
    kept = _orderDayExercises(label, kept);

    // Cap length without chopping finishers off the front of the session.
    while (kept.length > 7) {
      final dropIdx = kept.lastIndexWhere(
        (e) => !_isCore(e.primaryMuscle.toLowerCase()) && !_isTimeFinisher(e),
      );
      if (dropIdx < 0) {
        kept = kept.take(7).toList(growable: false);
        break;
      }
      kept = <WorkoutExercise>[
        ...kept.take(dropIdx),
        ...kept.skip(dropIdx + 1),
      ];
    }

    // Re-number after final order.
    kept = _orderDayExercises(label, kept);

    for (final e in kept) {
      usedAcrossProgram.add(e.catalogExerciseId);
    }

    return WorkoutDay(
      id: day.id,
      dayIndex: day.dayIndex,
      label: label,
      exercises: [
        for (var i = 0; i < kept.length; i++)
          WorkoutExercise(
            id: kept[i].id.isEmpty ? _uuid.v4() : kept[i].id,
            catalogExerciseId: kept[i].catalogExerciseId,
            name: kept[i].name,
            primaryMuscle: kept[i].primaryMuscle,
            secondaryMuscles: kept[i].secondaryMuscles,
            equipment: kept[i].equipment,
            difficulty: kept[i].difficulty,
            isCompound: kept[i].isCompound,
            order: i,
            sets: kept[i].sets.isEmpty ? _defaultSets() : kept[i].sets,
            notes: kept[i].notes,
            selectionReasons: kept[i].selectionReasons,
          ),
      ],
      notes: day.notes,
    );
  }

  /// Practical gym order: keep muscle groups together; core/time last.
  static List<WorkoutExercise> _orderDayExercises(
    String label,
    List<WorkoutExercise> exercises,
  ) {
    final indexed = exercises.asMap().entries.toList(growable: false);
    indexed.sort((a, b) {
      final byGroup = _muscleGroupRank(label, a.value)
          .compareTo(_muscleGroupRank(label, b.value));
      if (byGroup != 0) return byGroup;

      final bySub = _muscleSubRank(a.value).compareTo(_muscleSubRank(b.value));
      if (bySub != 0) return bySub;

      final aTime = _isTimeFinisher(a.value);
      final bTime = _isTimeFinisher(b.value);
      if (aTime != bTime) return aTime ? 1 : -1;

      final aCompound = a.value.isCompound;
      final bCompound = b.value.isCompound;
      if (aCompound != bCompound) return aCompound ? -1 : 1;

      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList(growable: false);
  }

  static int _muscleGroupRank(String label, WorkoutExercise exercise) {
    final m = exercise.primaryMuscle.toLowerCase();
    if (_isCore(m) || _isTimeFinisher(exercise)) return 90;

    if (_isPushDay(label)) {
      if (_isChest(m)) return 10;
      if (_isShoulder(m)) return 20;
      if (_isTricep(m)) return 30;
      return 40;
    }
    if (_isPullDay(label)) {
      // Entire back family before arms — never interrupt with biceps.
      if (_isBackFamily(m)) return 10;
      if (_isBicep(m)) return 20;
      return 30;
    }
    if (_isLegDay(label)) {
      if (_isQuad(m)) return 10;
      if (_isHamstring(m)) return 20;
      if (_isGlute(m)) return 30;
      if (_isCalf(m)) return 40;
      return 50;
    }
    if (_isChest(m)) return 10;
    if (_isBackFamily(m)) return 20;
    if (_isQuad(m) || _isHamstring(m) || _isGlute(m)) return 30;
    if (_isShoulder(m)) return 40;
    if (_isBicep(m) || _isTricep(m)) return 50;
    if (_isCalf(m)) return 60;
    return 70;
  }

  /// Within the same group: lats before traps/lower-back; front delt before lateral.
  static int _muscleSubRank(WorkoutExercise exercise) {
    final m = exercise.primaryMuscle.toLowerCase();
    if (_isBackFamily(m)) {
      if (m.contains('lat') || m.contains('زیربغل')) return 1;
      if (m.contains('trap') || m.contains('کول')) return 2;
      if (m.contains('lower') || m.contains('کمر')) return 3;
      return 4;
    }
    if (_isShoulder(m)) {
      if (m.contains('anterior') || m.contains('جلو')) return 1;
      if (m.contains('lateral') || m.contains('جانب')) return 2;
      if (m.contains('posterior') || m.contains('خلف')) return 3;
      return 4;
    }
    return 0;
  }

  static bool _isTimeFinisher(WorkoutExercise exercise) {
    if (exercise.sets.isEmpty) return false;
    return exercise.sets.every((s) => s.type == WorkoutSetType.time);
  }

  static List<WorkoutExercise> _capPushVolume(
    String label,
    List<WorkoutExercise> exercises,
  ) {
    if (!_isPushDay(label)) return exercises;

    var chest = 0;
    var shoulder = 0;
    var presses = 0;
    final out = <WorkoutExercise>[];
    final deferred = <WorkoutExercise>[];

    for (final e in exercises) {
      final m = e.primaryMuscle.toLowerCase();
      final isChest = _isChest(m);
      final isShoulder = _isShoulder(m);
      final isTricep = _isTricep(m);
      final isCore = _isCore(m);

      if (isCore || isTricep) {
        deferred.add(e);
        continue;
      }

      if (isChest) {
        if (chest >= 2 || presses >= 3) continue;
        chest++;
        presses++;
        out.add(e);
        continue;
      }
      if (isShoulder) {
        if (shoulder >= 2 || presses >= 3) continue;
        shoulder++;
        presses++;
        out.add(e);
        continue;
      }
      out.add(e);
    }

    out.addAll(deferred);
    return out;
  }

  /// Validator rejects >3 quads on leg day — drop extras, keep posterior chain.
  static List<WorkoutExercise> _capLegQuads(
    String label,
    List<WorkoutExercise> exercises,
  ) {
    if (!_isLegDay(label)) return exercises;

    var quads = 0;
    final out = <WorkoutExercise>[];
    final deferred = <WorkoutExercise>[];

    for (final e in exercises) {
      final m = e.primaryMuscle.toLowerCase();
      if (_isQuad(m)) {
        if (quads >= 3) continue;
        quads++;
        out.add(e);
      } else {
        deferred.add(e);
      }
    }

    out.addAll(deferred);
    return out;
  }

  static List<WorkoutExercise> _fillDay({
    required String label,
    required List<WorkoutExercise> existing,
    required List<Exercise> curated,
    required Set<int> usedAcrossProgram,
    required int targetCount,
  }) {
    final out = List<WorkoutExercise>.from(existing);
    final have = out.map((e) => e.catalogExerciseId).toSet();

    final wantedMuscles = _wantedMusclesForDay(label, existing: out);
    final pool = List<Exercise>.from(curated)
      ..sort(
        (a, b) => LlmIranGymPopularity.score(b)
            .compareTo(LlmIranGymPopularity.score(a)),
      );

    for (final muscle in wantedMuscles) {
      if (out.length >= targetCount) break;
      for (final candidate in pool) {
        if (out.length >= targetCount) break;
        if (have.contains(candidate.id) ||
            usedAcrossProgram.contains(candidate.id)) {
          continue;
        }
        final m = candidate.mainMuscle.toLowerCase();
        if (!_muscleMatchesWanted(m, muscle)) continue;
        if (!_belongsOnDay(label, candidate.mainMuscle)) continue;
        if (!_fitsPushBudget(label, out, m)) continue;

        out.add(_fromCatalog(candidate, order: out.length));
        have.add(candidate.id);
      }
    }

    // Any remaining allowed muscle on this day.
    for (final candidate in pool) {
      if (out.length >= targetCount) break;
      if (have.contains(candidate.id) ||
          usedAcrossProgram.contains(candidate.id)) {
        continue;
      }
      if (!_belongsOnDay(label, candidate.mainMuscle)) continue;
      final m = candidate.mainMuscle.toLowerCase();
      if (!_fitsPushBudget(label, out, m)) continue;
      out.add(_fromCatalog(candidate, order: out.length));
      have.add(candidate.id);
    }

    return out;
  }

  static List<WorkoutExercise> _ensureMuscleOnDay({
    required String label,
    required List<WorkoutExercise> existing,
    required List<Exercise> curated,
    required Set<int> usedAcrossProgram,
    required String muscleKey,
    required int maxTotal,
  }) {
    if (existing.length >= maxTotal) return existing;
    final have = existing.map((e) => e.catalogExerciseId).toSet();
    final pool = List<Exercise>.from(curated)
      ..sort(
        (a, b) => LlmIranGymPopularity.score(b)
            .compareTo(LlmIranGymPopularity.score(a)),
      );
    for (final candidate in pool) {
      if (have.contains(candidate.id) ||
          usedAcrossProgram.contains(candidate.id)) {
        continue;
      }
      final m = candidate.mainMuscle.toLowerCase();
      if (!_muscleMatchesWanted(m, muscleKey)) continue;
      if (!_belongsOnDay(label, candidate.mainMuscle)) continue;
      return <WorkoutExercise>[
        ...existing,
        _fromCatalog(candidate, order: existing.length),
      ];
    }
    return existing;
  }

  static bool _fitsPushBudget(
    String label,
    List<WorkoutExercise> existing,
    String muscle,
  ) {
    if (_isPushDay(label)) {
      final chest = existing
          .where((e) => _isChest(e.primaryMuscle.toLowerCase()))
          .length;
      final shoulder = existing
          .where((e) => _isShoulder(e.primaryMuscle.toLowerCase()))
          .length;
      final presses = chest + shoulder;
      if (_isChest(muscle)) {
        return chest < 2 && presses < 3;
      }
      if (_isShoulder(muscle)) {
        return shoulder < 2 && presses < 3;
      }
      return true;
    }
    if (_isLegDay(label)) {
      final quads = existing
          .where((e) => _isQuad(e.primaryMuscle.toLowerCase()))
          .length;
      if (_isQuad(muscle)) return quads < 3;
      return true;
    }
    return true;
  }

  static WorkoutExercise _fromCatalog(Exercise exercise, {required int order}) {
    return WorkoutExercise(
      id: _uuid.v4(),
      catalogExerciseId: exercise.id,
      name: exercise.name,
      primaryMuscle: exercise.mainMuscle,
      secondaryMuscles: exercise.secondaryMuscles
          .split(RegExp('[,،/|]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false),
      equipment: exercise.equipment,
      difficulty: exercise.difficulty,
      order: order,
      sets: _defaultSets(),
    );
  }

  static List<WorkoutSet> _defaultSets() => List<WorkoutSet>.generate(
        3,
        (i) => WorkoutSet(
          id: _uuid.v4(),
          order: i,
          type: WorkoutSetType.reps,
          reps: i == 0 ? 12 : 10,
        ),
      );

  static List<String> _wantedMusclesForDay(
    String label, {
    List<WorkoutExercise> existing = const <WorkoutExercise>[],
  }) {
    if (_isPushDay(label)) {
      final hasTriceps = existing.any(
        (e) => _isTricep(e.primaryMuscle.toLowerCase()),
      );
      return hasTriceps
          ? const <String>['chest', 'shoulder', 'triceps', 'abs']
          : const <String>['triceps', 'chest', 'shoulder', 'abs'];
    }
    if (_isPullDay(label)) {
      return const <String>['back', 'biceps', 'abs'];
    }
    if (_isLegDay(label)) {
      final quads = existing
          .where((e) => _isQuad(e.primaryMuscle.toLowerCase()))
          .length;
      // Prefer posterior chain when already at/near quad cap.
      if (quads >= 2) {
        return const <String>['hamstrings', 'glutes', 'calves', 'abs', 'quads'];
      }
      return const <String>['quads', 'hamstrings', 'glutes', 'calves', 'abs'];
    }
    return const <String>['chest', 'back', 'quads', 'abs'];
  }

  static bool _muscleMatchesWanted(String muscle, String wanted) {
    switch (wanted) {
      case 'chest':
        return _isChest(muscle);
      case 'shoulder':
        return _isShoulder(muscle);
      case 'triceps':
        return _isTricep(muscle);
      case 'back':
        return _isBack(muscle);
      case 'biceps':
        return _isBicep(muscle);
      case 'quads':
        return _isQuad(muscle);
      case 'hamstrings':
        return _isHamstring(muscle);
      case 'glutes':
        return _isGlute(muscle);
      case 'calves':
        return _isCalf(muscle);
      case 'abs':
        return _isCore(muscle);
      default:
        return false;
    }
  }

  static bool _belongsOnDay(String label, String primaryMuscle) {
    final m = primaryMuscle.toLowerCase();
    if (_isPushDay(label)) return LlmWorkoutMuscleTags.isPushOk(m);
    if (_isPullDay(label)) return LlmWorkoutMuscleTags.isPullOk(m);
    if (_isLegDay(label)) return LlmWorkoutMuscleTags.isLegDayOk(m);
    return true;
  }

  static bool _isPushDay(String label) {
    final t = label.toLowerCase();
    return t.contains('فشار') || (t.contains('سینه') && !t.contains('پشت'));
  }

  static bool _isPullDay(String label) {
    final t = label.toLowerCase();
    if (t.contains('کشش') || t.contains('پول') || t.contains('pull')) {
      return true;
    }
    if (RegExp(r'پشت\s*بازو').hasMatch(t) || t.contains('پشت‌بازو')) {
      return false;
    }
    return t.contains('پشت') && !t.contains('پا');
  }

  static bool _isLegDay(String label) {
    final t = label.toLowerCase();
    return t.contains('پا') || t.contains('پایین') || t.contains('لگ');
  }

  static bool _isChest(String m) => LlmWorkoutMuscleTags.isChest(m);
  static bool _isShoulder(String m) => LlmWorkoutMuscleTags.isShoulder(m);
  static bool _isTricep(String m) => LlmWorkoutMuscleTags.isTricep(m);
  static bool _isBack(String m) => LlmWorkoutMuscleTags.isBack(m);
  static bool _isBicep(String m) => LlmWorkoutMuscleTags.isBicep(m);
  static bool _isQuad(String m) => LlmWorkoutMuscleTags.isQuad(m);
  static bool _isHamstring(String m) => LlmWorkoutMuscleTags.isHamstring(m);
  static bool _isGlute(String m) => LlmWorkoutMuscleTags.isGlute(m);
  static bool _isCalf(String m) => LlmWorkoutMuscleTags.isCalf(m);
  static bool _isCore(String m) => LlmWorkoutMuscleTags.isCore(m);
  static bool _isBackFamily(String m) => LlmWorkoutMuscleTags.isBack(m);
}
