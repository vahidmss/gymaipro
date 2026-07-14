import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_facade_result.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_factory.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';
import 'package:gymaipro/features/product_experience/coach_experience_runtime_bridge.dart';
import 'package:gymaipro/features/product_experience/coach_feature_integration.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

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
  }) : _coachLoader =
           coachLoader ??
           previewLoader ??
           CoachFeatureIntegration.defaultLoader(),
       _seedLoader = seedLoader,
       _programResolver = programResolver ?? CoachProgramResolver(),
       _runtimeBridge = runtimeBridge ?? const CoachExperienceRuntimeBridge(),
       _sessionFactory = sessionFactory ?? const LiveWorkoutSessionFactory();

  final CoachFeatureLoader _coachLoader;
  final CoachPreviewSeedProvider? _seedLoader;
  final CoachProgramResolver _programResolver;
  final CoachExperienceRuntimeBridge _runtimeBridge;
  final LiveWorkoutSessionFactory _sessionFactory;

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

  Future<LiveWorkoutFacadeResult> load() async {
    const message = 'تمرین امروزم رو شروع کن';
    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: AIIntent.workoutToday,
      message: message,
    );
    _lastUserId = seed.userId;
    final result = await _coachLoader(
      userMessage: message,
      userId: seed.userId,
      context: seed.context,
      metadata: const <String, Object?>{'feature': 'live_workout'},
    );
    return map(result, userId: seed.userId);
  }

  Future<LiveWorkoutFacadeResult> map(
    CoachIntegrationResult result, {
    String userId = 'preview_user',
  }) async {
    final gaps = <String>[];

    final resolved = await _programResolver.resolve(result: result);
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
    if (reasons.isEmpty) {
      gaps.add('توضیح‌پذیری در دسترس نبود.');
    }

    final coachTips = ProductExperienceFormatter.coachNotes(result);
    final session = _sessionFactory.fromResolved(
      resolved: resolved,
      userId: userId,
      programId: resolved.aiProgram?.id,
    );

    return LiveWorkoutFacadeResult(
      state: LiveWorkoutState.loaded(
        session: session,
        userId: userId,
        coachTips: coachTips,
        explainability: reasons,
      ),
      gaps: List<String>.unmodifiable(gaps),
      previewDuration: result.processingTime,
    );
  }
}
