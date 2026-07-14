import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/product_experience/coach_experience_runtime_bridge.dart';
import 'package:gymaipro/features/product_experience/coach_feature_integration.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/features/product_experience/coach_resolved_program.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
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
  }) : _coachLoader =
           coachLoader ??
           previewLoader ??
           CoachFeatureIntegration.defaultLoader(),
       _seedLoader = seedLoader,
       _programResolver = programResolver ?? CoachProgramResolver(),
       _runtimeBridge = runtimeBridge ?? const CoachExperienceRuntimeBridge();

  final CoachFeatureLoader _coachLoader;
  final CoachPreviewSeedProvider? _seedLoader;
  final CoachProgramResolver _programResolver;
  final CoachExperienceRuntimeBridge _runtimeBridge;

  CoachIntegrationResult? _lastResult;
  CoachResolvedTodayWorkout? _lastResolved;

  Future<WorkoutTodayFacadeResult> load() async {
    const message = 'تمرین امروز چیه؟';
    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: AIIntent.workoutToday,
      message: message,
    );
    final result = await _coachLoader(
      userMessage: message,
      userId: seed.userId,
      context: seed.context,
      metadata: const <String, Object?>{'feature': 'workout_today'},
    );
    return map(result);
  }

  Future<WorkoutTodayQuickActionResult> runQuickAction(String actionId) async {
    final result = _lastResult;
    if (result == null) {
      return const WorkoutTodayQuickActionResult(
        message: 'ابتدا تمرین امروز را بارگذاری کن.',
      );
    }

    final normalized =
        CoachExperienceRuntimeBridge.normalizeQuickActionId(actionId);
    final lines = _runtimeBridge.runQuickActionMessages(
      actionId: normalized,
      program: _lastResolved?.aiProgram,
      context: result.coachContext,
    );

    if (lines.isEmpty) {
      return WorkoutTodayQuickActionResult(
        message: ProductExperienceFormatter.promptForQuickAction(actionId),
        routeName: _routeForQuickAction(normalized),
        previewMessage: ProductExperienceFormatter.promptForQuickAction(actionId),
      );
    }

    return WorkoutTodayQuickActionResult(
      message: lines.join('\n'),
      routeName: _routeForQuickAction(normalized),
      previewMessage: ProductExperienceFormatter.promptForQuickAction(actionId),
    );
  }

  Future<WorkoutTodayFacadeResult> map(CoachIntegrationResult result) async {
    _lastResult = result;
    final gaps = <String>[];

    final resolved = await _programResolver.resolve(result: result);
    _lastResolved = resolved;
    if (resolved == null || resolved.exercises.isEmpty) {
      gaps.add('برنامه فعال برای امروز پیدا نشد.');
      return WorkoutTodayFacadeResult(
        state: const WorkoutTodayState.empty(),
        gaps: List<String>.unmodifiable(gaps),
        previewDuration: result.processingTime,
      );
    }

    final context = result.coachContext;
    final recovery = ProductExperienceFormatter.recoverySnapshot(
      context: context,
      result: result,
    );
    if (recovery.recovery == 0) {
      gaps.add('درصد ریکاوری در دسترس نبود.');
    }

    final review = _runtimeBridge.reviewProgram(
      program: resolved.aiProgram,
      context: context,
    );
    final reasons = ProductExperienceFormatter.explainabilityReasons(
      result: result,
      context: context,
      reviewResult: review,
      generatorReasons: resolved.aiProgram?.programReasons ?? const [],
    );
    if (reasons.isEmpty) {
      gaps.add('توضیح تمرین در دسترس نبود.');
    }

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
              result: result,
              muscleGroups: resolved.muscleGroups,
            ),
            recoveryPercent: recovery.readiness,
            durationMinutes: resolved.durationMinutes,
            exercises: exercises,
            totalSets: resolved.totalSets,
            muscleGroups: resolved.muscleGroups,
            intensity: resolved.intensity,
            coachNotes: ProductExperienceFormatter.coachNotes(result),
            reasons: reasons,
          ),
          quickActions: _quickActions,
        ),
      ),
      gaps: List<String>.unmodifiable(gaps),
      previewDuration: result.processingTime,
    );
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
          label: 'تغییر برنامه',
          routeName: '/coach-chat',
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
          id: 'replace',
          label: 'جایگزینی حرکت',
          routeName: '/coach-chat',
        ),
        WorkoutTodayQuickAction(
          id: 'ask',
          label: 'پرسش از مربی',
          routeName: '/coach-chat',
        ),
      ];
}

String _routeForQuickAction(String id) {
  return switch (id) {
    'build_program' => '/workout-program-builder',
    'today_program' => '/workout-today',
    'ask_coach' || 'ask' => '/coach-chat',
    _ => '/coach-chat',
  };
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
