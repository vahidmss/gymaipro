import 'package:gymaipro/ai/context/coach_context_patch.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides workout log history for Coach v2.
class WorkoutHistoryContextProvider implements AIContextProvider {
  WorkoutHistoryContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  final AIContextRepository _repository;

  /// Architecture documentation for this provider.
  AIContextProviderDescriptor get descriptor =>
      const AIContextProviderDescriptor(
        dataSource: 'WorkoutDailyLogService.getUserDailyLogs(userId)',
        readStrategy:
            'Read-only workout log fetch through AIContextRepository.',
        cacheStrategy:
            'Cacheable for 5 minutes; logs update after workout actions.',
        missingBehaviour: 'Return an empty workout history list.',
        futureMigrationNotes: 'Add time-window filtering and typed summaries.',
      );

  @override
  String get id => 'workout_history_context_provider';

  @override
  String get name => 'Workout History Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.workoutHistory,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.history,
  };

  @override
  AIContextProviderMetadata get metadata => AIContextProviderMetadata(
    name: name,
    priority: priority,
    estimatedCost: estimatedCost,
    estimatedLatency: estimatedLatency,
    cacheable: cacheable,
    ttl: ttl,
  );

  @override
  ContextPriority get priority => ContextPriority.high;

  @override
  double get estimatedCost => 0;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 180);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 5);

  @override
  Future<CoachContextPatch> build(AIContextRequest request) async {
    final history = await _repository.getWorkoutHistory(request.userId);
    return CoachContextPatch(workoutHistory: history);
  }
}
