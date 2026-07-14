import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/coach_conversation_summary.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
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

  static const Set<String> _profileKeys = <String>{
    'age',
    'height',
    'weight',
    'first_name',
    'last_name',
    'gender',
    'experience_level',
  };

  static const Set<String> _goalKeys = <String>{
    'goal',
    'goals',
    'fitness_goals',
    'primary_goals',
  };

  static const Set<String> _restrictionKeys = <String>{
    'restrictions',
    'injuries',
    'medical_conditions',
    'injury',
  };

  static const Set<String> _equipmentKeys = <String>{'equipment', 'equipments'};

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

  /// Applies conversation-state collected fields on top of this context.
  CoachContext withCollectedFields(Map<String, Object?> collectedFields) {
    if (collectedFields.isEmpty) return this;

    final profile = Map<String, Object?>.from(this.profile);
    final goals = List<String>.from(this.goals);
    final restrictions = List<String>.from(this.restrictions);
    final equipment = List<String>.from(this.equipment);
    final preferences = Map<String, Object?>.from(this.preferences);

    for (final entry in collectedFields.entries) {
      final key = entry.key.trim();
      final value = entry.value;
      if (key.isEmpty || value == null) continue;

      if (_profileKeys.contains(key)) {
        profile[key] = value;
        continue;
      }

      if (_goalKeys.contains(key)) {
        goals.addAll(_asStringList(value));
        continue;
      }

      if (_restrictionKeys.contains(key)) {
        restrictions.addAll(_asStringList(value));
        continue;
      }

      if (_equipmentKeys.contains(key)) {
        equipment.addAll(_asStringList(value));
        continue;
      }

      preferences['conversation_state_$key'] = value;
    }

    return CoachContext(
      intent: intent,
      metadata: metadata,
      profile: Map<String, Object?>.unmodifiable(profile),
      goals: List<String>.unmodifiable(_uniqueStrings(goals)),
      restrictions: List<String>.unmodifiable(_uniqueStrings(restrictions)),
      equipment: List<String>.unmodifiable(_uniqueStrings(equipment)),
      preferences: Map<String, Object?>.unmodifiable(preferences),
      activeProgram: activeProgram,
      workoutHistory: workoutHistory,
      weeklyHeatmap: weeklyHeatmap,
      memories: memories,
      apiUsage: apiUsage,
      currentQuestion: currentQuestion,
      conversationSummary: conversationSummary,
    );
  }

  static List<String> _asStringList(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? const <String>[] : <String>[trimmed];
    }
    if (value is Iterable<Object?>) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    final text = value.toString().trim();
    return text.isEmpty ? const <String>[] : <String>[text];
  }

  static List<String> _uniqueStrings(List<String> values) {
    final seen = <String>{};
    final unique = <String>[];
    for (final value in values) {
      if (seen.add(value)) unique.add(value);
    }
    return unique;
  }
}
