import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/coach_conversation_summary.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/prompt_context.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// Unified immutable context package for GymAI Coach v2.
///
/// This is the single data boundary between context collection and prompt
/// assembly. Chat consumes it when `CoachV2Config.coachV2Enabled` is true.
class CoachContext {
  const CoachContext({
    required this.intent,
    required this.metadata,
    this.profile = const <String, Object?>{},
    this.goals = const <String>[],
    this.restrictions = const <String>[],
    this.equipment = const <String>[],
    this.preferences = const <String, Object?>{},
    this.activeProgram,
    this.workoutHistory = const <WorkoutDailyLog>[],
    this.weeklyHeatmap,
    this.memories = const <CoachMemory>[],
    this.apiUsage = const <String, Object?>{},
    this.currentQuestion,
    this.conversationSummary = CoachConversationSummary.empty,
  });

  /// Empty package for dry-run seeds and tests.
  factory CoachContext.empty({
    AIIntent intent = AIIntent.generalChat,
    DateTime? buildTime,
  }) {
    final resolvedBuildTime = buildTime ?? DateTime.now();
    return CoachContext(
      intent: intent,
      metadata: CoachContextMetadata(
        buildTime: resolvedBuildTime,
        sourceCount: 0,
        missingProviders: const <AIContextProviderKey>{},
        confidence: 0,
        contextVersion: contextVersion,
      ),
    );
  }

  /// Current schema version for CoachContext.
  static const String contextVersion = 'v1';

  /// Resolved intent for this package.
  final AIIntent intent;

  /// Raw profile data adapted from existing profile services.
  final Map<String, Object?> profile;

  /// User training goals.
  final List<String> goals;

  /// Injuries, medical limits, and training restrictions.
  final List<String> restrictions;

  /// Available equipment.
  final List<String> equipment;

  /// Coaching and lifestyle preferences.
  final Map<String, Object?> preferences;

  /// Current active program state.
  final Map<String, Object?>? activeProgram;

  /// Recent workout logs.
  final List<WorkoutDailyLog> workoutHistory;

  /// Weekly muscle heatmap snapshot.
  final WeeklyMuscleHeatmapResult? weeklyHeatmap;

  /// Read-only coach memories included in this package.
  final List<CoachMemory> memories;

  /// Read-only API usage snapshot.
  final Map<String, Object?> apiUsage;

  /// Current user question.
  final String? currentQuestion;

  /// Placeholder conversation summary.
  final CoachConversationSummary conversationSummary;

  /// Assembly metadata.
  final CoachContextMetadata metadata;

  /// Converts this package to the legacy prompt context shape.
  ///
  /// Existing dry-run modules may use this bridge until they migrate to
  /// CoachContext directly. No runtime behavior is changed by this helper.
  PromptContext toPromptContext() {
    return PromptContext(
      userProfile: profile.isEmpty ? null : AIUserProfileContext(data: profile),
      goal: goals.isEmpty ? null : AIGoalContext(goals: goals),
      workout: (activeProgram == null && workoutHistory.isEmpty)
          ? null
          : AIWorkoutContext(
              activeProgram: activeProgram,
              history: workoutHistory,
            ),
      heatmap: weeklyHeatmap == null
          ? null
          : AIHeatmapContext(weekly: weeklyHeatmap),
      equipment: equipment.isEmpty
          ? null
          : AIEquipmentContext(items: equipment),
      restrictions: restrictions.isEmpty
          ? null
          : AIRestrictionsContext(items: restrictions),
      preferences: preferences.isEmpty
          ? null
          : AIPreferencesContext(items: preferences),
      memory: memories.isEmpty
          ? null
          : AIMemoryContext(
              items: <String, Object?>{
                for (final memory in memories) memory.key: memory.value,
              },
            ),
      currentQuestion: currentQuestion == null
          ? null
          : AICurrentQuestionContext(text: currentQuestion),
      apiUsage: apiUsage.isEmpty ? null : AIAPIUsageContext(data: apiUsage),
    );
  }
}
