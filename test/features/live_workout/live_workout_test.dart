import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_execution_result.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_completion_service.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_facade.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_facade_result.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_factory.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_persistence.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_store.dart';
import 'package:gymaipro/features/live_workout/domain/live_workout_domain_model.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/live_workout/navigation/live_workout_route.dart';
import 'package:gymaipro/features/live_workout/presentation/screens/live_workout_screen.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_completion_summary.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';
import 'package:gymaipro/features/live_workout/view_models/live_workout_view_model.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/muscle_heatmap_aggregate.dart';
import 'package:gymaipro/services/route_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  test('LiveWorkoutFacade maps activeProgram', () async {
    final facade = LiveWorkoutFacade(
      seedLoader: const _FakeSeedLoader(),
      programCatalog: _StubProgramCatalog(_testProgram),
      sessionGateway: const _FakeSessionGateway(selectedDay: 'Upper'),
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
    );

    final result = await facade.map(
      _integrationResult(activeProgram: _activeProgram),
      userId: 'user_1',
    );

    expect(result.state.isLoaded, true);
    expect(result.state.session!.totalExercises, 2);
    expect(result.state.session!.totalSets, 5);
    expect(result.state.session!.currentSetPointer, isNull);
  });

  test('LiveWorkoutFacade returns awaitingSession without day pick', () async {
    final facade = LiveWorkoutFacade(
      programCatalog: _StubProgramCatalog(_testProgram),
      sessionGateway: const _FakeSessionGateway(selectedDay: null),
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
    );

    final result = await facade.map(
      _integrationResult(activeProgram: _activeProgram),
    );

    expect(result.state.isAwaitingSession, true);
  });

  test('LiveWorkoutFacade returns empty without workout data', () async {
    final facade = LiveWorkoutFacade(
      programCatalog: _StubProgramCatalog(_testProgram),
      sessionGateway: const _FakeSessionGateway(selectedDay: 'Upper'),
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
    );

    final mapped = await facade.map(
      _integrationResult(activeProgram: const <String, Object?>{}),
    );

    expect(mapped.state.isEmpty, true);
  });

  test('LiveWorkoutViewModel saves sets in real time', () async {
    final session = const LiveWorkoutSessionFactory().fromPreview(
      preview: _previewSession(),
      userId: 'user_1',
    );
    final viewModel = LiveWorkoutViewModel(
      facade: _FakeLiveWorkoutFacade(
        LiveWorkoutFacadeResult(
          state: LiveWorkoutState.loaded(
            session: session,
            userId: 'user_1',
          ),
        ),
      ),
      sessionStore: _NoopSessionStore(),
      completionService: _FakeCompletionService(),
    );

    await viewModel.load();
    final exerciseKey =
        viewModel.displayExercises.first.exerciseId.toString();
    viewModel.exerciseControllers[exerciseKey]![0]['reps']!.text = '10';
    viewModel.exerciseControllers[exerciseKey]![0]['weight']!.text = '60';
    viewModel.saveSet(exerciseKey, 0);

    expect(viewModel.savedSetsCount, 1);
    expect(viewModel.setSavedStatus[exerciseKey]![0], isTrue);
    expect(
      viewModel.state.session!.exercises.first.sets.first.actualReps,
      10,
    );
  });

  test('LiveWorkoutViewModel finalizes workout when all sets saved', () async {
    final session = const LiveWorkoutSessionFactory().fromPreview(
      preview: _previewSession(),
      userId: 'user_1',
    );
    var completed = session;
    for (var exerciseIndex = 0; exerciseIndex < session.exercises.length; exerciseIndex++) {
      final exercise = session.exercises[exerciseIndex];
      for (var setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
        completed = completed.advanceAfterSet(
          exerciseIndex: exerciseIndex,
          setIndex: setIndex,
          terminalStatus: WorkoutSetSessionStatus.completed,
        );
      }
    }

    final viewModel = LiveWorkoutViewModel(
      initialState: LiveWorkoutState.loaded(
        session: completed,
        userId: 'user_1',
      ),
      sessionStore: _NoopSessionStore(),
      completionService: _FakeCompletionService(),
    );

    await viewModel.finishWorkout();

    expect(viewModel.state.isLoaded, isTrue);
    expect(viewModel.state.completionSummary, isNotNull);
    expect(viewModel.state.session, isNotNull);
    expect(viewModel.isCompleting, isFalse);
  });

  testWidgets('LiveWorkoutScreen renders loaded session', (tester) async {
    final session = const LiveWorkoutSessionFactory().fromPreview(
      preview: _previewSession(),
      userId: 'user_1',
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          home: LiveWorkoutScreen(
            autoLoad: false,
            viewModel: LiveWorkoutViewModel(
              initialState: LiveWorkoutState.loaded(
                session: session,
                userId: 'user_1',
                coachTips: const <String>['Keep your form tight.'],
                explainability: const <String>['Preview selected today workout.'],
              ),
              sessionStore: _NoopSessionStore(),
            ),
          ),
        ),
      ),
    );

    expect(find.text(ProductCopy.workoutSession), findsOneWidget);
    expect(find.text('Pull Day'), findsWidgets);
    expect(find.text(ProductCopy.liveSessionInProgress), findsOneWidget);
    expect(find.text('Bench Press'), findsWidgets);
    expect(find.text('0/5 ست'), findsOneWidget);
    expect(find.text(ProductCopy.completeSet), findsNothing);
  });

  testWidgets('LiveWorkoutRoute is registered', (tester) async {
    final route = RouteService.generateRoute(
      const RouteSettings(name: LiveWorkoutRoute.routeName),
    );

    expect(route.settings.name, LiveWorkoutRoute.routeName);
  });
}

const Map<String, Object?> _activeProgram = <String, Object?>{
  'name': 'Workout Today',
  'focus': 'Pull Day',
  'durationMinutes': 75,
  'exercises': <Object?>[
    <String, Object?>{
      'name': 'Bench Press',
      'primaryMuscle': 'Chest',
      'sets': <Object?>[
        <String, Object?>{'order': 1, 'reps': 8, 'weightKg': 70},
        <String, Object?>{'order': 2, 'reps': 8, 'weightKg': 70},
      ],
    },
    <String, Object?>{
      'name': 'Lat Pulldown',
      'primaryMuscle': 'Back',
      'sets': 3,
      'reps': 10,
      'weightKg': 55,
    },
  ],
};

class _FakeSeedLoader implements CoachPreviewSeedProvider {
  const _FakeSeedLoader();

  @override
  Future<CoachPreviewSeed> load({
    required AIIntent intent,
    required String message,
  }) async {
    return CoachPreviewSeed(
      userId: 'user_1',
      intent: intent,
      message: message,
      context: CoachContext(
        intent: intent,
        activeProgram: _activeProgram,
        metadata: CoachContextMetadata(
          buildTime: DateTime(2026, 7, 13),
          sourceCount: 1,
          missingProviders: const {},
          confidence: 0.9,
          contextVersion: CoachContext.contextVersion,
        ),
      ),
    );
  }
}

const _testProgram = ActiveProgramOption(
  id: 'program_1',
  title: 'برنامه تست',
  creatorLabel: 'GymAI',
  isActive: true,
  isAiSupervised: true,
);

class _StubProgramCatalog extends ActiveProgramCatalogService {
  _StubProgramCatalog(this._active) : super();

  final ActiveProgramOption _active;

  @override
  Future<ActiveProgramOption?> getActiveProgramOption() async => _active;

  @override
  Future<List<ActiveProgramOption>> listWorkoutPrograms() async => [_active];
}

class _FakeSessionGateway implements WorkoutSessionSelectionGateway {
  const _FakeSessionGateway({required this.selectedDay});

  final String? selectedDay;

  @override
  Future<void> applySessionChangeCleanup({
    required String sessionDayToDelete,
    String? userId,
  }) async {}

  @override
  Future<void> clearSelection({String? userId}) async {}

  @override
  SessionChangeEvaluation evaluateSessionChange({
    required ActiveWorkoutSessionContext context,
    required String newSessionDay,
    String? currentSessionDay,
  }) {
    return const SessionChangeEvaluation.none();
  }

  @override
  SessionChangeEvaluation evaluateProgramChange({
    required ActiveWorkoutSessionContext context,
  }) {
    return const SessionChangeEvaluation.none();
  }

  @override
  Future<ActiveWorkoutSessionContext> loadContext({
    required String programId,
    String? userId,
  }) async {
    return ActiveWorkoutSessionContext(
      programId: programId,
      programName: 'برنامه تست',
      sessions: const [],
      selectedSessionDay: selectedDay,
      loggedSessionDay: null,
      hasSavedLog: false,
      hasLiveDraft: false,
    );
  }

  @override
  Future<void> saveSelection({
    required String programId,
    required String sessionDay,
    String? userId,
  }) async {}
}

class _FakeLiveWorkoutFacade extends LiveWorkoutFacade {
  _FakeLiveWorkoutFacade(this.result)
    : super(
        coachLoader: _unusedCoachLoader,
        programResolver: CoachProgramResolver(programLoader: (_) async => null),
      );

  final LiveWorkoutFacadeResult result;

  @override
  Future<LiveWorkoutFacadeResult> load({bool enrichWithCoach = false}) async =>
      result;

  @override
  Future<String> resolveUserId() async => 'user_1';
}

class _NoopSessionStore extends LiveWorkoutSessionStore {
  @override
  Future<LiveWorkoutDraft?> loadDraft(String userId) async => null;

  @override
  Future<void> saveDraft(LiveWorkoutDraft draft) async {}

  @override
  Future<void> clearDraft(String userId) async {}
}

class _FakeCompletionService extends LiveWorkoutCompletionService {
  @override
  Future<LiveWorkoutCompletionResult> complete({
    required WorkoutSession session,
    required String userId,
    Map<int, Exercise> exerciseById = const <int, Exercise>{},
  }) async {
    return LiveWorkoutCompletionResult(
      summary: LiveWorkoutCompletionSummary.fromSessionStats(
        focus: session.focus,
        completedSets: session.completedSets,
        totalSets: session.totalSets,
        totalVolumeKg: 1000,
        heatmap: MuscleHeatmapSnapshot.empty(),
        synced: true,
      ),
      persistence: const LiveWorkoutPersistenceResult(synced: true),
    );
  }
}

Never _unusedCoachLoader({
  required String userMessage,
  String userId = 'preview_user',
  CoachContext? context,
  Map<String, Object?> metadata = const <String, Object?>{},
}) {
  throw UnimplementedError();
}

CoachIntegrationResult _integrationResult({
  required Map<String, Object?> activeProgram,
}) {
  return CoachIntegrationResult.local(
    intent: AIIntent.workoutToday,
    coachContext: CoachContext(
      intent: AIIntent.workoutToday,
      activeProgram: activeProgram,
      metadata: CoachContextMetadata(
        buildTime: DateTime(2026, 7, 13),
        sourceCount: 1,
        missingProviders: const {},
        confidence: 0.9,
        contextVersion: CoachContext.contextVersion,
      ),
    ),
    skillExecution: CoachSkillExecutionResult(
      skillId: 'workout_today_skill',
      response: CoachSkillResponse(
        confidence: 0.9,
        requiresAI: false,
        message: 'preview',
        structuredData: <String, Object?>{'program': activeProgram},
        nextActions: const <String>['Keep your form tight.'],
      ),
      executionTime: const Duration(milliseconds: 1),
      success: true,
    ),
    processingTime: const Duration(milliseconds: 1),
    logs: const [],
    pipelineMode: CoachPipelineMode.runtime,
  );
}

LiveWorkoutSession _previewSession() {
  return const LiveWorkoutSession(
    title: 'Workout Today',
    focus: 'Pull Day',
    estimatedMinutes: 75,
    coachTips: <String>['Keep your form tight.'],
    explainability: <String>['Preview selected today workout.'],
    exercises: <LiveWorkoutExercise>[
      LiveWorkoutExercise(
        name: 'Bench Press',
        primaryMuscle: 'Chest',
        sets: <LiveWorkoutSet>[
          LiveWorkoutSet(index: 1, reps: 8, weightKg: 70),
          LiveWorkoutSet(index: 2, reps: 8, weightKg: 70),
        ],
      ),
      LiveWorkoutExercise(
        name: 'Lat Pulldown',
        primaryMuscle: 'Back',
        sets: <LiveWorkoutSet>[
          LiveWorkoutSet(index: 1, reps: 10, weightKg: 55),
          LiveWorkoutSet(index: 2, reps: 10, weightKg: 55),
          LiveWorkoutSet(index: 3, reps: 10, weightKg: 55),
        ],
      ),
    ],
  );
}
