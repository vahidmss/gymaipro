import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides AI usage and budget context for Coach v2.
class ApiUsageContextProvider implements AIContextProvider {
  ApiUsageContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  final AIContextRepository _repository;

  /// Architecture documentation for this provider.
  AIContextProviderDescriptor
  get descriptor => const AIContextProviderDescriptor(
    dataSource:
        'SharedPreferences ai_chat_daily_messages and progress_analysis_free_usage_count',
    readStrategy:
        'Read-only local snapshot adapter; avoids mutating usage services.',
    cacheStrategy: 'Cacheable for 1 minute; counters may change after AI use.',
    missingBehaviour: 'Return zeroed usage counters with known limits.',
    futureMigrationNotes:
        'Add read-only subscription entitlement snapshot without write side effects.',
  );

  @override
  String get id => 'api_usage_context_provider';

  @override
  String get name => 'API Usage Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.apiUsage,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.apiUsage,
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
  ContextPriority get priority => ContextPriority.low;

  @override
  double get estimatedCost => 0;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 20);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 1);

  @override
  Future<PromptContextPatch> build(AIContextRequest request) async {
    final usage = await _repository.getApiUsage(request.userId);
    return PromptContextPatch(apiUsage: AIAPIUsageContext(data: usage));
  }
}
