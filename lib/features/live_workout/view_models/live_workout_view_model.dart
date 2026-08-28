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
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/live_workout/presentation/adapters/live_workout_exercise_adapter.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_rest_state.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/product_experience/domain/coach_observation.dart';
import 'package:gymaipro/features/product_experience/domain/session_debrief.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';
import 'package:gymaipro/features/product_experience/product_analytics.dart';
import 'package:gymaipro/features/session_analysis/application/session_analysis_assembler.dart';
import 'package:gymaipro/features/session_analysis/application/session_analysis_store.dart';
import 'package:gymaipro/features/session_analysis/application/workout_log_session_bridge.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_eligibility.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_snapshot.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/payment/services/ai_program_access.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/workout_log/models/previous_exercise_performance.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';
import 'package:gymaipro/workout_log/utils/workout_day_identity.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart'
    hide WorkoutSession;
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveWorkoutViewModel extends ChangeNotifier {
  LiveWorkoutViewModel({
    LiveWorkoutFacade? facade,
    LiveWorkoutSessionStore? sessionStore,
    LiveWorkoutCompletionService? completionService,
    LiveWorkoutSessionPersistence? sessionPersistence,
    LiveWorkoutSessionFactory? sessionFactory,
    ExerciseService? exerciseService,
    WorkoutDailyLogService? workoutLogService,
    LiveWorkoutState initialState = const LiveWorkoutState.loading(),
  }) : _facade = facade,
       _sessionStore = sessionStore ?? LiveWorkoutSessionStore(),
       _completionService = completionService ?? LiveWorkoutCompletionService(),
       _sessionPersistence =
           sessionPersistence ?? LiveWorkoutSessionPersistence(),
       _sessionFactory = sessionFactory ?? const LiveWorkoutSessionFactory(),
       _exerciseService = exerciseService ?? ExerciseService(),
       _workoutLogService = workoutLogService ?? WorkoutDailyLogService(),
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
  final WorkoutDailyLogService _workoutLogService;
  late final LiveWorkoutRestTimer _restTimer;

  LiveWorkoutState _state;
  bool _loaded = false;
  Timer? _draftSaveTimer;
  Timer? _remoteSaveTimer;
  bool _isCompleting = false;
  bool _isLoadingSetData = false;
  bool _isDisposed = false;
  bool _suppressAutoSave = false;
  bool _justCompletedForAnalysis = false;
  bool _suppressAutoFinalize = false;

  final Map<String, List<Map<String, TextEditingController>>>
  _exerciseControllers = {};
  final Map<String, List<bool>> _setSavedStatus = {};
  final Map<String, List<Map<String, FocusNode>>> _exerciseFocusNodes = {};
  final Map<String, bool> _collapsedExercises = {};
  final Map<int, Exercise> _exerciseDetails = {};
  final Map<String, Timer> _autoSaveTimers = {};
  final Map<String, int> _exerciseIndexByKey = {};
  final Map<String, WorkoutExerciseCoachFeedback> _exerciseCoachFeedback = {};
  final Map<int, List<PreviousExerciseSet>> _previousSetsByExerciseId = {};
  final Map<int, DateTime> _previousLogDateByExerciseId = {};
  SessionAnalysisSnapshot? _sessionAnalysis;
  final Map<String, ValueNotifier<int>> _exerciseRevision = {};

  /// فقط نوار پیشرفت — نه کل صفحه.
  final ValueNotifier<int> sessionProgressTick = ValueNotifier<int>(0);

  /// تیک تایمر استراحت — جدا از notifyListeners تا لیست حرکات نلرزد.
  final ValueNotifier<int> restRemaining = ValueNotifier<int>(0);
  final ValueNotifier<int> restTotal = ValueNotifier<int>(90);
  final ValueNotifier<bool> restRunning = ValueNotifier<bool>(false);
  final ValueNotifier<bool> restSessionActive = ValueNotifier<bool>(false);

  List<NormalExercise> _displayExercises = [];

  LiveWorkoutState get state => _state;
  bool get isCompleting => _isCompleting;
  bool get justCompletedForAnalysis => _justCompletedForAnalysis;
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
  Map<int, List<PreviousExerciseSet>> get previousSetsByExerciseId =>
      Map<int, List<PreviousExerciseSet>>.unmodifiable(
        _previousSetsByExerciseId,
      );
  SessionAnalysisSnapshot? get sessionAnalysis => _sessionAnalysis;
  bool get isAnalysisMode => _sessionAnalysis != null;

  int get savedSetsCount {
    var count = 0;
    for (final statuses in _setSavedStatus.values) {
      count += statuses.where((saved) => saved).length;
    }
    return count;
  }

  int get totalSetsCount => _state.session?.totalSets ?? 0;

  ValueNotifier<int> exerciseListenable(String exerciseKey) {
    return _exerciseRevision.putIfAbsent(
      exerciseKey,
      () => ValueNotifier<int>(0),
    );
  }

  void _bumpExerciseUi(String exerciseKey, {bool bumpProgress = true}) {
    if (_isDisposed) return;
    final tick = _exerciseRevision.putIfAbsent(
      exerciseKey,
      () => ValueNotifier<int>(0),
    );
    tick.value++;
    if (bumpProgress) {
      sessionProgressTick.value++;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _draftSaveTimer?.cancel();
    _remoteSaveTimer?.cancel();
    _cancelAutoSaveTimers();
    _disposeAllControllers();
    _restTimer.dispose();
    sessionProgressTick.dispose();
    restRemaining.dispose();
    restTotal.dispose();
    restRunning.dispose();
    restSessionActive.dispose();
    for (final n in _exerciseRevision.values) {
      n.dispose();
    }
    _exerciseRevision.clear();
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

  Future<SessionChangeEvaluation> evaluateProgramChangeTo(
    String newProgramId,
  ) async {
    if (newProgramId.trim().isEmpty) {
      return const SessionChangeEvaluation.none();
    }
    final facade = _facade ?? LiveWorkoutFacade();
    return facade.evaluateProgramChange(programId: newProgramId);
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
    _bumpExerciseUi(exerciseKey, bumpProgress: false);
  }

  void scheduleAutoSave(String exerciseKey, int setIndex) {
    if (_isDisposed || _isLoadingSetData || _suppressAutoSave) return;

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
        _refreshExerciseCoachFeedback(exerciseKey, notify: false);
        _bumpExerciseUi(exerciseKey);
      }
      return;
    }

    _autoSaveTimers[setKey] = Timer(const Duration(seconds: 1), () {
      if (_isDisposed) return;
      saveSet(exerciseKey, setIndex);
    });
  }

  /// Numpad open → edits stay in UI until explicit commit.
  void setSuppressAutoSave(bool suppress) {
    _suppressAutoSave = suppress;
    if (!suppress) return;
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
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

      // بدون notifyListeners کل صفحه — فقط کارت همین حرکت + نوار پیشرفت.
      _state = _state.copyWith(
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
      );
      _refreshExerciseCoachFeedback(exerciseKey, notify: false);
      if (wasSaved != hasData || hasData) {
        _bumpExerciseUi(exerciseKey);
      }
      _scheduleDraftSave();
      _scheduleRemoteSave();
      _maybeFinalizeWorkout();
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[LiveWorkout] saveSet error: $error');
      }
      if (savedStatus != null && savedStatus.length > setIndex && !wasSaved) {
        savedStatus[setIndex] = false;
        _bumpExerciseUi(exerciseKey);
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

  /// Uncheck a set: keep field values, mark pending (Hevy/Strong-style soft uncheck).
  void unsaveSet(String exerciseKey, int setIndex) {
    if (_isDisposed) return;
    final exerciseIndex = _exerciseIndexByKey[exerciseKey];
    final session = _state.session;
    if (exerciseIndex == null || session == null) return;
    if (setIndex < 0) return;

    final savedStatus = _setSavedStatus[exerciseKey];
    if (savedStatus == null ||
        setIndex < 0 ||
        setIndex >= savedStatus.length ||
        !savedStatus[setIndex]) {
      return;
    }

    savedStatus[setIndex] = false;

    _state = _state.copyWith(
      session: session.updateSet(
        exerciseIndex: exerciseIndex,
        setIndex: setIndex,
        status: WorkoutSetSessionStatus.pending,
      ),
    );
    _refreshExerciseCoachFeedback(exerciseKey, notify: false);
    _bumpExerciseUi(exerciseKey);
    _scheduleDraftSave();
    _scheduleRemoteSave();
  }

  void startRest({required int seconds}) {
    if (_isDisposed) return;
    _restTimer.start(seconds: seconds);
    _publishRestNotifiers();
    _syncRestIntoState(scheduleDraft: true);
  }

  void toggleRestPause() {
    if (_isDisposed || !_restTimer.isActive) return;
    if (_restTimer.isPaused) {
      _restTimer.resume();
    } else {
      _restTimer.pause();
    }
    _publishRestNotifiers();
    _syncRestIntoState();
  }

  void skipRest() {
    if (_isDisposed) return;
    _restTimer.skip();
    _publishRestNotifiers();
    _syncRestIntoState(scheduleDraft: true);
  }

  void adjustRestBy(int deltaSeconds) {
    if (_isDisposed) return;
    _restTimer.adjustRemaining(deltaSeconds);
    _publishRestNotifiers();
    _syncRestIntoState(scheduleDraft: true);
  }

  void _publishRestNotifiers() {
    if (_isDisposed) return;
    final remaining = _restTimer.remainingSeconds;
    final active = _restTimer.isActive && remaining > 0;
    restRemaining.value = remaining;
    restTotal.value = _restTimer.totalSeconds;
    restRunning.value = active && !_restTimer.isPaused;
    restSessionActive.value = active;
  }

  /// فقط state داخلی برای draft — بدون rebuild کل صفحه.
  void _syncRestIntoState({bool scheduleDraft = false}) {
    if (_isDisposed) return;
    _state = _state.copyWith(
      rest: LiveWorkoutRestState(
        active: _restTimer.isActive,
        paused: _restTimer.isPaused,
        remainingSeconds: _restTimer.remainingSeconds,
        totalSeconds: _restTimer.totalSeconds,
      ),
    );
    if (scheduleDraft) {
      _scheduleDraftSave();
    }
  }

  void _handleRestTick() {
    if (_isDisposed) return;
    _publishRestNotifiers();
    _syncRestIntoState(scheduleDraft: !_restTimer.isActive);
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
      await _loadPreviousExercisePerformance();
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
    await _loadPreviousExercisePerformance();
    await _restoreCompletionSummaryIfNeeded();
    await _restorePersistedAnalysisIfNeeded();
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
      feedbackByExerciseKey: Map<String, WorkoutExerciseCoachFeedback>.from(
        _exerciseCoachFeedback,
      ),
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

      final pass = await AiProgramAccess().load(userId: userId);
      if (_isDisposed) return;
      if (!pass.hasPass) {
        // Expired pass: drop draft so it cannot silently continue logging.
        await _sessionStore.clearDraft(userId);
        if (_isDisposed) return;
        _setState(
          const LiveWorkoutState.error(
            'دسترسی برنامه مربی هوشمند فعال نیست. '
            'لاگ‌های قبلی در تقویم می‌مانند؛ برای لایو هوشمند دوباره برنامه بخر.',
          ),
        );
        return;
      }

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

  Future<SessionAnalysisSnapshot?> finishWorkout({
    bool openAnalysis = false,
  }) async {
    if (_isDisposed || _isCompleting || !_state.isLoaded) return null;
    flushPendingSetSaves();

    final session = _state.session;
    final userId = _state.userId;
    if (session == null || userId == null) return null;

    _isCompleting = true;
    _safeNotifyListeners();
    try {
      // Heatmap needs catalog muscle targets — ensure details are loaded.
      if (_exerciseDetails.isEmpty) {
        await loadExerciseDetails();
        if (_isDisposed) return null;
      }

      _remoteSaveTimer?.cancel();
      await _persistRemote();
      if (_isDisposed) return null;

      final finishFeedback = WorkoutLogSessionBridge.buildFeedbackMap(
        session: session,
        previousByExerciseId: _previousSetsByExerciseId,
      );
      _exerciseCoachFeedback
        ..clear()
        ..addAll(finishFeedback);

      final result = await _completionService.complete(
        session: session,
        userId: userId,
        exerciseById: Map<int, Exercise>.from(_exerciseDetails),
        feedbackByExerciseKey: Map<String, WorkoutExerciseCoachFeedback>.from(
          finishFeedback,
        ),
      );
      if (_isDisposed) return null;
      await _sessionStore.clearDraft(userId);
      _restTimer.stop();
      _publishRestNotifiers();
      ProductAnalytics.track(
        ProductAnalyticsEvent.workoutFinished,
        properties: <String, Object?>{
          'completedSets': savedSetsCount,
          'totalSets': session.totalSets,
        },
      );
      _justCompletedForAnalysis = true;
      final snapshot = await buildAnalysisSnapshot(
        debrief: result.debrief,
        observations: result.observations,
        synced: result.persistence.synced,
      );
      _sessionAnalysis = snapshot;
      if (snapshot != null && userId.isNotEmpty) {
        final date = _sessionDate(session);
        await SessionAnalysisStore.save(
          userId: userId,
          date: date,
          snapshot: snapshot,
        );
        await _sessionPersistence.attachSessionAnalysis(
          session: session,
          userId: userId,
          analysis: Map<String, dynamic>.from(snapshot.toJson()),
        );
      }
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

      return snapshot;
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[LiveWorkout] finishWorkout: $error');
      }
      return null;
    } finally {
      _isCompleting = false;
      _safeNotifyListeners();
    }
  }

  /// Builds analysis payload for the current (or just-finished) session.
  Future<SessionAnalysisSnapshot?> buildAnalysisSnapshot({
    SessionDebrief? debrief,
    List<CoachObservation>? observations,
    bool synced = true,
  }) async {
    final session = _state.session;
    if (session == null) return null;

    final finishFeedback = WorkoutLogSessionBridge.buildFeedbackMap(
      session: session,
      previousByExerciseId: _previousSetsByExerciseId,
    );

    final effectiveDebrief =
        debrief ??
        SessionDebriefEngine.build(
          session: session,
          feedbackByExerciseKey: finishFeedback,
        );
    final effectiveObservations =
        observations ?? CoachObservationDetector.fromDebrief(effectiveDebrief);

    double? bodyWeightKg;
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      bodyWeightKg = double.tryParse(profile?['weight']?.toString() ?? '');
    } on Object {
      bodyWeightKg = null;
    }

    return SessionAnalysisAssembler.assemble(
      session: session,
      programKind: SessionAnalysisProgramKind.aiSupervised,
      debrief: effectiveDebrief,
      exerciseById: Map<int, Exercise>.from(_exerciseDetails),
      feedbackByExerciseKey: Map<String, WorkoutExerciseCoachFeedback>.from(
        finishFeedback,
      ),
      previousByExerciseId: Map<int, List<PreviousExerciseSet>>.from(
        _previousSetsByExerciseId,
      ),
      previousLogDateByExerciseId: Map<int, DateTime>.from(
        _previousLogDateByExerciseId,
      ),
      observations: effectiveObservations,
      programTitle: _state.activeProgram?.title,
      sessionDay: _state.sessionContext?.selectedSessionDay,
      bodyWeightKg: bodyWeightKg,
      synced: synced,
    );
  }

  /// Attach a prebuilt analysis snapshot (same-screen mode).
  void showAnalysis(SessionAnalysisSnapshot snapshot) {
    _sessionAnalysis = snapshot;
    _safeNotifyListeners();
  }

  void resumeSessionEditing() {
    _sessionAnalysis = null;
    _suppressAutoFinalize = true;
    _setState(
      _state.copyWith(clearCompletionSummary: true),
      syncControllers: false,
    );
    unawaited(_clearPersistedAnalysis());
  }

  Future<void> rememberAnalysisNarrative(String text) async {
    final current = _sessionAnalysis;
    final session = _state.session;
    final userId = _state.userId;
    if (current == null || session == null || userId == null || _isDisposed) {
      return;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty || current.coachNarrative == trimmed) return;
    _sessionAnalysis = current.copyWith(coachNarrative: trimmed);
    await SessionAnalysisStore.save(
      userId: userId,
      date: _sessionDate(session),
      snapshot: _sessionAnalysis!,
    );
    unawaited(
      _sessionPersistence.attachSessionAnalysis(
        session: session,
        userId: userId,
        analysis: Map<String, dynamic>.from(_sessionAnalysis!.toJson()),
      ),
    );
  }

  Future<void> _clearPersistedAnalysis() async {
    final session = _state.session;
    final userId = _state.userId;
    if (session == null || userId == null || userId.isEmpty) return;
    await SessionAnalysisStore.clear(
      userId: userId,
      date: _sessionDate(session),
    );
    await _sessionPersistence.attachSessionAnalysis(
      session: session,
      userId: userId,
    );
  }

  Future<void> _restorePersistedAnalysisIfNeeded() async {
    if (_isDisposed || !_state.isLoaded || _sessionAnalysis != null) return;
    final session = _state.session;
    final userId = _state.userId;
    if (session == null || userId == null || userId.isEmpty) return;
    if (savedSetsCount <= 0) return;

    Map<String, dynamic>? embedded;
    try {
      final dailyLog = await _workoutLogService.getDailyLogByDate(
        userId,
        _sessionDate(session),
        preferRemote: true,
      );
      if (dailyLog != null) {
        for (final item in dailyLog.sessions) {
          final sameProgram =
              (item.programId?.trim() ?? '').isEmpty ||
              (session.programId?.trim() ?? '').isEmpty ||
              item.programId == session.programId;
          if (sameProgram) {
            embedded = item.sessionAnalysis;
            if (embedded != null) break;
          }
        }
      }
    } on Object {
      embedded = null;
    }

    final restored = await SessionAnalysisStore.load(
      userId: userId,
      date: _sessionDate(session),
      programId: session.programId,
      sessionDay: _state.sessionContext?.selectedSessionDay ?? session.focus,
      embeddedJson: embedded,
    );
    if (_isDisposed || restored == null) return;
    _sessionAnalysis = restored;
    _suppressAutoFinalize = true;
  }

  DateTime _sessionDate(WorkoutSession session) {
    final started = session.startedAt;
    return DateTime(started.year, started.month, started.day);
  }

  bool get canFinishAndAnalyze {
    if (!_state.isLoaded || _state.completionSummary != null) return false;
    return savedSetsCount > 0;
  }

  void consumeJustCompletedForAnalysis() {
    _justCompletedForAnalysis = false;
  }

  void _maybeFinalizeWorkout() {
    if (_isDisposed || !_state.isLoaded || _isCompleting) return;
    if (_suppressAutoFinalize) return;
    if (_state.completionSummary != null) return;
    if (savedSetsCount < totalSetsCount || totalSetsCount == 0) return;
    unawaited(finishWorkout());
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
    } on DayWorkoutConflictException catch (error) {
      if (kDebugMode) {
        debugPrint('[LiveWorkout] day identity conflict: $error');
      }
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
      if (notify) _bumpExerciseUi(exerciseKey, bumpProgress: false);
      return;
    }

    final controllers = _exerciseControllers[exerciseKey];
    final savedStatus = _setSavedStatus[exerciseKey];
    if (controllers == null || savedStatus == null) {
      _exerciseCoachFeedback.remove(exerciseKey);
      if (notify) _bumpExerciseUi(exerciseKey, bumpProgress: false);
      return;
    }

    final details = _exerciseDetails[exercise.exerciseId];
    final previous = _previousSetsByExerciseId[exercise.exerciseId];
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
      previousSets: previous,
    );

    if (feedback == null) {
      _exerciseCoachFeedback.remove(exerciseKey);
    } else {
      _exerciseCoachFeedback[exerciseKey] = feedback;
    }
    if (notify) _bumpExerciseUi(exerciseKey, bumpProgress: false);
  }

  Future<void> _loadPreviousExercisePerformance() async {
    if (_isDisposed) return;
    final session = _state.session;
    final userId =
        _state.userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (session == null || userId == null || userId.isEmpty) {
      _previousSetsByExerciseId.clear();
      _previousLogDateByExerciseId.clear();
      return;
    }

    final ids = <int>{};
    for (final exercise in session.exercises) {
      final id = exercise.exerciseId;
      if (id != null) ids.add(id);
    }
    if (ids.isEmpty) {
      _previousSetsByExerciseId.clear();
      _previousLogDateByExerciseId.clear();
      return;
    }

    try {
      final before = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );
      final logs = await _workoutLogService.getRecentLogsBeforeDate(
        userId,
        before,
      );
      if (_isDisposed) return;
      final mapped = PreviousExercisePerformance.fromLogsWithMeta(
        logs: logs,
        exerciseIds: ids,
      );
      _previousSetsByExerciseId
        ..clear()
        ..addAll({for (final e in mapped.entries) e.key: e.value.sets});
      _previousLogDateByExerciseId
        ..clear()
        ..addAll({
          for (final e in mapped.entries)
            if (e.value.logDate != null) e.key: e.value.logDate!,
        });
      _refreshAllExerciseCoachFeedback();
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[LiveWorkout] previous performance: $error');
      }
      if (!_isDisposed) {
        _previousSetsByExerciseId.clear();
        _previousLogDateByExerciseId.clear();
      }
    }
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
