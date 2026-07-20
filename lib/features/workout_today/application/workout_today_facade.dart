import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/product_experience/coach_experience_runtime_bridge.dart';
import 'package:gymaipro/features/product_experience/coach_feature_integration.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/features/product_experience/coach_resolved_program.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/features/product_experience/training_metric_guides.dart';
import 'package:gymaipro/features/workout_today/application/workout_today_facade_result.dart';
import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';
import 'package:gymaipro/features/workout_today/state/workout_today_state.dart';

@Deprecated('Use CoachFeatureLoader')
typedef WorkoutTodayPreviewLoader = CoachFeatureLoader;

/// Facade between Workout Today UI and the Coach pipeline.
class WorkoutTodayFacade {
  WorkoutTodayFacade({
    CoachFeatureLoader? coachLoader,
    @Deprecated('Use coachLoader') CoachFeatureLoader? previewLoader,
    CoachPreviewSeedProvider? seedLoader,
    CoachProgramResolver? programResolver,
    CoachExperienceRuntimeBridge? runtimeBridge,
    ActiveProgramCatalogService? programCatalog,
    WorkoutSessionSelectionGateway? sessionGateway,
  }) : _coachLoader =
           coachLoader ??
           previewLoader ??
           CoachFeatureIntegration.defaultLoader(),
       _seedLoader = seedLoader,
       _programResolver = programResolver ?? CoachProgramResolver(),
       _runtimeBridge = runtimeBridge ?? const CoachExperienceRuntimeBridge(),
       _programCatalog = programCatalog ?? ActiveProgramCatalogService(),
       _sessionGateway = sessionGateway ?? ActiveWorkoutSessionService();

  final CoachFeatureLoader _coachLoader;
  final CoachPreviewSeedProvider? _seedLoader;
  final CoachProgramResolver _programResolver;
  final CoachExperienceRuntimeBridge _runtimeBridge;
  final ActiveProgramCatalogService _programCatalog;
  final WorkoutSessionSelectionGateway _sessionGateway;

  CoachIntegrationResult? _lastResult;
  CoachResolvedTodayWorkout? _lastResolved;
  ActiveProgramOption? _activeProgram;

  Future<WorkoutTodayFacadeResult> load({bool enrichWithCoach = false}) async {
    final programs = await _programCatalog.listWorkoutPrograms();
    _activeProgram = await _programCatalog.getActiveProgramOption() ??
        programs.firstOrNull;

    const message = 'تمرین امروز چیه؟';
    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: AIIntent.workoutToday,
      message: message,
    );

    if (_activeProgram == null) {
      return WorkoutTodayFacadeResult(
        state: const WorkoutTodayState.empty(),
        gaps: const <String>['برنامه فعال برای امروز پیدا نشد.'],
        previewDuration: Duration.zero,
      );
    }

    CoachIntegrationResult? result;
    if (enrichWithCoach) {
      result = await _coachLoader(
        userMessage: message,
        userId: seed.userId,
        context: seed.context,
        metadata: const <String, Object?>{'feature': 'workout_today'},
      );
      _lastResult = result;
    }

    return _buildFromProgram(
      program: _activeProgram!,
      seedContext: seed.context,
      integrationResult: result,
      availablePrograms: programs,
    );
  }

  Future<WorkoutTodayFacadeResult> reloadForProgram(String programId) async {
    await _programCatalog.activateProgram(programId);
    await _sessionGateway.clearSelection();
    // One live session per day: drop any prior draft when program changes.
    await _sessionGateway.applySessionChangeCleanup(sessionDayToDelete: '');
    return load();
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

  Future<SessionChangeEvaluation> evaluateProgramChange({
    required String programId,
  }) async {
    final context = await _sessionGateway.loadContext(programId: programId);
    return _sessionGateway.evaluateProgramChange(context: context);
  }

  Future<WorkoutTodayFacadeResult> selectSession({
    required String programId,
    required String sessionDay,
    bool enrichWithCoach = false,
  }) async {
    await _sessionGateway.saveSelection(
      programId: programId,
      sessionDay: sessionDay,
    );
    return load(enrichWithCoach: enrichWithCoach);
  }

  Future<WorkoutTodayQuickActionResult> runQuickAction(String actionId) async {
    final normalized =
        CoachExperienceRuntimeBridge.normalizeQuickActionId(actionId);
    final prompt = ProductExperienceFormatter.promptForQuickAction(normalized);
    final routeName = switch (normalized) {
      'modify' ||
      'modify_program' ||
      'modify_workout' ||
      'replace' ||
      'replace_exercise' => '/program-modify',
      _ => '/coach-chat',
    };

    final result = _lastResult;
    if (result != null && routeName == '/coach-chat') {
      final lines = _runtimeBridge.runQuickActionMessages(
        actionId: normalized,
        program: _lastResolved?.aiProgram,
        context: result.coachContext,
      );
      if (lines.isNotEmpty) {
        return WorkoutTodayQuickActionResult(
          message: lines.join('\n'),
          routeName: routeName,
          previewMessage: prompt,
        );
      }
    }

    return WorkoutTodayQuickActionResult(
      message: prompt,
      routeName: routeName,
      previewMessage: prompt,
    );
  }

  Future<WorkoutTodayFacadeResult> map(CoachIntegrationResult result) async {
    _lastResult = result;
    final programs = await _programCatalog.listWorkoutPrograms();
    _activeProgram = await _programCatalog.getActiveProgramOption() ??
        programs.firstOrNull;
    if (_activeProgram == null) {
      return WorkoutTodayFacadeResult(
        state: const WorkoutTodayState.empty(),
        gaps: const <String>['برنامه فعال برای امروز پیدا نشد.'],
        previewDuration: result.processingTime,
      );
    }
    return _buildFromProgram(
      program: _activeProgram!,
      seedContext: result.coachContext,
      integrationResult: result,
      availablePrograms: programs,
      previewDuration: result.processingTime,
    );
  }

  Future<WorkoutTodayFacadeResult> _buildFromProgram({
    required ActiveProgramOption program,
    required CoachContext seedContext,
    CoachIntegrationResult? integrationResult,
    required List<ActiveProgramOption> availablePrograms,
    Duration previewDuration = Duration.zero,
  }) async {
    final gaps = <String>[];
    final sessionContext = await _sessionGateway.loadContext(
      programId: program.id,
      userId: seedContext.profile['id']?.toString(),
    );

    if (sessionContext.needsSessionSelection) {
      return WorkoutTodayFacadeResult(
        state: WorkoutTodayState.awaitingSession(
          activeProgram: program,
          availablePrograms: availablePrograms,
          sessionContext: sessionContext,
        ),
        gaps: List<String>.unmodifiable(gaps),
        previewDuration: previewDuration,
      );
    }

    final sessionDay = sessionContext.selectedSessionDay!;
    CoachResolvedTodayWorkout? resolved;
    if (integrationResult != null) {
      resolved = await _programResolver.resolve(result: integrationResult);
    }
    resolved ??= await _programResolver.resolveStoredProgram(
      program.id,
      sessionDay: sessionDay,
    );
    _lastResolved = resolved;

    if (resolved == null || resolved.exercises.isEmpty) {
      gaps.add('برنامه فعال برای امروز پیدا نشد.');
      return WorkoutTodayFacadeResult(
        state: WorkoutTodayState.empty(
          availablePrograms: availablePrograms,
          activeProgram: program,
        ),
        gaps: List<String>.unmodifiable(gaps),
        previewDuration: previewDuration,
      );
    }

    final context = integrationResult?.coachContext ?? seedContext;
    final recovery = ProductExperienceFormatter.recoverySnapshot(
      context: context,
      result: integrationResult,
    );

    final review = _runtimeBridge.reviewProgram(
      program: resolved.aiProgram,
      context: context,
    );
    final engineReasons = integrationResult == null
        ? const <String>[]
        : ProductExperienceFormatter.explainabilityReasons(
            result: integrationResult,
            context: context,
            reviewResult: review,
            generatorReasons: resolved.aiProgram?.programReasons ?? const [],
          );
    final reasons = engineReasons.isEmpty
        ? _defaultReasons(program, resolved, sessionDay)
        : engineReasons;

    final coachNotes = _mergeCoachNotes(
      program: program,
      resolved: resolved,
      readiness: recovery.readiness,
      daysSinceLastWorkout: recovery.daysSinceLastWorkout,
      sessionDay: sessionDay,
      fromEngine: integrationResult == null
          ? const <String>[]
          : ProductExperienceFormatter.coachNotes(integrationResult),
    );

    final exercises = resolved.exercises
        .map(ProductExperienceFormatter.timelineExercise)
        .toList(growable: false);

    return WorkoutTodayFacadeResult(
      state: WorkoutTodayState.loaded(
        WorkoutTodayData(
          workout: WorkoutTodayDomainModel(
            userName: _profileName(context),
            headline: ProductExperienceFormatter.workoutHeadline(
              workout: resolved,
              result: integrationResult,
              muscleGroups: resolved.muscleGroups,
            ),
            recoveryPercent: recovery.readiness,
            durationMinutes: resolved.durationMinutes,
            exercises: exercises,
            totalSets: resolved.totalSets,
            muscleGroups: resolved.muscleGroups,
            intensity: resolved.intensity,
            coachNotes: coachNotes,
            reasons: reasons,
            readinessHint: TrainingMetricGuides.readinessHint(
              recovery.readiness,
              daysSinceLastWorkout: recovery.daysSinceLastWorkout,
            ),
          ),
          quickActions: _quickActions,
          activeProgram: program,
          availablePrograms: availablePrograms,
          sessionContext: sessionContext,
        ),
      ),
      gaps: List<String>.unmodifiable(gaps),
      previewDuration: previewDuration,
    );
  }

  /// Grounded session facts first; clean engine tips only if they add something real.
  List<String> _mergeCoachNotes({
    required ActiveProgramOption program,
    required CoachResolvedTodayWorkout resolved,
    required int readiness,
    required String sessionDay,
    required List<String> fromEngine,
    int? daysSinceLastWorkout,
  }) {
    final grounded = _defaultCoachNotes(
      program,
      resolved,
      readiness,
      sessionDay,
      daysSinceLastWorkout: daysSinceLastWorkout,
    );
    if (fromEngine.isEmpty) return grounded;

    final merged = <String>[];
    final seen = <String>{};
    void add(String raw) {
      final note = raw.trim();
      if (note.isEmpty || !seen.add(note) || merged.length >= 3) return;
      merged.add(note);
    }

    // Always lead with the real session line.
    if (grounded.isNotEmpty) add(grounded.first);
    for (final tip in fromEngine) {
      add(tip);
    }
    for (final rest in grounded.skip(1)) {
      add(rest);
    }
    return merged;
  }

  List<String> _defaultCoachNotes(
    ActiveProgramOption program,
    CoachResolvedTodayWorkout resolved,
    int readiness,
    String sessionDay, {
    int? daysSinceLastWorkout,
  }) {
    final notes = <String>[
      'امروز جلسه «$sessionDay» از برنامه «${program.title}» را می‌زنی.',
    ];

    if (resolved.muscleGroups.isNotEmpty) {
      final muscles = resolved.muscleGroups.take(3).join('، ');
      notes.add('تمرکز امروز روی $muscles است.');
    }

    if (resolved.totalSets > 0) {
      final sets = resolved.totalSets;
      notes.add(
        'حدود $sets ست در این جلسه داری؛ دو ست اول را کنترل‌شده بزن، بعد فشار را بالا ببر.',
      );
    }

    final hint = TrainingMetricGuides.readinessHint(
      readiness,
      daysSinceLastWorkout: daysSinceLastWorkout,
    ).trim();
    if (hint.isNotEmpty && notes.length < 3) {
      notes.add(hint.endsWith('.') ? hint : '$hint.');
    }

    return notes.take(3).toList(growable: false);
  }

  List<String> _defaultReasons(
    ActiveProgramOption program,
    CoachResolvedTodayWorkout resolved,
    String sessionDay,
  ) {
    final reasons = <String>[
      'این جلسه ($sessionDay) از برنامه فعال «${program.title}» آمده است.',
    ];
    final focus = resolved.focus.trim();
    if (focus.isNotEmpty) {
      reasons.add('تمرکز جلسه امروز: $focus.');
    }
    if (resolved.exercises.isNotEmpty) {
      final count = resolved.exercises.length;
      reasons.add('$count حرکت برای امروز چیده شده است.');
    }
    return reasons;
  }

  String _profileName(CoachContext context) {
    final firstName = context.profile['first_name']?.toString().trim();
    if (firstName != null && firstName.isNotEmpty) return firstName;
    return 'ورزشکار';
  }

  static const List<WorkoutTodayQuickAction> _quickActions =
      <WorkoutTodayQuickAction>[
        WorkoutTodayQuickAction(
          id: 'modify',
          label: 'اصلاح برنامه',
          routeName: '/program-modify',
        ),
        WorkoutTodayQuickAction(
          id: 'review',
          label: 'تحلیل برنامه',
          routeName: '/coach-chat',
        ),
        WorkoutTodayQuickAction(
          id: 'low_motivation',
          label: 'امروز حوصله ندارم',
          routeName: '/coach-chat',
        ),
        WorkoutTodayQuickAction(
          id: 'ask',
          label: 'پرسش از مربی',
          routeName: '/coach-chat',
        ),
      ];
}

class WorkoutTodayQuickActionResult {
  const WorkoutTodayQuickActionResult({
    required this.message,
    this.routeName,
    this.previewMessage,
  });

  final String message;
  final String? routeName;
  final String? previewMessage;
}
