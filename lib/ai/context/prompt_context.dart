import 'package:gymaipro/ai/context/context_models.dart';

/// Unified prompt context for GymAI Coach v2.
///
/// This object is the stable boundary between context collection and future
/// prompt assembly. Phase 1 only models the data and does not change existing
/// OpenAI prompts or services.
class PromptContext {
  const PromptContext({
    this.userProfile,
    this.goal,
    this.workout,
    this.history,
    this.heatmap,
    this.equipment,
    this.restrictions,
    this.preferences,
    this.memory,
    this.currentQuestion,
    this.apiUsage,
    this.recovery,
    this.chat,
  });

  /// Empty context used as a merge seed.
  const PromptContext.empty()
    : userProfile = null,
      goal = null,
      workout = null,
      history = null,
      heatmap = null,
      equipment = null,
      restrictions = null,
      preferences = null,
      memory = null,
      currentQuestion = null,
      apiUsage = null,
      recovery = null,
      chat = null;

  final AIUserProfileContext? userProfile;
  final AIGoalContext? goal;
  final AIWorkoutContext? workout;
  final AIHistoryContext? history;
  final AIHeatmapContext? heatmap;
  final AIEquipmentContext? equipment;
  final AIRestrictionsContext? restrictions;
  final AIPreferencesContext? preferences;
  final AIMemoryContext? memory;
  final AICurrentQuestionContext? currentQuestion;
  final AIAPIUsageContext? apiUsage;
  final AIRecoveryContext? recovery;
  final AIChatContext? chat;

  /// Merges a provider patch into this context.
  PromptContext merge(PromptContextPatch patch) {
    return PromptContext(
      userProfile: patch.userProfile ?? userProfile,
      goal: patch.goal ?? goal,
      workout: _mergeWorkout(workout, patch.workout),
      history: patch.history ?? history,
      heatmap: patch.heatmap ?? heatmap,
      equipment: patch.equipment ?? equipment,
      restrictions: patch.restrictions ?? restrictions,
      preferences: patch.preferences ?? preferences,
      memory: patch.memory ?? memory,
      currentQuestion: patch.currentQuestion ?? currentQuestion,
      apiUsage: patch.apiUsage ?? apiUsage,
      recovery: patch.recovery ?? recovery,
      chat: patch.chat ?? chat,
    );
  }

  AIWorkoutContext? _mergeWorkout(
    AIWorkoutContext? current,
    AIWorkoutContext? incoming,
  ) {
    if (current == null) return incoming;
    if (incoming == null) return current;

    return AIWorkoutContext(
      activeProgram: incoming.activeProgram ?? current.activeProgram,
      history: incoming.history.isNotEmpty ? incoming.history : current.history,
    );
  }
}
