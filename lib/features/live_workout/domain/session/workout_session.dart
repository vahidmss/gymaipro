import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';

/// Typed runtime session for live workout logging (EPIC 34).
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.title,
    required this.focus,
    required this.estimatedMinutes,
    required this.exercises,
    required this.startedAt,
    this.programId,
    this.userId,
  });

  final String id;
  final String title;
  final String focus;
  final int estimatedMinutes;
  final List<WorkoutExerciseSession> exercises;
  final DateTime startedAt;
  final String? programId;
  final String? userId;

  int get totalExercises => exercises.length;

  int get totalSets =>
      exercises.fold<int>(0, (sum, exercise) => sum + exercise.sets.length);

  int get completedSets => exercises.fold<int>(
    0,
    (sum, exercise) => sum + exercise.completedSets,
  );

  int get finishedExercises =>
      exercises.where((exercise) => exercise.isCompleted).length;

  bool get isCompleted =>
      exercises.isNotEmpty && finishedExercises == exercises.length;

  ({int exerciseIndex, int setIndex})? get currentSetPointer {
    for (var exerciseIndex = 0; exerciseIndex < exercises.length; exerciseIndex++) {
      final exercise = exercises[exerciseIndex];
      for (var setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
        if (exercise.sets[setIndex].status ==
            WorkoutSetSessionStatus.current) {
          return (exerciseIndex: exerciseIndex, setIndex: setIndex);
        }
      }
    }
    return null;
  }

  WorkoutExerciseSession? exerciseAt(int index) {
    if (index < 0 || index >= exercises.length) return null;
    return exercises[index];
  }

  WorkoutSetSession? currentSet() {
    final pointer = currentSetPointer;
    if (pointer == null) return null;
    return exercises[pointer.exerciseIndex].sets[pointer.setIndex];
  }

  WorkoutSession withCurrentPointer({
    required int exerciseIndex,
    required int setIndex,
  }) {
    if (exercises.isEmpty) return this;

    final targetExercise = exerciseIndex.clamp(0, exercises.length - 1);
    final exercise = exercises[targetExercise];
    if (exercise.sets.isEmpty) return this;

    final targetSet = setIndex.clamp(0, exercise.sets.length - 1);
    final updatedExercises = <WorkoutExerciseSession>[];

    for (var ei = 0; ei < exercises.length; ei++) {
      final currentExercise = exercises[ei];
      final updatedSets = <WorkoutSetSession>[];
      for (var si = 0; si < currentExercise.sets.length; si++) {
        final set = currentExercise.sets[si];
        if (set.status.isTerminal) {
          updatedSets.add(set);
          continue;
        }
        if (ei == targetExercise && si == targetSet) {
          updatedSets.add(
            set.copyWith(status: WorkoutSetSessionStatus.current),
          );
        } else {
          updatedSets.add(
            set.copyWith(status: WorkoutSetSessionStatus.pending),
          );
        }
      }
      updatedExercises.add(currentExercise.copyWith(sets: updatedSets));
    }

    return copyWith(exercises: updatedExercises);
  }

  WorkoutSession initializeCurrentSet() {
    if (isCompleted) return this;
    for (var exerciseIndex = 0; exerciseIndex < exercises.length; exerciseIndex++) {
      final exercise = exercises[exerciseIndex];
      for (var setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
        final set = exercise.sets[setIndex];
        if (!set.status.isTerminal) {
          return withCurrentPointer(
            exerciseIndex: exerciseIndex,
            setIndex: setIndex,
          );
        }
      }
    }
    return this;
  }

  WorkoutSession updateSet({
    required int exerciseIndex,
    required int setIndex,
    int? actualReps,
    double? actualWeightKg,
    int? rpe,
    int? durationSeconds,
    String? notes,
    WorkoutSetSessionStatus? status,
    bool clearNotes = false,
  }) {
    final exercise = exerciseAt(exerciseIndex);
    if (exercise == null || setIndex < 0 || setIndex >= exercise.sets.length) {
      return this;
    }

    final updatedSets = List<WorkoutSetSession>.from(exercise.sets);
    updatedSets[setIndex] = updatedSets[setIndex].copyWith(
      actualReps: actualReps,
      actualWeightKg: actualWeightKg,
      rpe: rpe,
      durationSeconds: durationSeconds,
      notes: notes,
      status: status,
      clearNotes: clearNotes,
    );

    final updatedExercises = List<WorkoutExerciseSession>.from(exercises);
    updatedExercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);
    return copyWith(exercises: updatedExercises);
  }

  WorkoutSession advanceAfterSet({
    required int exerciseIndex,
    required int setIndex,
    required WorkoutSetSessionStatus terminalStatus,
  }) {
    var updated = updateSet(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      status: terminalStatus,
    );

    final exercise = updated.exerciseAt(exerciseIndex);
    if (exercise == null) return updated;

    if (setIndex + 1 < exercise.sets.length) {
      return updated.withCurrentPointer(
        exerciseIndex: exerciseIndex,
        setIndex: setIndex + 1,
      );
    }

    if (exerciseIndex + 1 < updated.exercises.length) {
      return updated.withCurrentPointer(
        exerciseIndex: exerciseIndex + 1,
        setIndex: 0,
      );
    }

    return updated;
  }

  int? nextExerciseIndex(int currentExerciseIndex) {
    final next = currentExerciseIndex + 1;
    if (next >= exercises.length) return null;
    return next;
  }

  WorkoutSession copyWith({
    String? title,
    String? focus,
    int? estimatedMinutes,
    List<WorkoutExerciseSession>? exercises,
    DateTime? startedAt,
    String? programId,
    String? userId,
  }) {
    return WorkoutSession(
      id: id,
      title: title ?? this.title,
      focus: focus ?? this.focus,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      exercises: exercises ?? this.exercises,
      startedAt: startedAt ?? this.startedAt,
      programId: programId ?? this.programId,
      userId: userId ?? this.userId,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'focus': focus,
      'estimatedMinutes': estimatedMinutes,
      'startedAt': startedAt.toIso8601String(),
      'programId': programId,
      'userId': userId,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }

  factory WorkoutSession.fromJson(Map<String, Object?> json) {
    final rawExercises = json['exercises'];
    return WorkoutSession(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      focus: json['focus']?.toString() ?? '',
      estimatedMinutes:
          int.tryParse(json['estimatedMinutes']?.toString() ?? '') ?? 0,
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      programId: json['programId']?.toString(),
      userId: json['userId']?.toString(),
      exercises: rawExercises is List<Object?>
          ? rawExercises
                .whereType<Map<String, Object?>>()
                .map(WorkoutExerciseSession.fromJson)
                .toList(growable: false)
          : const <WorkoutExerciseSession>[],
    );
  }
}
