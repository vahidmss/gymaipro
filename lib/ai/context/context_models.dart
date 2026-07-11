import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// Context sections that can be produced independently by providers.
enum AIContextSection {
  userProfile,
  goal,
  workout,
  history,
  heatmap,
  equipment,
  restrictions,
  preferences,
  memory,
  currentQuestion,
  apiUsage,
  recovery,
  chat,
}

/// Granular provider capabilities used for intent-based selection.
enum AIContextProviderKey {
  profile,
  goals,
  restrictions,
  activeProgram,
  workoutHistory,
  heatmap,
  equipment,
  memory,
  currentQuestion,
  apiUsage,
  recovery,
  preferences,
  chatHistory,
  nutrition,
  supplements,
  appHelp,
  diagnostics,
}

/// Priority used when deciding which context providers should be selected.
enum ContextPriority { required, high, medium, low, never }

/// Metadata describing a provider before it is executed.
class AIContextProviderMetadata {
  const AIContextProviderMetadata({
    required this.name,
    required this.priority,
    required this.estimatedCost,
    required this.estimatedLatency,
    required this.cacheable,
    required this.ttl,
  });

  /// Human-readable provider name for diagnostics.
  final String name;

  /// Default selection priority.
  final ContextPriority priority;

  /// Relative cost unit. Zero means no paid AI/API cost is expected.
  final double estimatedCost;

  /// Expected provider latency.
  final Duration estimatedLatency;

  /// Whether the provider output can be cached safely.
  final bool cacheable;

  /// Suggested cache TTL.
  final Duration ttl;
}

/// Input passed to context providers.
class AIContextRequest {
  const AIContextRequest({
    required this.userId,
    this.intent = AIIntent.generalChat,
    this.currentQuestion,
    this.source,
    this.metadata = const <String, Object?>{},
  });

  /// Current authenticated user id.
  final String userId;

  /// Detected or caller-provided intent.
  final AIIntent intent;

  /// Current user question, if the context is being built for a prompt.
  final String? currentQuestion;

  /// Source surface such as coach home, chat, progress analysis, or workout log.
  final String? source;

  /// Additional future-safe metadata for providers.
  final Map<String, Object?> metadata;
}

/// Minimal profile slice for prompt context.
class AIUserProfileContext {
  const AIUserProfileContext({this.data = const <String, Object?>{}});

  /// Raw profile data adapted from existing profile services.
  final Map<String, Object?> data;
}

/// User goals collected from profile, onboarding, or future memory.
class AIGoalContext {
  const AIGoalContext({this.goals = const <String>[]});

  /// Fitness or nutrition goals expressed as normalized strings.
  final List<String> goals;
}

/// Workout-related state for the current user.
class AIWorkoutContext {
  const AIWorkoutContext({
    this.activeProgram,
    this.history = const <WorkoutDailyLog>[],
  });

  /// Current active program state from the existing active-program service.
  final Map<String, Object?>? activeProgram;

  /// Recent workout logs. Phase 1 does not summarize or transform them.
  final List<WorkoutDailyLog> history;
}

/// Historical signals that are not tied to a single workout.
class AIHistoryContext {
  const AIHistoryContext({this.entries = const <Object>[]});

  /// Future-safe history entries such as summaries, check-ins, or reports.
  final List<Object> entries;
}

/// Muscle heatmap context from the existing weekly heatmap service.
class AIHeatmapContext {
  const AIHeatmapContext({this.weekly});

  /// Existing weekly heatmap result.
  final WeeklyMuscleHeatmapResult? weekly;
}

/// Restrictions such as injuries, equipment limits, or medical notes.
class AIRestrictionsContext {
  const AIRestrictionsContext({this.items = const <String>[]});

  /// Normalized user restrictions.
  final List<String> items;
}

/// Equipment available to the user.
class AIEquipmentContext {
  const AIEquipmentContext({this.items = const <String>[]});

  /// Normalized available equipment names.
  final List<String> items;
}

/// User preferences that should influence future coaching.
class AIPreferencesContext {
  const AIPreferencesContext({this.items = const <String, Object?>{}});

  /// Flexible preference map for future onboarding and memory integration.
  final Map<String, Object?> items;
}

/// Long-lived AI memory placeholder.
class AIMemoryContext {
  const AIMemoryContext({this.items = const <String, Object?>{}});

  /// Future memory facts. Phase 1 does not persist or read memory.
  final Map<String, Object?> items;
}

/// Current question context for prompt assembly.
class AICurrentQuestionContext {
  const AICurrentQuestionContext({this.text});

  /// User's current question.
  final String? text;
}

/// API usage and entitlement context for future routing decisions.
class AIAPIUsageContext {
  const AIAPIUsageContext({this.data = const <String, Object?>{}});

  /// Usage stats adapted from current rate-limit or subscription services.
  final Map<String, Object?> data;
}

/// Recovery context reserved for readiness and rest recommendations.
class AIRecoveryContext {
  const AIRecoveryContext({this.data = const <String, Object?>{}});

  /// Future recovery signals such as soreness, rest days, and training density.
  final Map<String, Object?> data;
}

/// Chat context reserved for previous conversation summaries.
class AIChatContext {
  const AIChatContext({this.data = const <String, Object?>{}});

  /// Future chat session data or summaries.
  final Map<String, Object?> data;
}

/// Partial context returned by providers and merged by the builder.
class PromptContextPatch {
  const PromptContextPatch({
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
}
