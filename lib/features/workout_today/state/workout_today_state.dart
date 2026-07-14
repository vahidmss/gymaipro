import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';

enum WorkoutTodayStatus { loading, loaded, error, empty }

class WorkoutTodayState {
  const WorkoutTodayState({
    required this.status,
    this.data,
    this.errorMessage,
  });

  const WorkoutTodayState.loading()
    : status = WorkoutTodayStatus.loading,
      data = null,
      errorMessage = null;

  const WorkoutTodayState.loaded(WorkoutTodayData data)
    : this(status: WorkoutTodayStatus.loaded, data: data);

  const WorkoutTodayState.empty()
    : status = WorkoutTodayStatus.empty,
      data = null,
      errorMessage = null;

  const WorkoutTodayState.error(String message)
    : status = WorkoutTodayStatus.error,
      data = null,
      errorMessage = message;

  final WorkoutTodayStatus status;
  final WorkoutTodayData? data;
  final String? errorMessage;

  bool get isLoading => status == WorkoutTodayStatus.loading;
  bool get isLoaded => status == WorkoutTodayStatus.loaded;
  bool get isEmpty => status == WorkoutTodayStatus.empty;
  bool get hasError => status == WorkoutTodayStatus.error;
}

class WorkoutTodayData {
  const WorkoutTodayData({
    required this.workout,
    required this.quickActions,
  });

  final WorkoutTodayDomainModel workout;
  final List<WorkoutTodayQuickAction> quickActions;
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
