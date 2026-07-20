import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart' as ai;
import 'package:gymaipro/ai/workout/models/workout_exercise.dart' as ai;
import 'package:gymaipro/ai/workout/models/workout_program.dart' as ai;
import 'package:gymaipro/ai/workout/models/workout_set.dart' as ai;
import 'package:gymaipro/ai/workout/models/workout_week.dart' as ai;
import 'package:gymaipro/features/product_experience/coach_resolved_program.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';
import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart'
    as stored;
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';

typedef CoachStoredProgramLoader =
    Future<stored.WorkoutProgram?> Function(String programId);

/// Resolves the user's real active workout program for Coach product surfaces.
class CoachProgramResolver {
  CoachProgramResolver({
    CoachStoredProgramLoader? programLoader,
    ActiveProgramService? activeProgramService,
    ExerciseService? exerciseService,
  }) : _programLoader =
           programLoader ??
           ((id) => WorkoutProgramService().getProgramById(id)),
       _activeProgramService = activeProgramService ?? ActiveProgramService(),
       _exerciseServiceOrCreate = exerciseService;

  final CoachStoredProgramLoader _programLoader;
  final ActiveProgramService _activeProgramService;
  final ExerciseService? _exerciseServiceOrCreate;
  ExerciseService? _exerciseServiceCache;

  ExerciseService get _exerciseService =>
      _exerciseServiceCache ??=
          _exerciseServiceOrCreate ?? ExerciseService();

  Future<CoachResolvedTodayWorkout?> resolve({
    required CoachIntegrationResult result,
  }) async {
    final catalogById = await _loadCatalogById();

    final skillData =
        result.skillExecutionResult?.response.structuredData ??
        const <String, Object?>{};
    final programJson = skillData['workoutProgram'];
    if (programJson is Map<String, Object?>) {
      final program = ai.WorkoutProgram.fromJson(programJson);
      return _fromAiProgram(program, result.coachContext, catalogById);
    }

    final activeProgram =
        (skillData['program'] as Map<String, Object?>?) ??
        result.coachContext.activeProgram;
    if (activeProgram != null && activeProgram.isNotEmpty) {
      final fromMap = _fromActiveProgramMap(
        activeProgram,
        result.coachContext,
        catalogById,
      );
      if (fromMap != null) return fromMap;
    }

    final programId = await _resolveProgramId(result.coachContext);
    if (programId == null || programId.isEmpty) return null;

    final storedProgram = await _programLoader(programId);
    if (storedProgram == null) return null;

    return _fromStoredProgram(storedProgram, catalogById);
  }

  /// Resolves a stored program for an explicit session day (no auto-guess).
  Future<CoachResolvedTodayWorkout?> resolveStoredProgram(
    String programId, {
    required String sessionDay,
  }) async {
    if (programId.trim().isEmpty || sessionDay.trim().isEmpty) return null;
    final catalogById = await _loadCatalogById();
    final storedProgram = await _programLoader(programId);
    if (storedProgram == null) return null;
    final session = _findSessionByDay(storedProgram.sessions, sessionDay);
    if (session == null) return null;
    return _fromStoredProgramSession(storedProgram, session, catalogById);
  }

  stored.WorkoutSession? _findSessionByDay(
    List<stored.WorkoutSession> sessions,
    String sessionDay,
  ) {
    for (final session in sessions) {
      if (session.day == sessionDay && session.exercises.isNotEmpty) {
        return session;
      }
    }
    return null;
  }

  Future<Map<int, Exercise>> _loadCatalogById() async {
    try {
      final catalog = await _exerciseService.getExercises();
      return {for (final exercise in catalog) exercise.id: exercise};
    } on Object {
      return const <int, Exercise>{};
    }
  }

  String _resolveExerciseName({
    required String rawName,
    required int? exerciseId,
    required Map<int, Exercise> catalogById,
  }) {
    final id = exerciseId ?? 0;
    if (id > 0) {
      final fromCatalog = _catalogLabel(catalogById[id]);
      if (fromCatalog.isNotEmpty) return fromCatalog;
    }

    return ProductExperienceFormatter.displayExerciseName(
      name: rawName,
      exerciseId: id > 0 ? id : null,
    );
  }

  String _catalogLabel(Exercise? catalog) {
    if (catalog == null) return '';
    final name = catalog.name.trim();
    if (name.isNotEmpty) return name;
    return catalog.title.trim();
  }

  String _resolvePrimaryMuscle({
    required Map<int, Exercise> catalogById,
    int? exerciseId,
    String? rawMuscle,
    String? tag,
  }) {
    if (exerciseId != null && exerciseId > 0) {
      final fromCatalog = _catalogMuscle(catalogById[exerciseId]);
      if (fromCatalog.isNotEmpty) return fromCatalog;
    }

    final localizedRaw = _localizeMuscle(rawMuscle);
    if (localizedRaw.isNotEmpty) return localizedRaw;

    return _localizeMuscle(tag);
  }

  String _catalogMuscle(Exercise? catalog) {
    if (catalog == null) return '';
    final main = catalog.mainMuscle.trim();
    if (main.isNotEmpty) return _localizeMuscle(main);
    return _localizeMuscle(catalog.targetArea);
  }

  String _localizeMuscle(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    return ExerciseDisplayLabels.musclesCsv(raw.trim());
  }

  Future<String?> _resolveProgramId(CoachContext context) async {
    final fromContext = context.activeProgram?['active_program_id']?.toString();
    if (fromContext != null && fromContext.isNotEmpty) return fromContext;
    try {
      final state = await _activeProgramService.getActiveProgramState();
      return state?['active_program_id']?.toString();
    } on Object {
      return null;
    }
  }

  CoachResolvedTodayWorkout? _fromActiveProgramMap(
    Map<String, Object?> active,
    CoachContext context,
    Map<int, Exercise> catalogById,
  ) {
    final rawExercises =
        (active['exercises'] as List<Object?>?) ??
        (active['todayExercises'] as List<Object?>?) ??
        const <Object?>[];
    final exercises = rawExercises
        .whereType<Map<String, Object?>>()
        .map((item) => _exerciseFromMap(item, catalogById))
        .where((exercise) => exercise.name.isNotEmpty)
        .toList(growable: false);
    if (exercises.isEmpty) return null;

    final muscles = exercises
        .map((exercise) => exercise.primaryMuscle)
        .where((muscle) => muscle.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    final focus =
        active['focus']?.toString() ??
        active['todayFocus']?.toString() ??
        active['split']?.toString() ??
        _focusFromMuscles(muscles);

    return CoachResolvedTodayWorkout(
      title: active['name']?.toString() ?? 'تمرین امروز',
      focus: focus,
      sessionLabel: active['headline']?.toString() ?? focus,
      durationMinutes: _readInt(
        active['durationMinutes'] ?? active['sessionDurationMinutes'],
        fallback: _estimateDuration(exercises),
      ),
      exercises: exercises,
      muscleGroups: muscles,
      intensity: active['intensity']?.toString() ?? 'متوسط',
    );
  }

  CoachResolvedTodayWorkout _fromAiProgram(
    ai.WorkoutProgram program,
    CoachContext context,
    Map<int, Exercise> catalogById,
  ) {
    final day = program.allDays.firstOrNull;
    final exercises = day == null
        ? const <CoachResolvedExercise>[]
        : day.exercises
              .map((exercise) => _exerciseFromAi(exercise, catalogById))
              .where((exercise) => exercise.name.isNotEmpty)
              .toList(growable: false);
    final muscles = exercises
        .map((exercise) => exercise.primaryMuscle)
        .where((muscle) => muscle.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return CoachResolvedTodayWorkout(
      title: program.name.isEmpty ? 'تمرین امروز' : program.name,
      focus: day?.label.isNotEmpty == true
          ? day!.label
          : _focusFromMuscles(muscles),
      sessionLabel: day?.label ?? 'جلسه امروز',
      durationMinutes:
          program.sessionDurationMinutes ?? _estimateDuration(exercises),
      exercises: exercises,
      muscleGroups: muscles,
      intensity: _intensityFromGoal(program.goal),
      aiProgram: program,
    );
  }

  CoachResolvedTodayWorkout? _fromStoredProgram(
    stored.WorkoutProgram program,
    Map<int, Exercise> catalogById,
  ) {
    final session = _pickTodaySession(program.sessions);
    if (session == null) return null;
    return _fromStoredProgramSession(program, session, catalogById);
  }

  CoachResolvedTodayWorkout? _fromStoredProgramSession(
    stored.WorkoutProgram program,
    stored.WorkoutSession session,
    Map<int, Exercise> catalogById,
  ) {
    final exercises = <CoachResolvedExercise>[];
    var order = 0;
    for (final block in session.exercises) {
      if (block is stored.NormalExercise) {
        final catalog = catalogById[block.exerciseId];
        exercises.add(
          _exerciseFromStoredNormal(
            block,
            catalog,
            catalogById,
            order: order++,
          ),
        );
      } else if (block is stored.SupersetExercise) {
        for (final item in block.exercises) {
          final catalog = catalogById[item.exerciseId];
          exercises.add(
            _exerciseFromStoredSupersetItem(
              item,
              catalog,
              catalogById,
              block.note,
              order: order++,
            ),
          );
        }
      }
    }
    if (exercises.isEmpty) return null;

    final muscles = exercises
        .map((exercise) => exercise.primaryMuscle)
        .where((muscle) => muscle.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final aiProgram = _toAiProgram(program, session, catalogById);

    return CoachResolvedTodayWorkout(
      title: program.name,
      focus: session.day,
      sessionLabel: session.day,
      durationMinutes: _estimateDuration(exercises),
      exercises: exercises,
      muscleGroups: muscles,
      intensity: 'متوسط',
      aiProgram: aiProgram,
    );
  }

  stored.WorkoutSession? _pickTodaySession(List<stored.WorkoutSession> sessions) {
    final usable = sessions
        .where((session) => session.exercises.isNotEmpty)
        .toList(growable: false);
    if (usable.isEmpty) return null;
    final index = DateTime.now().weekday % usable.length;
    return usable[index];
  }

  ai.WorkoutProgram _toAiProgram(
    stored.WorkoutProgram program,
    stored.WorkoutSession session,
    Map<int, Exercise> catalogById,
  ) {
    final exercises = <ai.WorkoutExercise>[];
    var order = 0;
    for (final block in session.exercises) {
      if (block is stored.NormalExercise) {
        final catalog = catalogById[block.exerciseId];
        exercises.add(
          _aiExerciseFromStoredNormal(block, catalog, catalogById, order++),
        );
      } else if (block is stored.SupersetExercise) {
        for (final item in block.exercises) {
          final catalog = catalogById[item.exerciseId];
          exercises.add(
            _aiExerciseFromStoredSuperset(item, catalog, catalogById, order++),
          );
        }
      }
    }

    return ai.WorkoutProgram(
      id: program.id,
      userId: program.userId,
      name: program.name,
      goal: TrainingGoal.general,
      experienceLevel: 'متوسط',
      daysPerWeek: program.sessions.length.clamp(1, 7),
      sessionDurationMinutes: _estimateDuration(
        exercises
            .map(
              (exercise) => CoachResolvedExercise(
                name: exercise.name,
                primaryMuscle: exercise.primaryMuscle,
                sets: exercise.sets.length,
                reps: exercise.sets.firstOrNull?.reps ?? 0,
              ),
            )
            .toList(growable: false),
      ),
      weeks: <ai.WorkoutWeek>[
        ai.WorkoutWeek(
          id: '${program.id}_week_1',
          weekIndex: 1,
          days: <ai.WorkoutDay>[
            ai.WorkoutDay(
              id: session.id,
              dayIndex: 1,
              label: session.day,
              exercises: exercises,
            ),
          ],
        ),
      ],
      createdAt: program.createdAt,
      updatedAt: program.updatedAt,
    );
  }

  CoachResolvedExercise _exerciseFromMap(
    Map<String, Object?> item,
    Map<int, Exercise> catalogById,
  ) {
    final rawSets = item['sets'];
    final setCount = rawSets is List<Object?>
        ? rawSets.whereType<Map<String, Object?>>().length
        : _readInt(rawSets, fallback: 1);
    final reps = _readInt(item['reps'], fallback: 0);
    final exerciseId = _readInt(
      item['exerciseId'] ?? item['catalogExerciseId'],
    );
    return CoachResolvedExercise(
      exerciseId: exerciseId == 0 ? null : exerciseId,
      name: _resolveExerciseName(
        rawName:
            item['name']?.toString() ??
            item['title']?.toString() ??
            item['exerciseName']?.toString() ??
            '',
        exerciseId: exerciseId == 0 ? null : exerciseId,
        catalogById: catalogById,
      ),
      primaryMuscle: _resolvePrimaryMuscle(
        exerciseId: exerciseId == 0 ? null : exerciseId,
        rawMuscle:
            item['primaryMuscle']?.toString() ??
            item['mainMuscle']?.toString(),
        tag: item['tag']?.toString(),
        catalogById: catalogById,
      ),
      sets: setCount == 0 ? 1 : setCount,
      reps: reps,
      restSeconds: _readInt(item['restSeconds'], fallback: 0) == 0
          ? null
          : _readInt(item['restSeconds']),
      tempo: item['tempo']?.toString(),
      notes: item['notes']?.toString() ?? item['note']?.toString(),
      weightKg: _readDouble(item['weightKg'] ?? item['weight']),
    );
  }

  CoachResolvedExercise _exerciseFromAi(
    ai.WorkoutExercise exercise,
    Map<int, Exercise> catalogById,
  ) {
    final firstSet = exercise.sets.firstOrNull;
    final catalogId =
        exercise.catalogExerciseId == 0 ? null : exercise.catalogExerciseId;
    return CoachResolvedExercise(
      exerciseId: catalogId,
      name: _resolveExerciseName(
        rawName: exercise.name,
        exerciseId: catalogId,
        catalogById: catalogById,
      ),
      primaryMuscle: _resolvePrimaryMuscle(
        exerciseId: catalogId,
        rawMuscle: exercise.primaryMuscle,
        catalogById: catalogById,
      ),
      sets: exercise.sets.length,
      reps: firstSet?.reps ?? 0,
      restSeconds: firstSet?.rir == null ? 90 : null,
      notes: exercise.notes.firstOrNull?.text,
      weightKg: firstSet?.weightKg,
    );
  }

  CoachResolvedExercise _exerciseFromStoredNormal(
    stored.NormalExercise exercise,
    Exercise? catalog,
    Map<int, Exercise> catalogById, {
    required int order,
  }) {
    final firstSet = exercise.sets.firstOrNull;
    return CoachResolvedExercise(
      exerciseId: exercise.exerciseId,
      name: _resolveExerciseName(
        rawName: catalog?.name ?? catalog?.title ?? '',
        exerciseId: exercise.exerciseId,
        catalogById: catalogById,
      ),
      primaryMuscle: _resolvePrimaryMuscle(
        exerciseId: exercise.exerciseId,
        tag: exercise.tag,
        catalogById: catalogById,
      ),
      sets: exercise.sets.length,
      reps: firstSet?.reps ?? firstSet?.timeSeconds ?? 0,
      restSeconds: 90,
      notes: exercise.note,
      weightKg: firstSet?.weight,
    );
  }

  CoachResolvedExercise _exerciseFromStoredSupersetItem(
    stored.SupersetItem item,
    Exercise? catalog,
    Map<int, Exercise> catalogById,
    String? blockNote, {
    required int order,
  }) {
    final firstSet = item.sets.firstOrNull;
    return CoachResolvedExercise(
      exerciseId: item.exerciseId,
      name: _resolveExerciseName(
        rawName: catalog?.name ?? catalog?.title ?? '',
        exerciseId: item.exerciseId,
        catalogById: catalogById,
      ),
      primaryMuscle: _resolvePrimaryMuscle(
        exerciseId: item.exerciseId,
        catalogById: catalogById,
      ),
      sets: item.sets.length,
      reps: firstSet?.reps ?? firstSet?.timeSeconds ?? 0,
      restSeconds: 90,
      notes: blockNote,
      weightKg: firstSet?.weight,
    );
  }

  ai.WorkoutExercise _aiExerciseFromStoredNormal(
    stored.NormalExercise exercise,
    Exercise? catalog,
    Map<int, Exercise> catalogById,
    int order,
  ) {
    return ai.WorkoutExercise(
      id: exercise.id,
      catalogExerciseId: exercise.exerciseId,
      name: _resolveExerciseName(
        rawName: catalog?.name ?? catalog?.title ?? '',
        exerciseId: exercise.exerciseId,
        catalogById: catalogById,
      ),
      primaryMuscle: _resolvePrimaryMuscle(
        exerciseId: exercise.exerciseId,
        tag: exercise.tag,
        catalogById: catalogById,
      ),
      order: order,
      sets: exercise.sets
          .asMap()
          .entries
          .map(
            (entry) => ai.WorkoutSet(
              id: '${exercise.id}_set_${entry.key + 1}',
              order: entry.key + 1,
              type: entry.value.timeSeconds != null
                  ? ai.WorkoutSetType.time
                  : ai.WorkoutSetType.reps,
              reps: entry.value.reps,
              timeSeconds: entry.value.timeSeconds,
              weightKg: entry.value.weight,
            ),
          )
          .toList(growable: false),
    );
  }

  ai.WorkoutExercise _aiExerciseFromStoredSuperset(
    stored.SupersetItem item,
    Exercise? catalog,
    Map<int, Exercise> catalogById,
    int order,
  ) {
    return ai.WorkoutExercise(
      id: '${item.exerciseId}_$order',
      catalogExerciseId: item.exerciseId,
      name: _resolveExerciseName(
        rawName: catalog?.name ?? catalog?.title ?? '',
        exerciseId: item.exerciseId,
        catalogById: catalogById,
      ),
      primaryMuscle: _resolvePrimaryMuscle(
        exerciseId: item.exerciseId,
        catalogById: catalogById,
      ),
      order: order,
      sets: item.sets
          .asMap()
          .entries
          .map(
            (entry) => ai.WorkoutSet(
              id: 'set_${item.exerciseId}_${entry.key + 1}',
              order: entry.key + 1,
              type: entry.value.timeSeconds != null
                  ? ai.WorkoutSetType.time
                  : ai.WorkoutSetType.reps,
              reps: entry.value.reps,
              timeSeconds: entry.value.timeSeconds,
              weightKg: entry.value.weight,
            ),
          )
          .toList(growable: false),
    );
  }

  String _focusFromMuscles(List<String> muscles) {
    if (muscles.isEmpty) return 'تمرین امروز';
    return muscles.take(2).join(' + ');
  }

  String _intensityFromGoal(TrainingGoal goal) {
    return switch (goal) {
      TrainingGoal.strength => 'سنگین',
      TrainingGoal.endurance => 'سبک تا متوسط',
      _ => 'متوسط',
    };
  }

  int _estimateDuration(List<CoachResolvedExercise> exercises) {
    if (exercises.isEmpty) return 0;
    final minutes = exercises.fold<int>(
      0,
      (sum, exercise) => sum + (exercise.sets * 3),
    );
    return minutes.clamp(20, 120);
  }

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
