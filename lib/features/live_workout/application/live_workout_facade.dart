import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_facade_result.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_factory.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_hydrator.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_store.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/product_experience/coach_experience_runtime_bridge.dart';
import 'package:gymaipro/features/product_experience/coach_feature_integration.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';

@Deprecated('Use CoachFeatureLoader')
typedef LiveWorkoutPreviewLoader = CoachFeatureLoader;

class LiveWorkoutFacade {
  LiveWorkoutFacade({
    CoachFeatureLoader? coachLoader,
    @Deprecated('Use coachLoader') CoachFeatureLoader? previewLoader,
    CoachPreviewSeedProvider? seedLoader,
    CoachProgramResolver? programResolver,
    CoachExperienceRuntimeBridge? runtimeBridge,
    LiveWorkoutSessionFactory? sessionFactory,
    ActiveProgramCatalogService? programCatalog,
    WorkoutSessionSelectionGateway? sessionGateway,
    WorkoutDailyLogService? logService,
    LiveWorkoutSessionHydrator? sessionHydrator,
  }) : _coachLoader =
           coachLoader ??
           previewLoader ??
           CoachFeatureIntegration.defaultLoader(),
       _seedLoader = seedLoader,
       _programResolver = programResolver ?? CoachProgramResolver(),
       _runtimeBridge = runtimeBridge ?? const CoachExperienceRuntimeBridge(),
       _sessionFactory = sessionFactory ?? const LiveWorkoutSessionFactory(),
       _programCatalog = programCatalog ?? ActiveProgramCatalogService(),
       _sessionGateway = sessionGateway ?? ActiveWorkoutSessionService(),
       _logService = logService ?? WorkoutDailyLogService(),
       _sessionHydrator = sessionHydrator ?? const LiveWorkoutSessionHydrator();

  final CoachFeatureLoader _coachLoader;
  final CoachPreviewSeedProvider? _seedLoader;
  final CoachProgramResolver _programResolver;
  final CoachExperienceRuntimeBridge _runtimeBridge;
  final LiveWorkoutSessionFactory _sessionFactory;
  final ActiveProgramCatalogService _programCatalog;
  final WorkoutSessionSelectionGateway _sessionGateway;
  final WorkoutDailyLogService _logService;
  final LiveWorkoutSessionHydrator _sessionHydrator;

  String? _lastUserId;

  Future<String> resolveUserId() async {
    if (_lastUserId != null && _lastUserId!.isNotEmpty) {
      return _lastUserId!;
    }
    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: AIIntent.workoutToday,
      message: 'تمرین امروزم رو شروع کن',
    );
    _lastUserId = seed.userId;
    return seed.userId;
  }

  Future<LiveWorkoutFacadeResult> load({bool enrichWithCoach = false}) async {
    const message = 'تمرین امروزم رو شروع کن';
    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: AIIntent.workoutToday,
      message: message,
    );
    _lastUserId = seed.userId;

    final activeProgram = await _programCatalog.getActiveProgramOption();
    if (activeProgram == null) {
      return LiveWorkoutFacadeResult(
        state: const LiveWorkoutState.empty(),
        gaps: const <String>['برنامه فعال در دسترس نبود.'],
        previewDuration: Duration.zero,
      );
    }

    if (enrichWithCoach) {
      final result = await _coachLoader(
        userMessage: message,
        userId: seed.userId,
        context: seed.context,
        metadata: const <String, Object?>{'feature': 'live_workout'},
      );
      return map(result, userId: seed.userId);
    }

    return _buildFromStored(
      programId: activeProgram.id,
      userId: seed.userId,
      readinessHint: _readinessHintFromContext(seed.context),
    );
  }

  WorkoutSessionSelectionGateway get sessionGateway => _sessionGateway;

  Future<SessionChangeEvaluation> evaluateSessionChange({
    required String programId,
    required String newSessionDay,
    String? currentSessionDay,
  }) async {
    final context = await _sessionGateway.loadContext(programId: programId);
    return _sessionGateway.evaluateSessionChange(
      context: context,
      newSessionDay: newSessionDay,
      currentSessionDay: currentSessionDay,
    );
  }

  /// Whether a local draft belongs to the currently selected program/session.
  Future<bool> draftMatchesActiveSelection({
    required String userId,
    required LiveWorkoutDraft draft,
  }) async {
    if (draft.session.exercises.isEmpty) return false;
    final activeProgram = await _programCatalog.getActiveProgramOption();
    if (activeProgram == null) return false;

    final sessionContext = await _sessionGateway.loadContext(
      programId: activeProgram.id,
      userId: userId,
    );
    final sessionDay = sessionContext.selectedSessionDay;
    if (sessionDay == null || sessionDay.isEmpty) return false;

    return ActiveWorkoutSessionService.draftMatchesSelection(
      programId: activeProgram.id,
      sessionDay: sessionDay,
      draftProgramId: draft.session.programId,
      draftFocus: draft.session.focus,
    );
  }

  Future<LiveWorkoutFacadeResult> selectSession({
    required String programId,
    required String sessionDay,
    required String userId,
  }) async {
    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: AIIntent.workoutToday,
      message: 'تمرین امروزم رو شروع کن',
    );
    await _sessionGateway.saveSelection(
      programId: programId,
      sessionDay: sessionDay,
      userId: userId,
    );
    return _buildFromStored(
      programId: programId,
      userId: userId,
      readinessHint: _readinessHintFromContext(seed.context),
    );
  }

  Future<LiveWorkoutFacadeResult> map(
    CoachIntegrationResult result, {
    String userId = 'preview_user',
  }) async {
    final gaps = <String>[];
    final active = await _programCatalog.getActiveProgramOption();
    if (active == null) {
      gaps.add('برنامه فعال در دسترس نبود.');
      return LiveWorkoutFacadeResult(
        state: const LiveWorkoutState.empty(),
        gaps: List<String>.unmodifiable(gaps),
        previewDuration: result.processingTime,
      );
    }

    final sessionContext = await _sessionGateway.loadContext(
      programId: active.id,
      userId: userId,
    );
    if (sessionContext.needsSessionSelection) {
      return LiveWorkoutFacadeResult(
        state: LiveWorkoutState.awaitingSession(
          activeProgram: active,
          sessionContext: sessionContext,
        ),
        gaps: List<String>.unmodifiable(gaps),
        previewDuration: result.processingTime,
      );
    }

    final sessionDay = sessionContext.selectedSessionDay!;
    var resolved = await _programResolver.resolve(result: result);
    if (resolved == null || resolved.exercises.isEmpty) {
      resolved = await _programResolver.resolveStoredProgram(
        active.id,
        sessionDay: sessionDay,
      );
    }
    if (resolved == null || resolved.exercises.isEmpty) {
      gaps.add('برنامه فعال در دسترس نبود.');
      return LiveWorkoutFacadeResult(
        state: const LiveWorkoutState.empty(),
        gaps: List<String>.unmodifiable(gaps),
        previewDuration: result.processingTime,
      );
    }

    final review = _runtimeBridge.reviewProgram(
      program: resolved.aiProgram,
      context: result.coachContext,
    );
    final reasons = ProductExperienceFormatter.explainabilityReasons(
      result: result,
      context: result.coachContext,
      reviewResult: review,
      generatorReasons: resolved.aiProgram?.programReasons ?? const [],
    );

    final coachTips = ProductExperienceFormatter.coachNotes(result);
    final session = await _hydrateToday(
      _sessionFactory.fromResolved(
        resolved: resolved,
        userId: userId,
        programId: resolved.aiProgram?.id,
      ),
      userId: userId,
    );

    return LiveWorkoutFacadeResult(
      state: LiveWorkoutState.loaded(
        session: session,
        userId: userId,
        coachTips: coachTips,
        explainability: reasons,
        readinessHint: _readinessHintFromContext(result.coachContext),
        activeProgram: active,
        sessionContext: sessionContext,
      ),
      gaps: List<String>.unmodifiable(gaps),
      previewDuration: result.processingTime,
    );
  }

  Future<LiveWorkoutFacadeResult> _buildFromStored({
    required String programId,
    required String userId,
    String? readinessHint,
  }) async {
    final activeProgram = await _programCatalog.getActiveProgramOption();
    final sessionContext = await _sessionGateway.loadContext(
      programId: programId,
      userId: userId,
    );

    if (sessionContext.needsSessionSelection) {
      return LiveWorkoutFacadeResult(
        state: LiveWorkoutState.awaitingSession(
          activeProgram: activeProgram,
          sessionContext: sessionContext,
        ),
        gaps: const <String>[],
        previewDuration: Duration.zero,
      );
    }

    final sessionDay = sessionContext.selectedSessionDay!;
    final resolved = await _programResolver.resolveStoredProgram(
      programId,
      sessionDay: sessionDay,
    );
    if (resolved == null || resolved.exercises.isEmpty) {
      return LiveWorkoutFacadeResult(
        state: const LiveWorkoutState.empty(),
        gaps: const <String>['برنامه فعال در دسترس نبود.'],
        previewDuration: Duration.zero,
      );
    }

    final reasons = <String>[
      'امروز «$sessionDay» را ثبت می‌کنی.',
      if (resolved.focus.trim().isNotEmpty &&
          resolved.focus.trim() != sessionDay.trim())
        'تمرکز این جلسه: ${resolved.focus}.',
    ];

    final coachTips = <String>[
      if (activeProgram != null)
        activeProgram.isAiSupervised
            ? 'برنامه «${activeProgram.title}» را با راهنمایی مربی هوشمند اجرا می‌کنی.'
            : 'برنامه «${activeProgram.title}» از ${activeProgram.creatorLabel} است؛ مربی هوشمند فقط در اجرا کمکت می‌کند.',
      'شدت تلاش اختیاری است — کنار فیلد روی راهنما بزن تا توضیح را ببینی.',
    ];

    final session = await _hydrateToday(
      _sessionFactory.fromResolved(
        resolved: resolved,
        userId: userId,
        programId: programId,
      ),
      userId: userId,
    );

    return LiveWorkoutFacadeResult(
      state: LiveWorkoutState.loaded(
        session: session,
        userId: userId,
        coachTips: coachTips,
        explainability: reasons,
        readinessHint: readinessHint,
        activeProgram: activeProgram,
        sessionContext: sessionContext,
      ),
      gaps: const <String>[],
      previewDuration: Duration.zero,
    );
  }

  Future<WorkoutSession> _hydrateToday(
    WorkoutSession session, {
    required String userId,
  }) async {
    final today = DateTime(
      session.startedAt.year,
      session.startedAt.month,
      session.startedAt.day,
    );
    try {
      final dailyLog = await _logService.getDailyLogByDate(
        userId,
        today,
        preferRemote: true,
      );
      return _sessionHydrator.applyLog(session: session, dailyLog: dailyLog);
    } on Object {
      return session;
    }
  }

  String? _readinessHintFromContext(CoachContext context) {
    final snapshot = ProductExperienceFormatter.recoverySnapshot(
      context: context,
    );
    return ProductExperienceFormatter.readinessHint(snapshot);
  }
}
