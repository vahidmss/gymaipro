import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/ai/workout/models/workout_week.dart';

/// Deep-clone and mutation helpers for workout programs.
class WorkoutProgramMutator {
  const WorkoutProgramMutator();

  WorkoutProgram clone(WorkoutProgram program) {
    return WorkoutProgram.fromJson(program.toJson());
  }

  WorkoutProgram withUpdatedAt(WorkoutProgram program) {
    return WorkoutProgram(
      id: program.id,
      userId: program.userId,
      name: program.name,
      version: program.version + 1,
      status: program.status,
      source: program.source,
      goal: program.goal,
      experienceLevel: program.experienceLevel,
      daysPerWeek: program.daysPerWeek,
      sessionDurationMinutes: program.sessionDurationMinutes,
      weeks: program.weeks,
      programReasons: program.programReasons,
      createdAt: program.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  WorkoutProgram replaceExercise({
    required WorkoutProgram program,
    required String exerciseId,
    required ExerciseProfile replacement,
  }) {
    return _mapExercises(
      program,
      (exercise) {
        if (exercise.id != exerciseId) return exercise;
        return _exerciseFromProfile(
          original: exercise,
          profile: replacement,
        );
      },
    );
  }

  WorkoutProgram removeExercise({
    required WorkoutProgram program,
    required String exerciseId,
  }) {
    final weeks = program.weeks
        .map(
          (week) => WorkoutWeek(
            id: week.id,
            weekIndex: week.weekIndex,
            days: week.days
                .map(
                  (day) => WorkoutDay(
                    id: day.id,
                    dayIndex: day.dayIndex,
                    label: day.label,
                    exercises: day.exercises
                        .where((exercise) => exercise.id != exerciseId)
                        .toList(),
                    notes: day.notes,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
    return _rebuild(program, weeks);
  }

  WorkoutProgram addExercise({
    required WorkoutProgram program,
    required String dayId,
    required ExerciseProfile profile,
    int sets = 3,
    int reps = 12,
  }) {
    return _mapDays(
      program,
      (day) {
        if (day.id != dayId) return day;
        final order = day.exercises.length;
        final exercise = WorkoutExercise(
          id: 'added-$order-${profile.id}',
          catalogExerciseId: profile.id,
          name: profile.canonicalName,
          primaryMuscle: profile.primaryMuscles.isNotEmpty
              ? profile.primaryMuscles.first
              : '',
          secondaryMuscles: profile.secondaryMuscles,
          equipment: profile.equipment
              .map((item) => item.name)
              .join(', '),
          difficulty: profile.difficulty.name,
          isCompound: profile.compound,
          order: order,
          sets: List<WorkoutSet>.generate(
            sets,
            (index) => WorkoutSet(
              id: 'set-added-$order-$index',
              order: index,
              type: WorkoutSetType.reps,
              reps: reps,
            ),
          ),
        );
        return WorkoutDay(
          id: day.id,
          dayIndex: day.dayIndex,
          label: day.label,
          exercises: <WorkoutExercise>[...day.exercises, exercise],
          notes: day.notes,
        );
      },
    );
  }

  WorkoutProgram adjustVolume({
    required WorkoutProgram program,
    required int deltaSets,
  }) {
    return _mapExercises(program, (exercise) {
      if (deltaSets == 0) return exercise;
      final sets = List<WorkoutSet>.from(exercise.sets);
      if (deltaSets > 0) {
        final last = sets.isNotEmpty ? sets.last : null;
        final reps = last?.reps ?? 10;
        for (var i = 0; i < deltaSets; i++) {
          sets.add(
            WorkoutSet(
              id: '${exercise.id}-extra-${sets.length}',
              order: sets.length,
              type: WorkoutSetType.reps,
              reps: reps,
            ),
          );
        }
      } else if (sets.length > 1) {
        sets.removeLast();
      }
      return WorkoutExercise(
        id: exercise.id,
        catalogExerciseId: exercise.catalogExerciseId,
        name: exercise.name,
        primaryMuscle: exercise.primaryMuscle,
        secondaryMuscles: exercise.secondaryMuscles,
        equipment: exercise.equipment,
        difficulty: exercise.difficulty,
        isCompound: exercise.isCompound,
        order: exercise.order,
        sets: sets,
        notes: exercise.notes,
        selectionReasons: exercise.selectionReasons,
      );
    });
  }

  WorkoutProgram adjustIntensity({
    required WorkoutProgram program,
    required int repDelta,
  }) {
    return _mapExercises(program, (exercise) {
      final sets = exercise.sets
          .map(
            (set) => WorkoutSet(
              id: set.id,
              order: set.order,
              type: set.type,
              reps: set.reps == null
                  ? null
                  : (set.reps! + repDelta).clamp(1, 30),
              timeSeconds: set.timeSeconds,
              weightKg: set.weightKg,
              rir: set.rir,
              progression: set.progression,
            ),
          )
          .toList();
      return WorkoutExercise(
        id: exercise.id,
        catalogExerciseId: exercise.catalogExerciseId,
        name: exercise.name,
        primaryMuscle: exercise.primaryMuscle,
        secondaryMuscles: exercise.secondaryMuscles,
        equipment: exercise.equipment,
        difficulty: exercise.difficulty,
        isCompound: exercise.isCompound,
        order: exercise.order,
        sets: sets,
        notes: exercise.notes,
        selectionReasons: exercise.selectionReasons,
      );
    });
  }

  WorkoutProgram shortenSessions({
    required WorkoutProgram program,
    int removeExercisesPerDay = 1,
  }) {
    final weeks = program.weeks
        .map(
          (week) => WorkoutWeek(
            id: week.id,
            weekIndex: week.weekIndex,
            days: week.days
                .map(
                  (day) {
                    if (day.exercises.length <= 2) return day;
                    final sorted = List<WorkoutExercise>.from(day.exercises)
                      ..sort((a, b) => b.order.compareTo(a.order));
                    final keep = sorted
                        .skip(removeExercisesPerDay)
                        .toList()
                      ..sort((a, b) => a.order.compareTo(b.order));
                    return WorkoutDay(
                      id: day.id,
                      dayIndex: day.dayIndex,
                      label: day.label,
                      exercises: keep,
                      notes: day.notes,
                    );
                  },
                )
                .toList(),
          ),
        )
        .toList();
    return _rebuild(program, weeks);
  }

  WorkoutExercise _exerciseFromProfile({
    required WorkoutExercise original,
    required ExerciseProfile profile,
  }) {
    return WorkoutExercise(
      id: original.id,
      catalogExerciseId: profile.id,
      name: profile.canonicalName,
      primaryMuscle: profile.primaryMuscles.isNotEmpty
          ? profile.primaryMuscles.first
          : original.primaryMuscle,
      secondaryMuscles: profile.secondaryMuscles,
      equipment: profile.equipment.map((item) => item.name).join(', '),
      difficulty: profile.difficulty.name,
      isCompound: profile.compound,
      order: original.order,
      sets: original.sets,
      notes: original.notes,
      selectionReasons: original.selectionReasons,
    );
  }

  WorkoutProgram _mapExercises(
    WorkoutProgram program,
    WorkoutExercise Function(WorkoutExercise exercise) transform,
  ) {
    final weeks = program.weeks
        .map(
          (week) => WorkoutWeek(
            id: week.id,
            weekIndex: week.weekIndex,
            days: week.days
                .map(
                  (day) => WorkoutDay(
                    id: day.id,
                    dayIndex: day.dayIndex,
                    label: day.label,
                    exercises: day.exercises.map(transform).toList(),
                    notes: day.notes,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
    return _rebuild(program, weeks);
  }

  WorkoutProgram _mapDays(
    WorkoutProgram program,
    WorkoutDay Function(WorkoutDay day) transform,
  ) {
    final weeks = program.weeks
        .map(
          (week) => WorkoutWeek(
            id: week.id,
            weekIndex: week.weekIndex,
            days: week.days.map(transform).toList(),
          ),
        )
        .toList();
    return _rebuild(program, weeks);
  }

  WorkoutProgram _rebuild(WorkoutProgram program, List<WorkoutWeek> weeks) {
    return WorkoutProgram(
      id: program.id,
      userId: program.userId,
      name: program.name,
      version: program.version,
      status: program.status,
      source: program.source,
      goal: program.goal,
      experienceLevel: program.experienceLevel,
      daysPerWeek: program.daysPerWeek,
      sessionDurationMinutes: program.sessionDurationMinutes,
      weeks: weeks,
      programReasons: program.programReasons,
      createdAt: program.createdAt,
      updatedAt: program.updatedAt,
    );
  }
}
