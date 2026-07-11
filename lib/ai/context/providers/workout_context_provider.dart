import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides workout-related context from existing workout services.
///
/// Deprecated migration path: active program and workout history moved to
/// ActiveProgramContextProvider and WorkoutHistoryContextProvider.
@Deprecated(
  'Use ActiveProgramContextProvider and WorkoutHistoryContextProvider.',
)
class WorkoutContextProvider implements AIContextProvider {
  @Deprecated(
    'Use ActiveProgramContextProvider and WorkoutHistoryContextProvider.',
  )
  WorkoutContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  final AIContextRepository _repository;

  @override
  String get id => 'workout_context_provider';

  @override
  String get name => 'Workout Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.activeProgram,
    AIContextProviderKey.workoutHistory,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.workout,
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
  ContextPriority get priority => ContextPriority.required;

  @override
  double get estimatedCost => 0;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 180);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 2);

  @override
  Future<PromptContextPatch> build(AIContextRequest request) async {
    final activeProgram = await _repository.getActiveProgram();
    final history = await _repository.getWorkoutHistory(request.userId);

    return PromptContextPatch(
      workout: AIWorkoutContext(activeProgram: activeProgram, history: history),
    );
  }
}
