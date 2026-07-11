import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides progress-oriented context such as goals and muscle heatmap data.
///
/// Deprecated migration path: goals and heatmap moved to GoalsContextProvider
/// and HeatmapContextProvider.
@Deprecated('Use GoalsContextProvider and HeatmapContextProvider.')
class ProgressContextProvider implements AIContextProvider {
  @Deprecated('Use GoalsContextProvider and HeatmapContextProvider.')
  ProgressContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  final AIContextRepository _repository;

  @override
  String get id => 'progress_context_provider';

  @override
  String get name => 'Progress Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.goals,
    AIContextProviderKey.heatmap,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.goal,
    AIContextSection.heatmap,
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
  Duration get estimatedLatency => const Duration(milliseconds: 260);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 10);

  @override
  Future<PromptContextPatch> build(AIContextRequest request) async {
    final goals = await _repository.getGoals(request.userId);
    final heatmap = await _repository.getWeeklyHeatmap(request.userId);

    return PromptContextPatch(
      goal: AIGoalContext(goals: goals),
      heatmap: AIHeatmapContext(weekly: heatmap),
    );
  }
}
