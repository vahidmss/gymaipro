import 'package:flutter/foundation.dart';
import 'package:gymaipro/features/workout_today/application/workout_today_facade.dart';
import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';
import 'package:gymaipro/features/product_experience/product_analytics.dart';
import 'package:gymaipro/features/workout_today/state/workout_today_state.dart';

/// ViewModel for WorkoutTodayScreen.
class WorkoutTodayViewModel extends ChangeNotifier {
  WorkoutTodayViewModel({
    WorkoutTodayFacade? facade,
    WorkoutTodayState initialState = const WorkoutTodayState.loading(),
  }) : _facade = facade,
       _state = initialState;

  final WorkoutTodayFacade? _facade;
  WorkoutTodayState _state;
  bool _loaded = false;

  WorkoutTodayState get state => _state;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    await _fetch();
  }

  Future<void> refresh() async {
    _loaded = false;
    await load();
  }

  Future<WorkoutTodayQuickActionResult> runQuickAction(
    WorkoutTodayQuickAction action,
  ) async {
    final result =
        await (_facade ?? WorkoutTodayFacade()).runQuickAction(action.id);
    final data = _state.data;
    if (data != null) {
      final workout = data.workout;
      _setState(
        WorkoutTodayState.loaded(
          WorkoutTodayData(
            workout: WorkoutTodayDomainModel(
              userName: workout.userName,
              headline: workout.headline,
              recoveryPercent: workout.recoveryPercent,
              durationMinutes: workout.durationMinutes,
              exercises: workout.exercises,
              totalSets: workout.totalSets,
              muscleGroups: workout.muscleGroups,
              intensity: workout.intensity,
              coachNotes: workout.coachNotes,
              reasons: <String>[result.message],
            ),
            quickActions: data.quickActions,
          ),
        ),
      );
    }
    return result;
  }

  Future<void> _fetch() async {
    _setState(const WorkoutTodayState.loading());
    try {
      final result = await (_facade ?? WorkoutTodayFacade()).load();
      ProductAnalytics.track(ProductAnalyticsEvent.workoutTodayOpened);
      _setState(result.state);
    } on Object catch (error) {
      _setState(WorkoutTodayState.error(error.toString()));
    }
  }

  void _setState(WorkoutTodayState state) {
    _state = state;
    notifyListeners();
  }
}
