import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/payment/services/ai_program_access.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_completion_service.dart';
import 'package:gymaipro/features/product_experience/coach_experience_runtime_bridge.dart';
import 'package:gymaipro/features/product_experience/coach_feature_integration.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/features/product_experience/coach_resolved_program.dart';
import 'package:gymaipro/features/product_experience/domain/coach_observation.dart';
import 'package:gymaipro/features/product_experience/domain/coach_user_card.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/features/product_experience/recovery/last_night_sleep.dart';
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_provider.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/features/coach/application/coach_facade_result.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';

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
    SubscriptionService? subscriptionService,
    @Deprecated('Hub access uses AiProgramAccess')
    CoachEntitlementProvider? entitlementProvider,
    WorkoutDailyLogService? workoutLogService,
    LiveWorkoutCompletionService? completionService,
    LastNightSleepStore? sleepStore,
  }) : _coachLoader =
           coachLoader ??
           previewLoader ??
           CoachFeatureIntegration.defaultLoader(),
       _seedLoader = seedLoader,
       _programResolver = programResolver ?? CoachProgramResolver(),
       _runtimeBridge = runtimeBridge ?? const CoachExperienceRuntimeBridge(),
       _subscriptionService = subscriptionService ?? SubscriptionService(),
       _workoutLogService = workoutLogService ?? WorkoutDailyLogService(),
       _completionService = completionService ?? LiveWorkoutCompletionService(),
       _sleepStore = sleepStore ?? LastNightSleepStore();

  final CoachFeatureLoader _coachLoader;
  final CoachPreviewSeedProvider? _seedLoader;
  final CoachProgramResolver _programResolver;
  final CoachExperienceRuntimeBridge _runtimeBridge;
  final SubscriptionService _subscriptionService;
  final WorkoutDailyLogService _workoutLogService;
  final LiveWorkoutCompletionService _completionService;
  final LastNightSleepStore _sleepStore;

  CoachIntegrationResult? _lastResult;
  CoachResolvedTodayWorkout? _lastResolved;

  Future<CoachFacadeResult> load({bool enrichWithCoach = false}) async {
    final stopwatch = Stopwatch()..start();
    const message = 'سلام، وضعیت تمرین امروز چطوره؟';
    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: AIIntent.workoutToday,
      message: message,
    );
    final sleep = await _sleepStore.readToday(seed.userId);
    final context = LastNightSleep.applyToContext(seed.context, sleep);
    // Free teaser + paid spring: hub never runs the Coach pipeline on open.
    final CoachIntegrationResult result;
    if (enrichWithCoach) {
      result = await _coachLoader(
        userMessage: message,
        userId: seed.userId,
        context: context,
        metadata: const <String, Object?>{'feature': 'coach_home'},
      );
    } else {
      result = CoachIntegrationResult.hubSeed(
        coachContext: context,
        processingTime: stopwatch.elapsed,
      );
    }
    return map(result, userId: seed.userId);
  }

  Future<CoachQuickActionResult> runQuickAction(String actionId) async {
    final result = _lastResult;
    if (result == null) {
      return const CoachQuickActionResult(
        message: 'ابتدا صفحه مربی را بارگذاری کن.',
      );
    }

    final normalized = CoachExperienceRuntimeBridge.normalizeQuickActionId(
      actionId,
    );
    final lines = _runtimeBridge.runQuickActionMessages(
      actionId: normalized,
      program: _lastResolved?.aiProgram,
      context: result.coachContext,
    );

    if (lines.isEmpty) {
      return CoachQuickActionResult(
        message: ProductExperienceFormatter.promptForQuickAction(actionId),
        routeName: _routeForQuickAction(normalized),
        previewMessage: ProductExperienceFormatter.promptForQuickAction(
          actionId,
        ),
      );
    }

    return CoachQuickActionResult(
      message: lines.join('\n'),
      routeName: _routeForQuickAction(normalized),
      previewMessage: ProductExperienceFormatter.promptForQuickAction(actionId),
    );
  }

  Future<CoachFacadeResult> map(
    CoachIntegrationResult result, {
    String? userId,
  }) async {
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

    final card = CoachUserCard.fromContext(context, recovery: recovery);
    final memories = card.userFacingLines.take(4).toList(growable: false);
    if (memories.isEmpty) {
      gaps.add('حافظه مربی در دسترس نبود.');
    }

    final insights = ProductExperienceFormatter.insights(context, result);
    if (insights.isEmpty) {
      gaps.add('بینش مربی در دسترس نبود.');
    }

    final observations = await _loadObservations(userId: userId);

    final review = _runtimeBridge.reviewProgram(
      program: resolved?.aiProgram,
      context: context,
    );
    final reasons = ProductExperienceFormatter.explainabilityReasons(
      result: result,
      context: context,
      reviewResult: review,
      generatorReasons: resolved?.aiProgram?.programReasons ?? const [],
      recovery: recovery,
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

    final planInfo = await _resolvePlan(userId: userId ?? '', context: context);

    final guidance = RecoveryGuidance.fromSnapshot(recovery);
    final name = _profileName(context);
    final greeting = switch (guidance.scenario) {
      RecoveryScenario.postSessionToday =>
        'سلام $name\nجلسه امروزت ثبت شد — آفرین. الان روی ریکاوری تمرکز کن.',
      RecoveryScenario.returningAfterBreak =>
        'سلام $name\nخوش برگشتی؛ امروز با شدت متوسط شروع کنیم.',
      RecoveryScenario.needsRestOrLighter =>
        'سلام $name\nبدن امروز به فشار کمتر نیاز دارد.',
      _ => 'سلام $name\nامروز آماده تمرینی؟',
    };

    return CoachFacadeResult(
      state: CoachHomeState(
        greeting: greeting,
        todayWorkout: _todayWorkout(resolved, gaps),
        recovery: recovery,
        memories: memories,
        insights: insights,
        observations: observations,
        coachBrief: coachBrief,
        quickActions: _quickActions,
        recentConversations: _recentConversations(result),
        explainability: CoachExplainabilityItem(
          question: 'چرا امروز این پیشنهاد را می‌بینم؟',
          reasons: reasons,
        ),
        plan: planInfo.plan,
        planLabel: planInfo.label,
      ),
      gaps: List<String>.unmodifiable(gaps),
      previewDuration: result.processingTime,
    );
  }

  Future<List<CoachObservation>> _loadObservations({String? userId}) async {
    final id = userId?.trim() ?? '';
    if (id.isEmpty) return const <CoachObservation>[];
    try {
      final stored = await _completionService.loadStoredObservations(id);
      final logs = await _workoutLogService.getRecentLogsBeforeDate(
        id,
        DateTime.now().add(const Duration(days: 1)),
        limit: 14,
      );
      final fromHistory = CoachObservationDetector.fromRecentLogs(logs);
      return CoachObservationDetector.merge(
        fromSession: stored,
        fromHistory: fromHistory,
      );
    } on Object {
      return const <CoachObservation>[];
    }
  }

  Future<({CoachSubscriptionPlan plan, String label})> _resolvePlan({
    required String userId,
    required CoachContext context,
  }) async {
    final effectiveUserId = userId.trim().isEmpty ? null : userId;
    try {
      final access = await AiProgramAccess().load(userId: effectiveUserId);
      if (access.hasPass) {
        return (
          plan: access.plan,
          label: CoachPlanCatalog.hubBadgeLabel(
            plan: access.plan,
            daysRemaining: access.daysRemaining,
          ),
        );
      }
      if (access.hasPaidAccess) {
        return (plan: access.plan, label: 'حساب‌شده — در انتظار ساخت');
      }
      return (
        plan: CoachSubscriptionPlan.free,
        label: CoachPlanCatalog.hubBadgeLabel(plan: CoachSubscriptionPlan.free),
      );
    } on Object {
      final active = await _subscriptionService.peekActiveSubscription(
        userId: effectiveUserId,
      );
      if (active == null) {
        return (
          plan: CoachSubscriptionPlan.free,
          label: CoachPlanCatalog.hubBadgeLabel(
            plan: CoachSubscriptionPlan.free,
          ),
        );
      }
      final plan = CoachPlanCatalog.planFromSubscriptionType(active.type);
      final now = DateTime.now();
      var days = 0;
      if (active.expiryDate.isAfter(now)) {
        days = active.expiryDate.difference(now).inDays;
        if (days == 0) days = 1;
      }
      return (
        plan: plan,
        label: CoachPlanCatalog.hubBadgeLabel(plan: plan, daysRemaining: days),
      );
    }
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
      'build_program' => '/workout-program-request',
      'modify_program' ||
      'modify' ||
      'modify_workout' ||
      'replace' ||
      'replace_exercise' => '/program-modify',
      'review_program' || 'ask_coach' => '/coach-chat',
      'today_program' => '/workout-today',
      _ => '/coach-chat',
    };
  }

  static const List<CoachQuickAction> _quickActions = <CoachQuickAction>[
    CoachQuickAction(
      id: 'build_program',
      label: 'ساخت برنامه',
      routeName: '/workout-program-request',
      previewMessage: 'می‌خواهم برنامه تمرینی جدید بسازم',
    ),
    CoachQuickAction(
      id: 'modify_program',
      label: 'اصلاح برنامه',
      routeName: '/program-modify',
      previewMessage:
          'برنامه‌ام را اصلاح کن: اگر لازم است حرکت عوض شود، ست کم/زیاد شود، یا جلسه سبک‌تر/سنگین‌تر شود.',
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
