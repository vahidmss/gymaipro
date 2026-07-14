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
      errorMessage = null;

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
      errorMessage = message;

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
  });

  final int recovery;
  final int fatigue;
  final int sleep;
  final int readiness;
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
