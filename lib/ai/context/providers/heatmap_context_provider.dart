import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides weekly muscle heatmap data for Coach v2.
class HeatmapContextProvider implements AIContextProvider {
  HeatmapContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  final AIContextRepository _repository;

  /// Architecture documentation for this provider.
  AIContextProviderDescriptor get descriptor =>
      const AIContextProviderDescriptor(
        dataSource: 'WeeklyMuscleHeatmapService.loadForUser(userId)',
        readStrategy: 'Read-only weekly heatmap fetch.',
        cacheStrategy:
            'Cacheable for 10 minutes; heatmap changes with log updates.',
        missingBehaviour:
            'Return empty service result as provided by heatmap service.',
        futureMigrationNotes:
            'Add compact muscle-balance summaries for prompts.',
      );

  @override
  String get id => 'heatmap_context_provider';

  @override
  String get name => 'Heatmap Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.heatmap,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
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
    final heatmap = await _repository.getWeeklyHeatmap(request.userId);
    return PromptContextPatch(heatmap: AIHeatmapContext(weekly: heatmap));
  }
}
