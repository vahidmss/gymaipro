import 'package:flutter/material.dart';
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
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/services/route_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  test('LiveWorkoutFacade maps activeProgram', () async {
    Map<String, Object?>? metadataSeen;
    final facade = LiveWorkoutFacade(
      seedLoader: const _FakeSeedLoader(),
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
      coachLoader: ({
        required userMessage,
        userId = 'preview_user',
        context,
        metadata = const <String, Object?>{},
      }) async {
        metadataSeen = metadata;
        expect(userMessage, 'تمرین امروزم رو شروع کن');
        expect(context, isNotNull);
        return _integrationResult(activeProgram: _activeProgram);
      },
    );

    final result = await facade.load();

    expect(metadataSeen?['feature'], 'live_workout');
    expect(result.state.isLoaded, true);
    expect(result.state.session!.totalExercises, 2);
    expect(result.state.session!.totalSets, 5);
    expect(
      result.state.session!.currentSet()?.status,
      WorkoutSetSessionStatus.current,
    );
  });

  test('LiveWorkoutFacade returns empty without workout data', () async {
    final facade = LiveWorkoutFacade(
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
      coachLoader: ({
        required userMessage,
        userId = 'preview_user',
        context,
        metadata = const <String, Object?>{},
      }) async {
        return _integrationResult(activeProgram: const <String, Object?>{});
      },
    );

    final mapped = await facade.map(
      _integrationResult(activeProgram: const <String, Object?>{}),
    );

    expect(mapped.state.isEmpty, true);
  });

  test('LiveWorkoutViewModel advances sets through session', () async {
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
    var guard = 0;
    while (!viewModel.state.isSessionCompleted && guard < 30) {
      guard++;
      if (viewModel.state.rest.active) {
        viewModel.skipRest();
      } else {
        viewModel.completePrimaryAction();
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    expect(viewModel.state.isSessionCompleted, true);
    expect(viewModel.state.completionSummary?.completedSets, session.totalSets);
  });

  test('LiveWorkoutViewModel persists completion summary', () async {
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

    expect(viewModel.state.isSessionCompleted, true);
    expect(viewModel.state.completionSummary?.completedSets, session.totalSets);
  });

  testWidgets('LiveWorkoutScreen renders loaded session', (tester) async {
    final session = const LiveWorkoutSessionFactory().fromPreview(
      preview: _previewSession(),
      userId: 'user_1',
    );
    await tester.pumpWidget(
      MaterialApp(
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
    );

    expect(find.text(ProductCopy.workoutSession), findsOneWidget);
    expect(find.text('Pull Day'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text(ProductCopy.sets), findsOneWidget);
    expect(
      find.text(ProductCopy.completeSet),
      findsOneWidget,
    );
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

class _FakeLiveWorkoutFacade extends LiveWorkoutFacade {
  _FakeLiveWorkoutFacade(this.result)
    : super(coachLoader: _unusedCoachLoader);

  final LiveWorkoutFacadeResult result;

  @override
  Future<LiveWorkoutFacadeResult> load() async => result;

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
    required List<String> coachTips,
    required List<String> explainability,
  }) async {
    return LiveWorkoutCompletionResult(
      summary: LiveWorkoutCompletionSummary(
        title: session.title,
        focus: session.focus,
        durationMinutes: 45,
        completedExercises: session.finishedExercises,
        totalExercises: session.totalExercises,
        completedSets: session.completedSets,
        totalSets: session.totalSets,
        totalVolumeKg: 1000,
        coachMessage: 'جلسه عالی بود.',
        highlights: const <String>['۵ ست'],
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
