import 'package:gymaipro/ai/context/adapters/memory_context_adapter.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/context_builder.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/prompt_context.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// Assembles immutable [CoachContext] packages from provider output.
class CoachContextAssembler {
  CoachContextAssembler({
    AIContextBuilder? contextBuilder,
    MemoryContextAdapter? memoryAdapter,
  }) : _contextBuilder = contextBuilder ?? AIContextBuilder.standard(),
       _memoryAdapter = memoryAdapter ?? MemoryContextAdapter();

  final AIContextBuilder _contextBuilder;
  final MemoryContextAdapter _memoryAdapter;

  /// Builds a unified coach context for [intent] and [selection].
  Future<CoachContext> assemble({
    required AIContextRequest request,
    required AIIntent intent,
    required AIContextProviderSelection selection,
    DateTime? buildTime,
  }) async {
    final resolvedBuildTime = buildTime ?? DateTime.now();
    final promptContext = await _contextBuilder.buildForProviders(
      request,
      selection.providers,
    );
    final memories = await _memoryAdapter.loadActiveMemories(request.userId);

    return _mapToCoachContext(
      intent: intent,
      request: request,
      promptContext: promptContext,
      memories: memories,
      selection: selection,
      buildTime: resolvedBuildTime,
    );
  }

  CoachContext _mapToCoachContext({
    required AIIntent intent,
    required AIContextRequest request,
    required PromptContext promptContext,
    required List<CoachMemory> memories,
    required AIContextProviderSelection selection,
    required DateTime buildTime,
  }) {
    final profile = Map<String, Object?>.from(
      promptContext.userProfile?.data ?? const <String, Object?>{},
    );
    final goals = List<String>.from(
      promptContext.goal?.goals ?? const <String>[],
    );
    final restrictions = List<String>.from(
      promptContext.restrictions?.items ?? const <String>[],
    );
    final equipment = List<String>.from(
      promptContext.equipment?.items ?? const <String>[],
    );
    final preferences = Map<String, Object?>.from(
      promptContext.preferences?.items ?? const <String, Object?>{},
    );
    final activeProgram = promptContext.workout?.activeProgram == null
        ? null
        : Map<String, Object?>.from(promptContext.workout!.activeProgram!);
    final workoutHistory = List<WorkoutDailyLog>.from(
      promptContext.workout?.history ?? const <WorkoutDailyLog>[],
    );
    final apiUsage = Map<String, Object?>.from(
      promptContext.apiUsage?.data ?? const <String, Object?>{},
    );
    final currentQuestion =
        promptContext.currentQuestion?.text ?? request.currentQuestion;

    final sourceCount = _sourceCount(
      profile: profile,
      goals: goals,
      restrictions: restrictions,
      equipment: equipment,
      preferences: preferences,
      activeProgram: activeProgram,
      workoutHistory: workoutHistory,
      weeklyHeatmap: promptContext.heatmap?.weekly,
      memories: memories,
      apiUsage: apiUsage,
      currentQuestion: currentQuestion,
    );

    final missingProviders = <AIContextProviderKey>{
      ...selection.missingRequiredProviders,
      ...selection.missingOptionalProviders,
    };

    return CoachContext(
      intent: intent,
      profile: profile,
      goals: goals,
      restrictions: restrictions,
      equipment: equipment,
      preferences: preferences,
      activeProgram: activeProgram,
      workoutHistory: workoutHistory,
      weeklyHeatmap: promptContext.heatmap?.weekly,
      memories: memories,
      apiUsage: apiUsage,
      currentQuestion: currentQuestion,
      metadata: CoachContextMetadata(
        buildTime: buildTime,
        sourceCount: sourceCount,
        missingProviders: Set<AIContextProviderKey>.unmodifiable(
          missingProviders,
        ),
        confidence: _confidence(
          sourceCount: sourceCount,
          missingRequired: selection.missingRequiredProviders.length,
        ),
        contextVersion: CoachContext.contextVersion,
      ),
    );
  }

  int _sourceCount({
    required Map<String, Object?> profile,
    required List<String> goals,
    required List<String> restrictions,
    required List<String> equipment,
    required Map<String, Object?> preferences,
    required Map<String, Object?>? activeProgram,
    required List<WorkoutDailyLog> workoutHistory,
    required WeeklyMuscleHeatmapResult? weeklyHeatmap,
    required List<CoachMemory> memories,
    required Map<String, Object?> apiUsage,
    required String? currentQuestion,
  }) {
    var count = 0;
    if (profile.isNotEmpty) count++;
    if (goals.isNotEmpty) count++;
    if (restrictions.isNotEmpty) count++;
    if (equipment.isNotEmpty) count++;
    if (preferences.isNotEmpty) count++;
    if (activeProgram != null && activeProgram.isNotEmpty) count++;
    if (workoutHistory.isNotEmpty) count++;
    if (weeklyHeatmap != null && weeklyHeatmap.hasHeatmapData) count++;
    if (memories.isNotEmpty) count++;
    if (apiUsage.isNotEmpty) count++;
    if (currentQuestion != null && currentQuestion.trim().isNotEmpty) count++;
    return count;
  }

  double _confidence({required int sourceCount, required int missingRequired}) {
    if (sourceCount == 0) return 0;
    final base = 0.45 + (sourceCount * 0.05);
    final penalty = missingRequired * 0.08;
    return (base - penalty).clamp(0, 1);
  }
}
