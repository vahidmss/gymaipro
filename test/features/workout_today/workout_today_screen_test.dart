import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/application/workout_today_facade.dart';
import 'package:gymaipro/features/workout_today/application/workout_today_facade_result.dart';
import 'package:gymaipro/features/workout_today/domain/workout_today_domain_model.dart';
import 'package:gymaipro/features/workout_today/navigation/workout_today_route.dart';
import 'package:gymaipro/features/workout_today/presentation/screens/workout_today_screen.dart';
import 'package:gymaipro/features/workout_today/state/workout_today_state.dart';
import 'package:gymaipro/features/workout_today/view_models/workout_today_view_model.dart';
import 'package:gymaipro/services/route_service.dart';

void main() {
  test('WorkoutTodayState exposes status helpers', () {
    const loading = WorkoutTodayState.loading();
    const empty = WorkoutTodayState.empty();
    const error = WorkoutTodayState.error('خطا');
    final loaded = _loadedState();

    expect(loading.isLoading, true);
    expect(empty.isEmpty, true);
    expect(error.hasError, true);
    expect(loaded.isLoaded, true);
    expect(loaded.data!.workout.exercises.length, 7);
  });

  testWidgets('WorkoutTodayScreen renders loaded preview workout', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: WorkoutTodayScreen(
            viewModel: WorkoutTodayViewModel(initialState: _loadedState()),
            autoLoad: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('سلام وحید'), findsOneWidget);
    expect(find.text('امروز روز تمرین بالاتنه است.'), findsOneWidget);
    expect(find.text(ProductCopy.startWorkout), findsWidgets);
    expect(find.text(ProductCopy.workoutSummary), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text(ProductCopy.exerciseTimeline), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text(ProductCopy.coachNotes), findsOneWidget);
    expect(find.text(ProductCopy.whyThisSuggestion), findsOneWidget);
    expect(find.text(ProductCopy.quickActions), findsOneWidget);
  });

  testWidgets('WorkoutTodayScreen renders loading skeleton', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: WorkoutTodayScreen(
            viewModel: WorkoutTodayViewModel(
              initialState: const WorkoutTodayState.loading(),
            ),
            autoLoad: false,
          ),
        ),
      ),
    );

    expect(find.byType(GymSkeleton), findsWidgets);
    expect(find.textContaining('سلام وحید'), findsNothing);
  });

  testWidgets('WorkoutTodayScreen renders empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: WorkoutTodayScreen(
            viewModel: WorkoutTodayViewModel(
              initialState: const WorkoutTodayState.empty(),
            ),
            autoLoad: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ProductCopy.emptyWorkoutTitle), findsOneWidget);
    expect(find.text(ProductCopy.buildProgram), findsOneWidget);
  });

  testWidgets('WorkoutTodayScreen renders error state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: WorkoutTodayScreen(
            viewModel: WorkoutTodayViewModel(
              initialState: const WorkoutTodayState.error('خطای تست'),
            ),
            autoLoad: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('خطای تست'), findsOneWidget);
  });

  testWidgets('WorkoutTodayRoute is registered in RouteService', (tester) async {
    final route = RouteService.generateRoute(
      const RouteSettings(name: WorkoutTodayRoute.routeName),
    );

    expect(route.settings.name, WorkoutTodayRoute.routeName);
  });

  test('WorkoutTodayViewModel loads through facade', () async {
    final viewModel = WorkoutTodayViewModel(
      facade: _FakeWorkoutTodayFacade(
        WorkoutTodayFacadeResult(state: _loadedState()),
      ),
    );

    await viewModel.load();

    expect(viewModel.state.isLoaded, true);
    expect(viewModel.state.data!.workout.exercises.length, 7);
  });

  test('WorkoutTodayViewModel exposes error state on facade failure', () async {
    final viewModel = WorkoutTodayViewModel(
      facade: _FakeWorkoutTodayFacade.error(),
    );

    await viewModel.load();

    expect(viewModel.state.hasError, true);
  });
}

WorkoutTodayState _loadedState() {
  return const WorkoutTodayState.loaded(
    WorkoutTodayData(
      workout: WorkoutTodayDomainModel(
        userName: 'وحید',
        headline: 'امروز روز تمرین بالاتنه است.',
        recoveryPercent: 82,
        durationMinutes: 65,
        totalSets: 24,
        muscleGroups: <String>['سینه', 'سرشانه', 'پشت بازو'],
        intensity: 'متوسط رو به بالا',
        exercises: <WorkoutTodayExercise>[
          WorkoutTodayExercise(
            name: 'Bench Press',
            sets: 4,
            reps: 10,
            primaryMuscle: 'سینه',
          ),
          WorkoutTodayExercise(
            name: 'Incline Press',
            sets: 4,
            reps: 10,
            primaryMuscle: 'بالاسینه',
          ),
          WorkoutTodayExercise(
            name: 'Cable Fly',
            sets: 3,
            reps: 12,
            primaryMuscle: 'سینه',
          ),
          WorkoutTodayExercise(
            name: 'Shoulder Press',
            sets: 3,
            reps: 10,
            primaryMuscle: 'سرشانه',
          ),
          WorkoutTodayExercise(
            name: 'Lateral Raise',
            sets: 3,
            reps: 14,
            primaryMuscle: 'سرشانه',
          ),
          WorkoutTodayExercise(
            name: 'Triceps Pushdown',
            sets: 4,
            reps: 12,
            primaryMuscle: 'پشت بازو',
          ),
          WorkoutTodayExercise(
            name: 'Overhead Triceps Extension',
            sets: 3,
            reps: 12,
            primaryMuscle: 'پشت بازو',
          ),
        ],
        coachNotes: <String>['امروز روی اجرای صحیح تمرکز کن.'],
        reasons: <String>['Recovery مناسب است.'],
      ),
      quickActions: <WorkoutTodayQuickAction>[
        WorkoutTodayQuickAction(
          id: 'modify',
          label: 'تغییر برنامه',
          routeName: '/coach',
        ),
      ],
    ),
  );
}

class _FakeWorkoutTodayFacade extends WorkoutTodayFacade {
  _FakeWorkoutTodayFacade(this.result)
    : shouldThrow = false,
      super(previewLoader: _unusedPreviewLoader);

  _FakeWorkoutTodayFacade.error()
    : result = null,
      shouldThrow = true,
      super(previewLoader: _unusedPreviewLoader);

  final WorkoutTodayFacadeResult? result;
  final bool shouldThrow;

  @override
  Future<WorkoutTodayFacadeResult> load() async {
    if (shouldThrow) throw StateError('preview failed');
    return result!;
  }
}

Never _unusedPreviewLoader({
  required String userMessage,
  String userId = 'preview_user',
  dynamic context,
  Map<String, Object?> metadata = const <String, Object?>{},
}) {
  throw UnimplementedError();
}
