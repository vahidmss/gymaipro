import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_completion_service.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_rest_timer.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_store.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_facade.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_rest_state.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';
import 'package:gymaipro/features/product_experience/product_analytics.dart';

class LiveWorkoutViewModel extends ChangeNotifier {
  LiveWorkoutViewModel({
    LiveWorkoutFacade? facade,
    LiveWorkoutSessionStore? sessionStore,
    LiveWorkoutCompletionService? completionService,
    LiveWorkoutState initialState = const LiveWorkoutState.loading(),
  }) : _facade = facade,
       _sessionStore = sessionStore ?? LiveWorkoutSessionStore(),
       _completionService = completionService ?? LiveWorkoutCompletionService(),
       _state = initialState {
    _restTimer = LiveWorkoutRestTimer(onTick: _handleRestTick);
  }

  final LiveWorkoutFacade? _facade;
  final LiveWorkoutSessionStore _sessionStore;
  final LiveWorkoutCompletionService _completionService;
  late final LiveWorkoutRestTimer _restTimer;

  LiveWorkoutState _state;
  bool _loaded = false;
  Timer? _draftSaveTimer;
  bool _isCompleting = false;

  LiveWorkoutState get state => _state;
  bool get isCompleting => _isCompleting;

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    _restTimer.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    await _fetch();
  }

  Future<void> refresh() async {
    _loaded = false;
    await load();
  }

  Future<void> _fetch() async {
    _setState(const LiveWorkoutState.loading());
    try {
      final facade = _facade ?? LiveWorkoutFacade();
      final userId = await facade.resolveUserId();
      final draft = await _sessionStore.loadDraft(userId);
      if (draft != null && draft.session.exercises.isNotEmpty) {
        _setState(
          LiveWorkoutState.loaded(
            session: draft.session.initializeCurrentSet(),
            userId: userId,
            coachTips: draft.coachTips,
            explainability: draft.explainability,
            rest: draft.rest,
          ),
        );
        if (draft.rest.active && draft.rest.remainingSeconds > 0) {
          _restTimer.start(seconds: draft.rest.remainingSeconds);
          if (draft.rest.paused) {
            _restTimer.pause();
          }
        }
        ProductAnalytics.track(
          ProductAnalyticsEvent.workoutStarted,
          properties: const <String, Object?>{'resumed': true},
        );
        return;
      }

      final result = await facade.load();
      _setState(result.state);
      if (result.state.isLoaded) {
        ProductAnalytics.track(ProductAnalyticsEvent.workoutStarted);
        unawaited(_persistDraft());
      }
    } on Object catch (error) {
      _setState(LiveWorkoutState.error(error.toString()));
    }
  }

  void updateCurrentSet({
    int? reps,
    double? weightKg,
    int? rpe,
    int? durationSeconds,
    String? notes,
  }) {
    final pointer = _state.currentPointer;
    final session = _state.session;
    if (pointer == null || session == null) return;

    _setState(
      _state.copyWith(
        session: session.updateSet(
          exerciseIndex: pointer.exerciseIndex,
          setIndex: pointer.setIndex,
          actualReps: reps,
          actualWeightKg: weightKg,
          rpe: rpe,
          durationSeconds: durationSeconds,
          notes: notes,
        ),
      ),
    );
    _scheduleDraftSave();
  }

  void completePrimaryAction() {
    if (_state.rest.active) {
      skipRest();
      return;
    }

    final pointer = _state.currentPointer;
    final session = _state.session;
    if (!_state.isLoaded || pointer == null || session == null) return;

    if (_state.currentExerciseCompleted && !_state.isLastExercise) {
      final nextExercise = _state.nextExerciseIndex!;
      _setState(
        _state.copyWith(
          session: session.withCurrentPointer(
            exerciseIndex: nextExercise,
            setIndex: 0,
          ),
        ),
      );
      _scheduleDraftSave();
      return;
    }

    if (session.isCompleted || _state.currentExerciseCompleted) {
      unawaited(finishWorkout());
      return;
    }

    _completeCurrentSet(WorkoutSetSessionStatus.completed);
  }

  void skipCurrentSet() => _completeCurrentSet(WorkoutSetSessionStatus.skipped);

  void failCurrentSet() => _completeCurrentSet(WorkoutSetSessionStatus.failed);

  void toggleSet(int setIndex) {
    final exerciseIndex = _state.currentExerciseIndex;
    final session = _state.session;
    if (exerciseIndex == null || session == null) return;

    final exercise = session.exerciseAt(exerciseIndex);
    if (exercise == null || setIndex < 0 || setIndex >= exercise.sets.length) {
      return;
    }

    final currentStatus = exercise.sets[setIndex].status;
    if (currentStatus == WorkoutSetSessionStatus.current) {
      _completeCurrentSet(WorkoutSetSessionStatus.completed);
      return;
    }

    if (currentStatus.isTerminal) {
      _setState(
        _state.copyWith(
          session: session
              .updateSet(
                exerciseIndex: exerciseIndex,
                setIndex: setIndex,
                status: WorkoutSetSessionStatus.pending,
              )
              .withCurrentPointer(
                exerciseIndex: exerciseIndex,
                setIndex: setIndex,
              ),
        ),
      );
      _restTimer.stop();
      _setState(_state.copyWith(rest: const LiveWorkoutRestState.idle()));
      _scheduleDraftSave();
    }
  }

  void pauseRest() {
    if (!_state.rest.active || _state.rest.paused) return;
    _restTimer.pause();
    _setState(
      _state.copyWith(
        rest: _state.rest.copyWith(paused: true),
      ),
    );
    _scheduleDraftSave();
  }

  void resumeRest() {
    if (!_state.rest.active || !_state.rest.paused) return;
    _restTimer.resume();
    _setState(
      _state.copyWith(
        rest: _state.rest.copyWith(paused: false),
      ),
    );
    _scheduleDraftSave();
  }

  void skipRest() {
    _restTimer.stop();
    _setState(_state.copyWith(rest: const LiveWorkoutRestState.idle()));
    _scheduleDraftSave();
  }

  void extendRest(int extraSeconds) {
    _restTimer.extend(extraSeconds);
    _setState(
      _state.copyWith(
        rest: LiveWorkoutRestState(
          active: true,
          paused: _restTimer.isPaused,
          remainingSeconds: _restTimer.remainingSeconds,
          totalSeconds: _restTimer.totalSeconds,
        ),
      ),
    );
    _scheduleDraftSave();
  }

  Future<void> finishWorkout() async {
    if (_isCompleting || !_state.isLoaded) return;
    final session = _state.session;
    final userId = _state.userId;
    if (session == null || userId == null) return;

    _isCompleting = true;
    notifyListeners();
    try {
      final result = await _completionService.complete(
        session: session,
        userId: userId,
        coachTips: _state.coachTips,
        explainability: _state.explainability,
      );
      await _sessionStore.clearDraft(userId);
      _restTimer.stop();
      ProductAnalytics.track(
        ProductAnalyticsEvent.workoutFinished,
        properties: <String, Object?>{
          'completedSets': session.completedSets,
          'totalSets': session.totalSets,
        },
      );
      _setState(
        LiveWorkoutState.sessionCompleted(
          summary: result.summary,
          coachTips: _state.coachTips,
          explainability: _state.explainability,
        ),
      );
    } on Object catch (error) {
      _setState(LiveWorkoutState.error(error.toString()));
    } finally {
      _isCompleting = false;
      notifyListeners();
    }
  }

  void _completeCurrentSet(WorkoutSetSessionStatus terminalStatus) {
    final pointer = _state.currentPointer;
    final session = _state.session;
    if (pointer == null || session == null) return;

    final updated = session.advanceAfterSet(
      exerciseIndex: pointer.exerciseIndex,
      setIndex: pointer.setIndex,
      terminalStatus: terminalStatus,
    );

    _setState(_state.copyWith(session: updated));
    _scheduleDraftSave();

    if (updated.isCompleted) {
      unawaited(finishWorkout());
      return;
    }

    if (terminalStatus == WorkoutSetSessionStatus.completed ||
        terminalStatus == WorkoutSetSessionStatus.failed) {
      final completedSet =
          session.exerciseAt(pointer.exerciseIndex)?.sets[pointer.setIndex];
      final restSeconds = completedSet?.restSeconds ?? 90;
      _restTimer.start(seconds: restSeconds);
      _setState(
        _state.copyWith(
          rest: LiveWorkoutRestState(
            active: true,
            paused: false,
            remainingSeconds: restSeconds,
            totalSeconds: restSeconds,
          ),
        ),
      );
    }
  }

  void _handleRestTick() {
    if (!_state.rest.active) return;
    _setState(
      _state.copyWith(
        rest: LiveWorkoutRestState(
          active: _restTimer.isActive,
          paused: _restTimer.isPaused,
          remainingSeconds: _restTimer.remainingSeconds,
          totalSeconds: _restTimer.totalSeconds,
        ),
      ),
    );
    if (!_restTimer.isActive) {
      _scheduleDraftSave();
    }
  }

  void _scheduleDraftSave() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persistDraft());
    });
  }

  Future<void> _persistDraft() async {
    final session = _state.session;
    final userId = _state.userId;
    if (!_state.isLoaded || session == null || userId == null) return;
    await _sessionStore.saveDraft(
      LiveWorkoutDraft(
        userId: userId,
        session: session,
        coachTips: _state.coachTips,
        explainability: _state.explainability,
        rest: _state.rest,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _setState(LiveWorkoutState state) {
    _state = state;
    notifyListeners();
  }
}
