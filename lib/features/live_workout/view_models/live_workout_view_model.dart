import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_completion_service.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_facade.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_rest_timer.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_factory.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_persistence.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_store.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/live_workout/presentation/adapters/live_workout_exercise_adapter.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_rest_state.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';
import 'package:gymaipro/features/product_experience/product_analytics.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

class LiveWorkoutViewModel extends ChangeNotifier {
  LiveWorkoutViewModel({
    LiveWorkoutFacade? facade,
    LiveWorkoutSessionStore? sessionStore,
    LiveWorkoutCompletionService? completionService,
    LiveWorkoutSessionPersistence? sessionPersistence,
    LiveWorkoutSessionFactory? sessionFactory,
    ExerciseService? exerciseService,
    LiveWorkoutState initialState = const LiveWorkoutState.loading(),
  }) : _facade = facade,
       _sessionStore = sessionStore ?? LiveWorkoutSessionStore(),
       _completionService = completionService ?? LiveWorkoutCompletionService(),
       _sessionPersistence =
           sessionPersistence ?? LiveWorkoutSessionPersistence(),
       _sessionFactory = sessionFactory ?? const LiveWorkoutSessionFactory(),
       _exerciseService = exerciseService ?? ExerciseService(),
       _state = initialState {
    _restTimer = LiveWorkoutRestTimer(onTick: _handleRestTick);
    if (initialState.isLoaded) {
      _rebuildDisplayExercises();
      _initAllExerciseControllers();
      unawaited(loadExerciseDetails());
    }
  }

  final LiveWorkoutFacade? _facade;
  final LiveWorkoutSessionStore _sessionStore;
  final LiveWorkoutCompletionService _completionService;
  final LiveWorkoutSessionPersistence _sessionPersistence;
  final LiveWorkoutSessionFactory _sessionFactory;
  final ExerciseService _exerciseService;
  late final LiveWorkoutRestTimer _restTimer;

  LiveWorkoutState _state;
  bool _loaded = false;
  Timer? _draftSaveTimer;
  Timer? _remoteSaveTimer;
  bool _isCompleting = false;
  bool _isLoadingSetData = false;
  bool _isDisposed = false;

  final Map<String, List<Map<String, TextEditingController>>>
  _exerciseControllers = {};
  final Map<String, List<bool>> _setSavedStatus = {};
  final Map<String, List<Map<String, FocusNode>>> _exerciseFocusNodes = {};
  final Map<String, bool> _collapsedExercises = {};
  final Map<int, Exercise> _exerciseDetails = {};
  final Map<String, Timer> _autoSaveTimers = {};
  final Map<String, int> _exerciseIndexByKey = {};
  final Map<String, WorkoutExerciseCoachFeedback> _exerciseCoachFeedback = {};

  List<NormalExercise> _displayExercises = [];

  LiveWorkoutState get state => _state;
  bool get isCompleting => _isCompleting;
  List<NormalExercise> get displayExercises =>
      List<NormalExercise>.unmodifiable(_displayExercises);
  Map<String, List<Map<String, TextEditingController>>>
  get exerciseControllers => _exerciseControllers;
  Map<String, List<bool>> get setSavedStatus => _setSavedStatus;
  Map<String, List<Map<String, FocusNode>>> get exerciseFocusNodes =>
      _exerciseFocusNodes;
  Map<String, bool> get collapsedExercises => _collapsedExercises;
  Map<int, Exercise> get exerciseDetails => _exerciseDetails;
  Map<String, WorkoutExerciseCoachFeedback> get exerciseCoachFeedback =>
      _exerciseCoachFeedback;

  int get savedSetsCount {
    var count = 0;
    for (final statuses in _setSavedStatus.values) {
      count += statuses.where((saved) => saved).length;
    }
    return count;
  }

  int get totalSetsCount => _state.session?.totalSets ?? 0;

  @override
  void dispose() {
    _isDisposed = true;
    _draftSaveTimer?.cancel();
    _remoteSaveTimer?.cancel();
    _cancelAutoSaveTimers();
    _disposeAllControllers();
    _restTimer.dispose();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
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

  Future<SessionChangeEvaluation> evaluateSessionChange(
    String newSessionDay,
  ) async {
    final facade = _facade ?? LiveWorkoutFacade();
    final programId =
        _state.activeProgram?.id ?? _state.sessionContext?.programId;
    if (programId == null || programId.isEmpty) {
      return const SessionChangeEvaluation.none();
    }
    return facade.evaluateSessionChange(
      programId: programId,
      newSessionDay: newSessionDay,
      currentSessionDay: _state.sessionContext?.selectedSessionDay,
    );
  }

  Future<void> selectSession(String sessionDay) async {
    final facade = _facade ?? LiveWorkoutFacade();
    final programId =
        _state.activeProgram?.id ?? _state.sessionContext?.programId;
    if (programId == null || programId.isEmpty) return;

    _setState(const LiveWorkoutState.loading());
    try {
      final userId = await facade.resolveUserId();
      if (_isDisposed) return;
      final result = await facade.selectSession(
        programId: programId,
        sessionDay: sessionDay,
        userId: userId,
      );
      if (_isDisposed) return;
      _setState(result.state);
      if (result.state.isLoaded) {
        ProductAnalytics.track(ProductAnalyticsEvent.workoutStarted);
        // Do not persist an empty shell — only save after real set progress.
        unawaited(loadExerciseDetails());
      }
    } on Object catch (error) {
      if (_isDisposed) return;
      _setState(LiveWorkoutState.error(error.toString()));
    }
  }

  WorkoutSessionSelectionGateway get sessionGateway =>
      (_facade ?? LiveWorkoutFacade()).sessionGateway;

  void toggleExerciseCollapse(String exerciseKey) {
    if (_isDisposed) return;
    _collapsedExercises[exerciseKey] =
        !(_collapsedExercises[exerciseKey] ?? false);
    _safeNotifyListeners();
  }

  void scheduleAutoSave(String exerciseKey, int setIndex) {
    if (_isDisposed || _isLoadingSetData) return;

    final setKey = '$exerciseKey-$setIndex';
    _autoSaveTimers[setKey]?.cancel();

    final controllers = _exerciseControllers[exerciseKey];
    if (controllers == null || controllers.length <= setIndex) return;

    final setControllers = controllers[setIndex];
    final weight = setControllers['weight']?.text.trim() ?? '';
    final reps = setControllers['reps']?.text.trim() ?? '';
    final time = setControllers['time']?.text.trim() ?? '';

    if (weight.isEmpty && reps.isEmpty && time.isEmpty) {
      final savedStatus = _setSavedStatus[exerciseKey];
      if (savedStatus != null &&
          savedStatus.length > setIndex &&
          savedStatus[setIndex]) {
        savedStatus[setIndex] = false;
        _refreshExerciseCoachFeedback(exerciseKey);
      }
      return;
    }

    _autoSaveTimers[setKey] = Timer(const Duration(seconds: 1), () {
      if (_isDisposed) return;
      saveSet(exerciseKey, setIndex);
    });
  }

  void saveSet(String exerciseKey, int setIndex) {
    if (_isDisposed) return;
    final exerciseIndex = _exerciseIndexByKey[exerciseKey];
    final session = _state.session;
    final controllers = _exerciseControllers[exerciseKey];
    if (exerciseIndex == null || session == null || controllers == null) {
      return;
    }
    if (controllers.length <= setIndex) return;

    final savedStatus = _setSavedStatus[exerciseKey];
    final wasSaved =
        savedStatus != null &&
        savedStatus.length > setIndex &&
        savedStatus[setIndex];

    try {
      final setControllers = controllers[setIndex];
      final weightText = setControllers['weight']?.text.trim() ?? '';
      final repsText = setControllers['reps']?.text.trim() ?? '';
      final rpeText = setControllers['rpe']?.text.trim() ?? '';

      final weight = weightText.isNotEmpty
          ? (double.tryParse(weightText) ?? 0.0)
          : 0.0;
      final reps = repsText.isNotEmpty ? (int.tryParse(repsText) ?? 0) : 0;
      final rpe = rpeText.isNotEmpty ? int.tryParse(rpeText) : null;
      final hasData = reps > 0 || weight > 0;

      if (savedStatus != null && savedStatus.length > setIndex) {
        savedStatus[setIndex] = hasData;
      }

      if (!wasSaved && hasData) {
        _safeNotifyListeners();
      } else if (wasSaved && !hasData) {
        _safeNotifyListeners();
      }

      _setState(
        _state.copyWith(
          session: session.updateSet(
            exerciseIndex: exerciseIndex,
            setIndex: setIndex,
            actualReps: reps > 0 ? reps : null,
            actualWeightKg: weight > 0 ? weight : null,
            rpe: rpe,
            status: hasData
                ? WorkoutSetSessionStatus.completed
                : WorkoutSetSessionStatus.pending,
            clearActualReps: reps <= 0,
            clearActualWeightKg: weight <= 0,
            clearRpe: rpe == null,
          ),
        ),
        syncControllers: false,
      );
      _refreshExerciseCoachFeedback(exerciseKey);
      _scheduleDraftSave();
      _scheduleRemoteSave();
      _maybeFinalizeWorkout();
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[LiveWorkout] saveSet error: $error');
      }
      if (savedStatus != null && savedStatus.length > setIndex && !wasSaved) {
        savedStatus[setIndex] = false;
        _safeNotifyListeners();
      }
    }
  }

  void flushPendingSetSaves() {
    if (_isDisposed) return;
    final pending = _autoSaveTimers.keys.toList(growable: false);
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();

    for (final setKey in pending) {
      final parts = setKey.split('-');
      if (parts.length < 2) continue;
      final setIndex = int.tryParse(parts.last);
      if (setIndex == null) continue;
      final exerciseKey = parts.sublist(0, parts.length - 1).join('-');
      saveSet(exerciseKey, setIndex);
    }
  }

  Future<void> loadExerciseDetails() async {
    if (_isDisposed) return;
    final session = _state.session;
    if (!_state.isLoaded || session == null) return;

    final idsToLoad = <int>{};
    for (final exercise in session.exercises) {
      final id = exercise.exerciseId;
      if (id != null && !_exerciseDetails.containsKey(id)) {
        idsToLoad.add(id);
      }
    }
    if (idsToLoad.isEmpty) {
      _refreshAllExerciseCoachFeedback();
      await _restoreCompletionSummaryIfNeeded();
      _safeNotifyListeners();
      return;
    }

    try {
      final allExercises = await _exerciseService.getExercises();
      if (_isDisposed) return;
      final exerciseMap = {for (final ex in allExercises) ex.id: ex};
      for (final id in idsToLoad) {
        final exercise = exerciseMap[id];
        if (exercise != null) {
          _exerciseDetails[id] = exercise;
        }
      }
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[LiveWorkout] loadExerciseDetails: $error');
      }
    }
    _refreshAllExerciseCoachFeedback();
    await _restoreCompletionSummaryIfNeeded();
    _safeNotifyListeners();
  }

  /// Reattach completion card + heatmap when today's session is already logged.
  Future<void> _restoreCompletionSummaryIfNeeded() async {
    if (_isDisposed || !_state.isLoaded) return;
    if (_state.completionSummary != null) return;
    final session = _state.session;
    if (session == null || !session.isCompleted) return;

    final summary = _completionService.buildSummary(
      session: session,
      exerciseById: Map<int, Exercise>.from(_exerciseDetails),
    );
    _setState(
      _state.copyWith(completionSummary: summary),
      syncControllers: false,
    );
  }

  Future<void> _fetch() async {
    _setState(const LiveWorkoutState.loading());
    try {
      final facade = _facade ?? LiveWorkoutFacade();
      final userId = await facade.resolveUserId();
      if (_isDisposed) return;
      final draft = await _sessionStore.loadDraft(userId);
      if (_isDisposed) return;
      if (draft != null && draft.session.exercises.isNotEmpty) {
        final matches = await facade.draftMatchesActiveSelection(
          userId: userId,
          draft: draft,
        );
        if (_isDisposed) return;
        if (matches) {
          final session = _sessionFactory.withDisplayNames(draft.session);
          _setState(
            LiveWorkoutState.loaded(
              session: session,
              userId: userId,
              coachTips: draft.coachTips,
              explainability: draft.explainability,
              rest: draft.rest,
            ),
          );
          if (draft.rest.active && draft.rest.remainingSeconds > 0) {
            _restTimer.stop();
          }
          ProductAnalytics.track(
            ProductAnalyticsEvent.workoutStarted,
            properties: const <String, Object?>{'resumed': true},
          );
          unawaited(loadExerciseDetails());
          return;
        }
        // Stale draft from another program/session — do not resume it.
        await _sessionStore.clearDraft(userId);
        if (_isDisposed) return;
      }

      final result = await facade.load();
      if (_isDisposed) return;
      _setState(result.state);
      if (result.state.isLoaded) {
        ProductAnalytics.track(ProductAnalyticsEvent.workoutStarted);
        // Empty shells must not create a blocking draft on SharedPreferences.
        unawaited(loadExerciseDetails());
      }
    } on Object catch (error) {
      if (_isDisposed) return;
      _setState(LiveWorkoutState.error(error.toString()));
    }
  }

  Future<void> finishWorkout() async {
    if (_isDisposed || _isCompleting || !_state.isLoaded) return;
    flushPendingSetSaves();

    final session = _state.session;
    final userId = _state.userId;
    if (session == null || userId == null) return;

    _isCompleting = true;
    _safeNotifyListeners();
    try {
      // Heatmap needs catalog muscle targets — ensure details are loaded.
      if (_exerciseDetails.isEmpty) {
        await loadExerciseDetails();
        if (_isDisposed) return;
      }

      _remoteSaveTimer?.cancel();
      await _persistRemote();
      if (_isDisposed) return;

      final result = await _completionService.complete(
        session: session,
        userId: userId,
        exerciseById: Map<int, Exercise>.from(_exerciseDetails),
      );
      if (_isDisposed) return;
      await _sessionStore.clearDraft(userId);
      _restTimer.stop();
      ProductAnalytics.track(
        ProductAnalyticsEvent.workoutFinished,
        properties: <String, Object?>{
          'completedSets': savedSetsCount,
          'totalSets': session.totalSets,
        },
      );
      // Keep the filled session on screen — do not wipe UI into a weak
      // summary-only page. Persist succeeded; values stay visible.
      _setState(
        _state.copyWith(
          session: session,
          completionSummary: result.summary,
          rest: const LiveWorkoutRestState.idle(),
        ),
        syncControllers: false,
      );
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[LiveWorkout] finishWorkout: $error');
      }
    } finally {
      _isCompleting = false;
      _safeNotifyListeners();
    }
  }

  void _maybeFinalizeWorkout() {
    if (_isDisposed || !_state.isLoaded || _isCompleting) return;
    if (_state.completionSummary != null) return;
    if (savedSetsCount < totalSetsCount || totalSetsCount == 0) return;
    unawaited(finishWorkout());
  }

  void _handleRestTick() {
    if (_isDisposed || !_state.rest.active) return;
    _setState(
      _state.copyWith(
        rest: LiveWorkoutRestState(
          active: _restTimer.isActive,
          paused: _restTimer.isPaused,
          remainingSeconds: _restTimer.remainingSeconds,
          totalSeconds: _restTimer.totalSeconds,
        ),
      ),
      syncControllers: false,
    );
    if (!_restTimer.isActive) {
      _scheduleDraftSave();
    }
  }

  void _scheduleDraftSave() {
    if (_isDisposed) return;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 400), () {
      if (_isDisposed) return;
      unawaited(_persistDraft());
    });
  }

  /// Near-realtime DB sync — same cadence idea as dashboard workout log (~1s).
  void _scheduleRemoteSave() {
    if (_isDisposed) return;
    _remoteSaveTimer?.cancel();
    _remoteSaveTimer = Timer(const Duration(seconds: 1), () {
      if (_isDisposed) return;
      unawaited(_persistRemote());
    });
  }

  Future<void> _persistRemote() async {
    if (_isDisposed) return;
    final session = _state.session;
    final userId = _state.userId;
    if (session == null || userId == null || userId.isEmpty) return;
    if (session.completedSets <= 0) return;

    try {
      await _sessionPersistence.persistSession(
        session: session,
        userId: userId,
      );
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[LiveWorkout] remote persist: $error');
      }
    }
  }

  Future<void> _persistDraft() async {
    if (_isDisposed) return;
    final session = _state.session;
    final userId = _state.userId;
    if (!_state.isLoaded || session == null || userId == null) return;
    // Never write empty shells — they falsely block session switches.
    if (!ActiveWorkoutSessionService.draftHasProgress(session)) {
      await _sessionStore.clearDraft(userId);
      return;
    }
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

  void _setState(LiveWorkoutState state, {bool syncControllers = true}) {
    if (_isDisposed) return;
    _state = state;
    if (syncControllers) {
      _rebuildDisplayExercises();
      _initAllExerciseControllers();
    }
    _safeNotifyListeners();
  }

  void _rebuildDisplayExercises() {
    final session = _state.session;
    if (session == null) {
      _displayExercises = [];
      _exerciseIndexByKey.clear();
      return;
    }

    _displayExercises = <NormalExercise>[];
    _exerciseIndexByKey.clear();
    for (var i = 0; i < session.exercises.length; i++) {
      final normal = LiveWorkoutExerciseAdapter.toNormalExercise(
        session.exercises[i],
        index: i,
      );
      _displayExercises.add(normal);
      _exerciseIndexByKey[LiveWorkoutExerciseAdapter.controllerKey(normal)] = i;
    }
  }

  void _initAllExerciseControllers() {
    _isLoadingSetData = true;
    _cancelAutoSaveTimers();
    _disposeAllControllers();

    final session = _state.session;
    if (!_state.isLoaded || session == null) {
      _isLoadingSetData = false;
      return;
    }

    for (var i = 0; i < session.exercises.length; i++) {
      _initExerciseControllers(
        session.exercises[i],
        LiveWorkoutExerciseAdapter.controllerKey(_displayExercises[i]),
      );
    }

    _isLoadingSetData = false;
    _refreshAllExerciseCoachFeedback();
  }

  void _refreshAllExerciseCoachFeedback() {
    _exerciseCoachFeedback.clear();
    for (final exerciseKey in _exerciseControllers.keys) {
      _refreshExerciseCoachFeedback(exerciseKey, notify: false);
    }
  }

  void _refreshExerciseCoachFeedback(String exerciseKey, {bool notify = true}) {
    if (_isDisposed) return;

    NormalExercise? exercise;
    for (final item in _displayExercises) {
      if (LiveWorkoutExerciseAdapter.controllerKey(item) == exerciseKey) {
        exercise = item;
        break;
      }
    }
    if (exercise == null) {
      _exerciseCoachFeedback.remove(exerciseKey);
      if (notify) _safeNotifyListeners();
      return;
    }

    final controllers = _exerciseControllers[exerciseKey];
    final savedStatus = _setSavedStatus[exerciseKey];
    if (controllers == null || savedStatus == null) {
      _exerciseCoachFeedback.remove(exerciseKey);
      if (notify) _safeNotifyListeners();
      return;
    }

    final details = _exerciseDetails[exercise.exerciseId];
    final feedback = WorkoutExerciseCoachFeedbackEngine.fromControllers(
      prescription: exercise.sets,
      setValues: controllers
          .map(
            (setControllers) => <String, String>{
              'weight': setControllers['weight']?.text.trim() ?? '',
              'reps': setControllers['reps']?.text.trim() ?? '',
              'time': setControllers['time']?.text.trim() ?? '',
              'rpe': setControllers['rpe']?.text.trim() ?? '',
            },
          )
          .toList(),
      savedStatus: savedStatus,
      style: exercise.style,
      formTipSource: WorkoutExerciseCoachFeedbackEngine.resolveFormTipSource(
        tips: details?.tips ?? const <String>[],
        programNote: exercise.note,
      ),
    );

    if (feedback == null) {
      _exerciseCoachFeedback.remove(exerciseKey);
    } else {
      _exerciseCoachFeedback[exerciseKey] = feedback;
    }
    if (notify) _safeNotifyListeners();
  }

  void _initExerciseControllers(
    WorkoutExerciseSession exercise,
    String exerciseKey,
  ) {
    _exerciseControllers[exerciseKey] = [];
    _setSavedStatus[exerciseKey] = [];
    _exerciseFocusNodes[exerciseKey] = [];

    for (var i = 0; i < exercise.sets.length; i++) {
      final set = exercise.sets[i];
      final weightController = TextEditingController();
      final repsController = TextEditingController();
      final timeController = TextEditingController();
      final rpeController = TextEditingController();

      final repsFocusNode = FocusNode();
      final timeFocusNode = FocusNode();
      final weightFocusNode = FocusNode();
      final rpeFocusNode = FocusNode();

      if (set.actualWeightKg != null && set.actualWeightKg! > 0) {
        weightController.text = _formatWeight(set.actualWeightKg!);
      }
      if (set.actualReps != null && set.actualReps! > 0) {
        repsController.text = set.actualReps.toString();
      }
      if (set.durationSeconds != null && set.durationSeconds! > 0) {
        timeController.text = set.durationSeconds.toString();
      }
      if (set.rpe != null && set.rpe! > 0) {
        rpeController.text = set.rpe.toString();
      }

      final setKey = '$exerciseKey-$i';
      weightController.addListener(() => scheduleAutoSave(exerciseKey, i));
      repsController.addListener(() => scheduleAutoSave(exerciseKey, i));
      timeController.addListener(() => scheduleAutoSave(exerciseKey, i));
      rpeController.addListener(() => scheduleAutoSave(exerciseKey, i));

      _exerciseControllers[exerciseKey]!.add(<String, TextEditingController>{
        'weight': weightController,
        'reps': repsController,
        'time': timeController,
        'rpe': rpeController,
      });
      _exerciseFocusNodes[exerciseKey]!.add(<String, FocusNode>{
        'weight': weightFocusNode,
        'reps': repsFocusNode,
        'time': timeFocusNode,
        'rpe': rpeFocusNode,
      });

      final hasData =
          (set.actualWeightKg != null && set.actualWeightKg! > 0) ||
          (set.actualReps != null && set.actualReps! > 0) ||
          (set.durationSeconds != null && set.durationSeconds! > 0) ||
          (set.rpe != null && set.rpe! > 0) ||
          set.status == WorkoutSetSessionStatus.completed;
      _setSavedStatus[exerciseKey]!.add(hasData);
      _autoSaveTimers.remove(setKey);
    }
  }

  void _disposeAllControllers() {
    _cancelAutoSaveTimers();
    for (final setControllers in _exerciseControllers.values) {
      for (final controllers in setControllers) {
        for (final controller in controllers.values) {
          controller.dispose();
        }
      }
    }
    for (final exerciseFocusNodes in _exerciseFocusNodes.values) {
      for (final setFocusNodes in exerciseFocusNodes) {
        for (final focusNode in setFocusNodes.values) {
          focusNode.dispose();
        }
      }
    }
    _exerciseControllers.clear();
    _setSavedStatus.clear();
    _exerciseFocusNodes.clear();
    _collapsedExercises.clear();
    _exerciseCoachFeedback.clear();
  }

  void _cancelAutoSaveTimers() {
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
  }

  static String _formatWeight(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
