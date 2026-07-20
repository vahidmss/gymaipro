import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';

enum CoachHomeStatus { loading, loaded, error }

/// Immutable view state for the Coach home experience.
class CoachHomeState {
  const CoachHomeState({
    required this.greeting,
    required this.todayWorkout,
    required this.recovery,
    required this.memories,
    required this.insights,
    required this.quickActions,
    required this.recentConversations,
    required this.explainability,
    this.coachBrief = '',
    this.status = CoachHomeStatus.loaded,
    this.errorMessage,
    this.plan = CoachSubscriptionPlan.free,
    this.planLabel = 'رایگان',
  });

  const CoachHomeState.loading()
    : status = CoachHomeStatus.loading,
      greeting = '',
      todayWorkout = null,
      recovery = const CoachRecoverySnapshot(
        recovery: 0,
        fatigue: 0,
        sleep: 0,
        readiness: 0,
      ),
      memories = const <String>[],
      insights = const <String>[],
      quickActions = const <CoachQuickAction>[],
      recentConversations = const <CoachConversationSummaryItem>[],
      explainability = const CoachExplainabilityItem(
        question: '',
        reasons: <String>[],
      ),
      coachBrief = '',
      errorMessage = null,
      plan = CoachSubscriptionPlan.free,
      planLabel = 'رایگان';

  const CoachHomeState.error(String message)
    : status = CoachHomeStatus.error,
      greeting = '',
      todayWorkout = null,
      recovery = const CoachRecoverySnapshot(
        recovery: 0,
        fatigue: 0,
        sleep: 0,
        readiness: 0,
      ),
      memories = const <String>[],
      insights = const <String>[],
      quickActions = const <CoachQuickAction>[],
      recentConversations = const <CoachConversationSummaryItem>[],
      explainability = const CoachExplainabilityItem(
        question: '',
        reasons: <String>[],
      ),
      coachBrief = '',
      errorMessage = message,
      plan = CoachSubscriptionPlan.free,
      planLabel = 'رایگان';

  final CoachHomeStatus status;
  final String greeting;
  final CoachTodayWorkout? todayWorkout;
  final CoachRecoverySnapshot recovery;
  final List<String> memories;
  final List<String> insights;
  final List<CoachQuickAction> quickActions;
  final List<CoachConversationSummaryItem> recentConversations;
  final CoachExplainabilityItem explainability;
  final String coachBrief;
  final String? errorMessage;
  final CoachSubscriptionPlan plan;
  final String planLabel;

  bool get isLoading => status == CoachHomeStatus.loading;
  bool get isLoaded => status == CoachHomeStatus.loaded;
  bool get hasError => status == CoachHomeStatus.error;

  CoachHomeState copyWith({
    CoachHomeStatus? status,
    String? greeting,
    CoachTodayWorkout? todayWorkout,
    CoachRecoverySnapshot? recovery,
    List<String>? memories,
    List<String>? insights,
    List<CoachQuickAction>? quickActions,
    List<CoachConversationSummaryItem>? recentConversations,
    CoachExplainabilityItem? explainability,
    String? coachBrief,
    String? errorMessage,
    CoachSubscriptionPlan? plan,
    String? planLabel,
  }) {
    return CoachHomeState(
      status: status ?? this.status,
      greeting: greeting ?? this.greeting,
      todayWorkout: todayWorkout ?? this.todayWorkout,
      recovery: recovery ?? this.recovery,
      memories: memories ?? this.memories,
      insights: insights ?? this.insights,
      quickActions: quickActions ?? this.quickActions,
      recentConversations: recentConversations ?? this.recentConversations,
      explainability: explainability ?? this.explainability,
      coachBrief: coachBrief ?? this.coachBrief,
      errorMessage: errorMessage ?? this.errorMessage,
      plan: plan ?? this.plan,
      planLabel: planLabel ?? this.planLabel,
    );
  }
}

class CoachTodayWorkout {
  const CoachTodayWorkout({
    required this.title,
    required this.focus,
    required this.exerciseCount,
    required this.durationMinutes,
  });

  final String title;
  final String focus;
  final int exerciseCount;
  final int durationMinutes;
}

class CoachRecoverySnapshot {
  const CoachRecoverySnapshot({
    required this.recovery,
    required this.fatigue,
    required this.sleep,
    required this.readiness,
    this.daysSinceLastWorkout,
  });

  final int recovery;
  final int fatigue;
  final int sleep;
  final int readiness;

  /// Calendar days since last logged workout (`0` = trained today).
  final int? daysSinceLastWorkout;
}

class CoachQuickAction {
  const CoachQuickAction({
    required this.id,
    required this.label,
    required this.routeName,
    this.previewMessage,
  });

  final String id;
  final String label;
  final String routeName;
  final String? previewMessage;
}

class CoachConversationSummaryItem {
  const CoachConversationSummaryItem({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class CoachExplainabilityItem {
  const CoachExplainabilityItem({
    required this.question,
    required this.reasons,
  });

  final String question;
  final List<String> reasons;
}
