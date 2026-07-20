import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';

enum WorkoutTodayStatus { loading, loaded, error, empty, awaitingSession }

class WorkoutTodayState {
  const WorkoutTodayState({
    required this.status,
    this.data,
    this.errorMessage,
    this.availablePrograms = const <ActiveProgramOption>[],
    this.activeProgram,
    this.sessionContext,
  });

  const WorkoutTodayState.loading()
    : status = WorkoutTodayStatus.loading,
      data = null,
      errorMessage = null,
      availablePrograms = const <ActiveProgramOption>[],
      activeProgram = null,
      sessionContext = null;

  const WorkoutTodayState.loaded(WorkoutTodayData data)
    : this(status: WorkoutTodayStatus.loaded, data: data);

  const WorkoutTodayState.empty({
    this.availablePrograms = const <ActiveProgramOption>[],
    this.activeProgram,
  }) : status = WorkoutTodayStatus.empty,
       data = null,
       errorMessage = null,
       sessionContext = null;

  const WorkoutTodayState.awaitingSession({
    required this.activeProgram,
    required this.sessionContext,
    this.availablePrograms = const <ActiveProgramOption>[],
  }) : status = WorkoutTodayStatus.awaitingSession,
       data = null,
       errorMessage = null;

  const WorkoutTodayState.error(String message)
    : status = WorkoutTodayStatus.error,
      data = null,
      errorMessage = message,
      availablePrograms = const <ActiveProgramOption>[],
      activeProgram = null,
      sessionContext = null;

  final WorkoutTodayStatus status;
  final WorkoutTodayData? data;
  final String? errorMessage;
  final List<ActiveProgramOption> availablePrograms;
  final ActiveProgramOption? activeProgram;
  final ActiveWorkoutSessionContext? sessionContext;

  bool get isLoading => status == WorkoutTodayStatus.loading;
  bool get isLoaded => status == WorkoutTodayStatus.loaded;
  bool get isEmpty => status == WorkoutTodayStatus.empty;
  bool get isAwaitingSession => status == WorkoutTodayStatus.awaitingSession;
  bool get hasError => status == WorkoutTodayStatus.error;
}

class WorkoutTodayData {
  const WorkoutTodayData({
    required this.workout,
    required this.quickActions,
    required this.sessionContext,
    this.activeProgram,
    this.availablePrograms = const <ActiveProgramOption>[],
  });

  final WorkoutTodayDomainModel workout;
  final List<WorkoutTodayQuickAction> quickActions;
  final ActiveWorkoutSessionContext sessionContext;
  final ActiveProgramOption? activeProgram;
  final List<ActiveProgramOption> availablePrograms;
}

class WorkoutTodayQuickAction {
  const WorkoutTodayQuickAction({
    required this.id,
    required this.label,
    required this.routeName,
  });

  final String id;
  final String label;
  final String routeName;
}
