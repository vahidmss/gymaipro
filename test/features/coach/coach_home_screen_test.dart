import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/coach/application/coach_facade.dart';
import 'package:gymaipro/features/coach/application/coach_facade_result.dart';
import 'package:gymaipro/features/coach/navigation/coach_home_route.dart';
import 'package:gymaipro/features/coach/presentation/screens/coach_home_screen.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/coach/view_models/coach_home_view_model.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/services/route_service.dart';

void main() {
  testWidgets('CoachHomeScreen renders orbit hub', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: CoachHomeScreen(
            viewModel: CoachHomeViewModel(initialState: _loadedState()),
            autoLoad: false,
            enforceCoachV2Gate: false,
          ),
        ),
      ),
    );

    await tester.pump();
    // Entrance + continuous presence/orbit tickers never fully settle.
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text(ProductCopy.myCoachTitle), findsOneWidget);
    expect(find.text(ProductCopy.programOrbit), findsOneWidget);
    expect(find.text(ProductCopy.todayOrbit), findsOneWidget);
    expect(find.text(ProductCopy.mealPlanOrbit), findsOneWidget);
    expect(find.text(ProductCopy.chatWithCoach), findsWidgets);
    expect(find.text(ProductCopy.goToTodayWorkout), findsOneWidget);
    expect(find.text(ProductCopy.coachMonitorTitle), findsOneWidget);
    expect(find.text(ProductCopy.quickTools), findsOneWidget);
    expect(find.text(ProductCopy.progressAnalysis), findsOneWidget);
    expect(find.text(ProductCopy.logWorkout), findsNothing);
    expect(find.text(ProductCopy.startWorkout), findsNothing);
    expect(find.textContaining('امروز انرژی خوبی داری'), findsOneWidget);
    expect(find.textContaining('آمادگی 76٪'), findsOneWidget);
  });

  testWidgets('CoachHomeScreen keeps UI behind CoachV2 gate', (tester) async {
    CoachV2Config.debugOverride = false;
    addTearDown(() => CoachV2Config.debugOverride = null);

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: CoachHomeScreen(enforceCoachV2Gate: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(ProductCopy.coachDisabledTitle), findsOneWidget);
    expect(find.text(ProductCopy.myCoachTitle), findsNothing);
  });

  testWidgets('CoachHomeRoute is registered in RouteService', (tester) async {
    final route = RouteService.generateRoute(
      const RouteSettings(name: CoachHomeRoute.routeName),
    );

    expect(route.settings.name, CoachHomeRoute.routeName);
  });

  test('CoachHomeViewModel loads through facade', () async {
    final viewModel = CoachHomeViewModel(
      facade: _FakeCoachFacade(CoachFacadeResult(state: _loadedState())),
    );

    await viewModel.load();

    expect(viewModel.state.isLoaded, true);
    expect(viewModel.state.greeting, contains('وحید'));
  });

  test('CoachHomeViewModel exposes error state on facade failure', () async {
    final viewModel = CoachHomeViewModel(
      facade: _FakeCoachFacade.error(),
    );

    await viewModel.load();

    expect(viewModel.state.hasError, true);
  });
}

CoachHomeState _loadedState() {
  return const CoachHomeState(
    greeting: 'سلام وحید 👋\nامروز آماده تمرینی؟',
    todayWorkout: CoachTodayWorkout(
      title: 'تمرین امروز',
      focus: 'سینه + پشت بازو',
      exerciseCount: 7,
      durationMinutes: 65,
    ),
    recovery: CoachRecoverySnapshot(
      recovery: 82,
      fatigue: 30,
      sleep: 80,
      readiness: 76,
    ),
    memories: <String>['یادم هست گفتی زانوی راستت اذیت می‌شود.'],
    insights: <String>['این هفته عضلات پشت کمتر تمرین داده شده‌اند.'],
    quickActions: <CoachQuickAction>[
      CoachQuickAction(
        id: 'build_program',
        label: 'ساخت برنامه',
        routeName: '/workout-program-builder',
      ),
    ],
    recentConversations: <CoachConversationSummaryItem>[],
    explainability: CoachExplainabilityItem(
      question: 'چرا امروز پا پیشنهاد ندادم؟',
      reasons: <String>['Recovery پایین بود.'],
    ),
    coachBrief:
        'امروز انرژی خوبی داری.\n\nپیشنهاد می‌کنم تمرین سینه + پشت بازو را انجام بدهی.',
  );
}

class _FakeCoachFacade extends CoachFacade {
  _FakeCoachFacade(this.result)
    : shouldThrow = false,
      super(
        previewLoader: _unusedPreviewLoader,
        programResolver: CoachProgramResolver(
          programLoader: (_) async => null,
        ),
      );

  _FakeCoachFacade.error()
    : result = null,
      shouldThrow = true,
      super(
        previewLoader: _unusedPreviewLoader,
        programResolver: CoachProgramResolver(
          programLoader: (_) async => null,
        ),
      );

  final CoachFacadeResult? result;
  final bool shouldThrow;

  @override
  Future<CoachFacadeResult> load() async {
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
