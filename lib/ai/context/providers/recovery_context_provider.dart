import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides recovery context for future coach recommendations.
///
/// Deprecated migration path: restrictions moved to RestrictionsContextProvider.
/// Keep this provider only until a dedicated recovery data source exists.
@Deprecated('Use RestrictionsContextProvider for restrictions in new code.')
class RecoveryContextProvider implements AIContextProvider {
  @Deprecated('Use RestrictionsContextProvider for restrictions in new code.')
  RecoveryContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  // ignore: unused_field
  final AIContextRepository _repository;

  @override
  String get id => 'recovery_context_provider';

  @override
  String get name => 'Recovery Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.recovery,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.recovery,
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
  ContextPriority get priority => ContextPriority.medium;

  @override
  double get estimatedCost => 0;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 160);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 10);

  @override
  Future<PromptContextPatch> build(AIContextRequest request) async {
    // TODO(ai-context): Replace this placeholder when a stable recovery source
    // exists (sleep, soreness, readiness, or rest-day state).
    return const PromptContextPatch(recovery: AIRecoveryContext());
  }
}
