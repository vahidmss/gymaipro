import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/features/coach/application/coach_facade_result.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/coach_experience_runtime_bridge.dart';
import 'package:gymaipro/features/product_experience/coach_feature_integration.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/features/product_experience/coach_resolved_program.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

@Deprecated('Use CoachFeatureLoader')
typedef CoachPreviewLoader = CoachFeatureLoader;

/// Facade between Coach Home UI and the Coach pipeline.
class CoachFacade {
  CoachFacade({
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

  Future<CoachFacadeResult> load() async {
    const message = 'سلام، وضعیت تمرین امروز چطوره؟';
    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: AIIntent.workoutToday,
      message: message,
    );
    final result = await _coachLoader(
      userMessage: message,
      userId: seed.userId,
      context: seed.context,
      metadata: const <String, Object?>{'feature': 'coach_home'},
    );
    return map(result);
  }

  Future<CoachQuickActionResult> runQuickAction(String actionId) async {
    final result = _lastResult;
    if (result == null) {
      return const CoachQuickActionResult(
        message: 'ابتدا صفحه مربی را بارگذاری کن.',
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
      return CoachQuickActionResult(
        message: ProductExperienceFormatter.promptForQuickAction(actionId),
        routeName: _routeForQuickAction(normalized),
        previewMessage: ProductExperienceFormatter.promptForQuickAction(actionId),
      );
    }

    return CoachQuickActionResult(
      message: lines.join('\n'),
      routeName: _routeForQuickAction(normalized),
      previewMessage: ProductExperienceFormatter.promptForQuickAction(actionId),
    );
  }

  Future<CoachFacadeResult> map(CoachIntegrationResult result) async {
    _lastResult = result;
    final gaps = <String>[];

    final context = result.coachContext;
    final resolved = await _programResolver.resolve(result: result);
    _lastResolved = resolved;

    final recovery = ProductExperienceFormatter.recoverySnapshot(
      context: context,
      result: result,
    );
    if (recovery.readiness == 0) {
      gaps.add('داده ریکاوری در دسترس نبود.');
    }

    final memories = context.memories
        .map((memory) => memory.value)
        .where((memory) => memory.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (memories.isEmpty) {
      gaps.add('حافظه مربی در دسترس نبود.');
    }

    final insights = ProductExperienceFormatter.insights(context, result);
    if (insights.isEmpty) {
      gaps.add('بینش مربی در دسترس نبود.');
    }

    final review = _runtimeBridge.reviewProgram(
      program: resolved?.aiProgram,
      context: context,
    );
    final reasons = ProductExperienceFormatter.explainabilityReasons(
      result: result,
      context: context,
      reviewResult: review,
      generatorReasons: resolved?.aiProgram?.programReasons ?? const [],
    );
    if (reasons.isEmpty) {
      gaps.add('توضیح‌پذیری در دسترس نبود.');
    }

    final coachBrief = ProductExperienceFormatter.coachBrief(
      context: context,
      result: result,
      recovery: recovery,
      workout: resolved,
      memories: memories,
      insights: insights,
    );

    return CoachFacadeResult(
      state: CoachHomeState(
        greeting: 'سلام ${_profileName(context)} 👋\nامروز آماده تمرینی؟',
        todayWorkout: _todayWorkout(resolved, gaps),
        recovery: recovery,
        memories: memories,
        insights: insights,
        coachBrief: coachBrief,
        quickActions: _quickActions,
        recentConversations: _recentConversations(result),
        explainability: CoachExplainabilityItem(
          question: 'چرا امروز این پیشنهاد را می‌بینم؟',
          reasons: reasons,
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

  CoachTodayWorkout? _todayWorkout(
    CoachResolvedTodayWorkout? resolved,
    List<String> gaps,
  ) {
    if (resolved == null) {
      gaps.add('تمرین امروز در دسترس نبود.');
      return null;
    }
    return CoachTodayWorkout(
      title: resolved.title,
      focus: resolved.focus,
      exerciseCount: resolved.exerciseCount,
      durationMinutes: resolved.durationMinutes,
    );
  }

  List<CoachConversationSummaryItem> _recentConversations(
    CoachIntegrationResult result,
  ) {
    final state = result.conversationState;
    if (state == null) return const <CoachConversationSummaryItem>[];
    return <CoachConversationSummaryItem>[
      CoachConversationSummaryItem(
        title: ProductExperienceFormatter.localizeFlowType(state.flowType),
        subtitle: ProductExperienceFormatter.localizePhase(state.currentPhase),
      ),
    ];
  }

  String _routeForQuickAction(String id) {
    return switch (id) {
      'build_program' ||
      'modify_program' ||
      'review_program' ||
      'ask_coach' => '/coach-chat',
      'today_program' => '/workout-today',
      _ => '/coach-chat',
    };
  }

  static const List<CoachQuickAction> _quickActions = <CoachQuickAction>[
    CoachQuickAction(
      id: 'build_program',
      label: 'ساخت برنامه',
      routeName: '/coach-chat',
      previewMessage: 'برای من یک برنامه تمرینی بساز',
    ),
    CoachQuickAction(
      id: 'modify_program',
      label: 'اصلاح برنامه',
      routeName: '/coach-chat',
      previewMessage: 'تمرین امروز من را اصلاح کن',
    ),
    CoachQuickAction(
      id: 'review_program',
      label: 'تحلیل برنامه',
      routeName: '/coach-chat',
      previewMessage: 'برنامه تمرینی من را تحلیل کن',
    ),
    CoachQuickAction(
      id: 'today_program',
      label: 'برنامه امروز',
      routeName: '/workout-today',
      previewMessage: 'تمرین امروز من چیه؟',
    ),
    CoachQuickAction(
      id: 'ask_coach',
      label: 'سؤال از مربی',
      routeName: '/coach-chat',
      previewMessage: 'یک سوال از مربی دارم',
    ),
  ];
}

class CoachQuickActionResult {
  const CoachQuickActionResult({
    required this.message,
    this.routeName,
    this.previewMessage,
  });

  final String message;
  final String? routeName;
  final String? previewMessage;
}
