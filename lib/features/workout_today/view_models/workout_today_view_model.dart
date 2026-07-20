import 'package:flutter/foundation.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/workout_today/application/workout_today_facade.dart';
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
  bool _isDisposed = false;
  int _fetchToken = 0;

  WorkoutTodayState get state => _state;

  WorkoutSessionSelectionGateway get sessionGateway =>
      (_facade ?? WorkoutTodayFacade()).sessionGateway;

  @override
  void dispose() {
    _isDisposed = true;
    _fetchToken++;
    super.dispose();
  }

  Future<void> load() async {
    if (_loaded || _isDisposed) return;
    _loaded = true;
    await _fetch(enrichWithCoach: false);
  }

  Future<void> refresh() async {
    if (_isDisposed) return;
    _loaded = false;
    await load();
  }

  Future<void> refreshWithCoach() async {
    if (_isDisposed) return;
    _loaded = true;
    await _fetch(enrichWithCoach: true);
  }

  Future<void> selectProgram(ActiveProgramOption program) async {
    if (_isDisposed) return;
    _setState(const WorkoutTodayState.loading());
    final token = ++_fetchToken;
    try {
      final result =
          await (_facade ?? WorkoutTodayFacade()).reloadForProgram(program.id);
      if (_isDisposed || token != _fetchToken) return;
      _setState(result.state);
    } on Object catch (error) {
      if (_isDisposed || token != _fetchToken) return;
      _setState(WorkoutTodayState.error(error.toString()));
    }
  }

  Future<SessionChangeEvaluation> evaluateSessionChange(
    String newSessionDay,
  ) async {
    final programId = _resolveProgramId();
    if (programId == null) {
      return const SessionChangeEvaluation.none();
    }
    return (_facade ?? WorkoutTodayFacade()).evaluateSessionChange(
      programId: programId,
      newSessionDay: newSessionDay,
      currentSessionDay: _currentSessionDay(),
    );
  }

  Future<SessionChangeEvaluation> evaluateProgramChange() async {
    final programId = _resolveProgramId();
    if (programId == null) {
      return const SessionChangeEvaluation.none();
    }
    return (_facade ?? WorkoutTodayFacade()).evaluateProgramChange(
      programId: programId,
    );
  }

  Future<void> selectSession(String sessionDay) async {
    final programId = _resolveProgramId();
    if (programId == null || _isDisposed) return;

    _setState(const WorkoutTodayState.loading());
    final token = ++_fetchToken;
    try {
      final result = await (_facade ?? WorkoutTodayFacade()).selectSession(
        programId: programId,
        sessionDay: sessionDay,
      );
      if (_isDisposed || token != _fetchToken) return;
      _setState(result.state);
    } on Object catch (error) {
      if (_isDisposed || token != _fetchToken) return;
      _setState(WorkoutTodayState.error(error.toString()));
    }
  }

  Future<WorkoutTodayQuickActionResult> runQuickAction(
    WorkoutTodayQuickAction action,
  ) async {
    return (_facade ?? WorkoutTodayFacade()).runQuickAction(action.id);
  }

  Future<void> _fetch({required bool enrichWithCoach}) async {
    if (_isDisposed) return;
    final token = ++_fetchToken;
    _setState(const WorkoutTodayState.loading());
    try {
      final result = await (_facade ?? WorkoutTodayFacade()).load(
        enrichWithCoach: enrichWithCoach,
      );
      if (_isDisposed || token != _fetchToken) return;
      ProductAnalytics.track(ProductAnalyticsEvent.workoutTodayOpened);
      _setState(result.state);
    } on Object catch (error) {
      if (_isDisposed || token != _fetchToken) return;
      _setState(WorkoutTodayState.error(error.toString()));
    }
  }

  String? _resolveProgramId() {
    return _state.activeProgram?.id ?? _state.data?.activeProgram?.id;
  }

  String? _currentSessionDay() {
    return _state.sessionContext?.selectedSessionDay ??
        _state.data?.sessionContext.selectedSessionDay;
  }

  void _setState(WorkoutTodayState state) {
    if (_isDisposed) return;
    _state = state;
    notifyListeners();
  }
}
