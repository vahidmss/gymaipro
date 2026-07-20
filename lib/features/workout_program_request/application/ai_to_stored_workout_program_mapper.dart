import 'package:gymaipro/ai/workout/labels/workout_session_labels.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart' as ai;
import 'package:gymaipro/ai/workout/models/workout_exercise.dart' as ai;
import 'package:gymaipro/ai/workout/models/workout_program.dart' as ai;
import 'package:gymaipro/ai/workout/models/workout_set.dart' as ai;
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart'
    as stored;
import 'package:uuid/uuid.dart';

/// Maps Coach-generated AI [ai.WorkoutProgram] → persisted builder model.
class AiToStoredWorkoutProgramMapper {
  const AiToStoredWorkoutProgramMapper();

  stored.WorkoutProgram map(
    ai.WorkoutProgram program, {
    String? userId,
    String? trainerId,
  }) {
    final days = program.allDays
        .where((day) => day.exercises.any((e) => e.catalogExerciseId > 0))
        .toList(growable: false);
    final uniqueLabels = WorkoutSessionLabels.normalizeParsed(
      days
          .map(
            (day) => day.label.isEmpty
                ? 'روز ${day.dayIndex + 1}'
                : day.label,
          )
          .toList(growable: false),
    );

    final sessions = <stored.WorkoutSession>[
      for (var i = 0; i < days.length; i++)
        _mapDay(days[i], label: uniqueLabels[i]),
    ];

    return stored.WorkoutProgram(
      id: const Uuid().v4(),
      name: program.name.isEmpty ? 'برنامه تمرینی جیم‌آی' : program.name,
      sessions: sessions,
      userId: userId ?? program.userId,
      trainerId: trainerId,
      isSelfServiceAi: true,
      createdAt: program.createdAt,
      updatedAt: program.updatedAt,
    );
  }

  stored.WorkoutSession _mapDay(ai.WorkoutDay day, {required String label}) {
    final exercises = day.exercises
        .where((exercise) => exercise.catalogExerciseId > 0)
        .map(_mapExercise)
        .toList(growable: false);

    return stored.WorkoutSession(
      id: day.id.isEmpty ? const Uuid().v4() : day.id,
      day: label,
      exercises: exercises,
    );
  }

  stored.NormalExercise _mapExercise(ai.WorkoutExercise exercise) {
    final style = exercise.sets.any((set) => set.type == ai.WorkoutSetType.time)
        ? stored.ExerciseStyle.setsTime
        : stored.ExerciseStyle.setsReps;

    final sets = exercise.sets.isEmpty
        ? <stored.ExerciseSet>[
            stored.ExerciseSet(reps: 10),
            stored.ExerciseSet(reps: 10),
            stored.ExerciseSet(reps: 10),
          ]
        : exercise.sets.map(_mapSet).toList(growable: false);

    return stored.NormalExercise(
      exerciseId: exercise.catalogExerciseId,
      tag: exercise.primaryMuscle,
      style: style,
      sets: sets,
    );
  }

  stored.ExerciseSet _mapSet(ai.WorkoutSet set) {
    return stored.ExerciseSet(
      reps: set.reps,
      timeSeconds: set.timeSeconds,
      weight: set.weightKg,
    );
  }
}
