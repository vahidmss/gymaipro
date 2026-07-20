import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_completion_summary.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_rest_state.dart';

enum LiveWorkoutStatus { loading, loaded, empty, error, sessionCompleted, awaitingSession }

class LiveWorkoutState {
  const LiveWorkoutState({
    required this.status,
    this.session,
    this.userId,
    this.coachTips = const <String>[],
    this.explainability = const <String>[],
    this.readinessHint,
    this.rest = const LiveWorkoutRestState.idle(),
    this.completionSummary,
    this.errorMessage,
    this.activeProgram,
    this.sessionContext,
  });

  const LiveWorkoutState.loading()
    : status = LiveWorkoutStatus.loading,
      session = null,
      userId = null,
      coachTips = const <String>[],
      explainability = const <String>[],
      readinessHint = null,
      rest = const LiveWorkoutRestState.idle(),
      completionSummary = null,
      errorMessage = null,
      activeProgram = null,
      sessionContext = null;

  const LiveWorkoutState.empty()
    : status = LiveWorkoutStatus.empty,
      session = null,
      userId = null,
      coachTips = const <String>[],
      explainability = const <String>[],
      readinessHint = null,
      rest = const LiveWorkoutRestState.idle(),
      completionSummary = null,
      errorMessage = null,
      activeProgram = null,
      sessionContext = null;

  const LiveWorkoutState.awaitingSession({
    required this.activeProgram,
    required this.sessionContext,
  }) : status = LiveWorkoutStatus.awaitingSession,
       session = null,
       userId = null,
       coachTips = const <String>[],
       explainability = const <String>[],
       readinessHint = null,
       rest = const LiveWorkoutRestState.idle(),
       completionSummary = null,
       errorMessage = null;

  const LiveWorkoutState.error(String message)
    : status = LiveWorkoutStatus.error,
      session = null,
      userId = null,
      coachTips = const <String>[],
      explainability = const <String>[],
      readinessHint = null,
      rest = const LiveWorkoutRestState.idle(),
      completionSummary = null,
      errorMessage = message,
      activeProgram = null,
      sessionContext = null;

  const LiveWorkoutState.loaded({
    required WorkoutSession session,
    required String userId,
    this.coachTips = const <String>[],
    this.explainability = const <String>[],
    this.readinessHint,
    this.rest = const LiveWorkoutRestState.idle(),
    this.activeProgram,
    this.sessionContext,
    this.completionSummary,
  }) : status = LiveWorkoutStatus.loaded,
       session = session,
       userId = userId,
       errorMessage = null;

  const LiveWorkoutState.sessionCompleted({
    required LiveWorkoutCompletionSummary summary,
    List<String> coachTips = const <String>[],
    List<String> explainability = const <String>[],
  }) : status = LiveWorkoutStatus.sessionCompleted,
       session = null,
       userId = null,
       coachTips = coachTips,
       explainability = explainability,
       readinessHint = null,
       rest = const LiveWorkoutRestState.idle(),
       completionSummary = summary,
       errorMessage = null,
       activeProgram = null,
       sessionContext = null;

  final LiveWorkoutStatus status;
  final WorkoutSession? session;
  final String? userId;
  final List<String> coachTips;
  final List<String> explainability;
  final String? readinessHint;
  final LiveWorkoutRestState rest;
  final LiveWorkoutCompletionSummary? completionSummary;
  final String? errorMessage;
  final ActiveProgramOption? activeProgram;
  final ActiveWorkoutSessionContext? sessionContext;

  bool get isLoading => status == LiveWorkoutStatus.loading;
  bool get isLoaded => status == LiveWorkoutStatus.loaded;
  bool get isEmpty => status == LiveWorkoutStatus.empty;
  bool get isAwaitingSession => status == LiveWorkoutStatus.awaitingSession;
  bool get hasError => status == LiveWorkoutStatus.error;
  bool get isSessionCompleted => status == LiveWorkoutStatus.sessionCompleted;

  ({int exerciseIndex, int setIndex})? get currentPointer =>
      session?.currentSetPointer;

  WorkoutExerciseSession? get currentExercise {
    final pointer = currentPointer;
    if (pointer == null || session == null) return null;
    return session!.exerciseAt(pointer.exerciseIndex);
  }

  WorkoutSetSession? get currentSet => session?.currentSet();

  int? get currentExerciseIndex => currentPointer?.exerciseIndex;

  int get completedSets => session?.completedSets ?? 0;

  int get totalSets => session?.totalSets ?? 0;

  int get finishedExercises => session?.finishedExercises ?? 0;

  int get totalExercises => session?.totalExercises ?? 0;

  int? get nextExerciseIndex {
    final index = currentExerciseIndex;
    if (index == null || session == null) return null;
    return session!.nextExerciseIndex(index);
  }

  WorkoutExerciseSession? get upcomingExercise {
    final next = nextExerciseIndex;
    if (next == null || session == null) return null;
    return session!.exerciseAt(next);
  }

  bool get isLastExercise =>
      currentExerciseIndex != null &&
      session != null &&
      currentExerciseIndex! >= session!.exercises.length - 1;

  bool get currentExerciseCompleted {
    final exercise = currentExercise;
    if (exercise == null) return false;
    return exercise.sets.every((set) => set.status.isTerminal);
  }

  String get primaryButtonLabel {
    if (rest.active) return ProductCopy.skipRest;
    if (currentExerciseCompleted) return ProductCopy.nextExercise;
    return ProductCopy.completeSet;
  }

  bool isSetDone(int exerciseIndex, int setIndex) {
    final exercise = session?.exerciseAt(exerciseIndex);
    if (exercise == null || setIndex < 0 || setIndex >= exercise.sets.length) {
      return false;
    }
    final status = exercise.sets[setIndex].status;
    return status == WorkoutSetSessionStatus.completed ||
        status == WorkoutSetSessionStatus.skipped;
  }

  WorkoutSetSessionStatus statusForSet(int exerciseIndex, int setIndex) {
    final exercise = session?.exerciseAt(exerciseIndex);
    if (exercise == null || setIndex < 0 || setIndex >= exercise.sets.length) {
      return WorkoutSetSessionStatus.pending;
    }
    return exercise.sets[setIndex].status;
  }

  LiveWorkoutState copyWith({
    LiveWorkoutStatus? status,
    WorkoutSession? session,
    String? userId,
    List<String>? coachTips,
    List<String>? explainability,
    String? readinessHint,
    LiveWorkoutRestState? rest,
    LiveWorkoutCompletionSummary? completionSummary,
    String? errorMessage,
    ActiveProgramOption? activeProgram,
    ActiveWorkoutSessionContext? sessionContext,
  }) {
    return LiveWorkoutState(
      status: status ?? this.status,
      session: session ?? this.session,
      userId: userId ?? this.userId,
      coachTips: coachTips ?? this.coachTips,
      explainability: explainability ?? this.explainability,
      readinessHint: readinessHint ?? this.readinessHint,
      rest: rest ?? this.rest,
      completionSummary: completionSummary ?? this.completionSummary,
      errorMessage: errorMessage ?? this.errorMessage,
      activeProgram: activeProgram ?? this.activeProgram,
      sessionContext: sessionContext ?? this.sessionContext,
    );
  }
}
