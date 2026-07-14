import 'package:gymaipro/ai/context/coach_context_patch.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides injuries, medical limits, and training restrictions for Coach v2.
class RestrictionsContextProvider implements AIContextProvider {
  RestrictionsContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  final AIContextRepository _repository;

  /// Architecture documentation for this provider.
  AIContextProviderDescriptor
  get descriptor => const AIContextProviderDescriptor(
    dataSource:
        'profiles.medical_conditions, bb_injury_* fields, confidential lifestyle health fields, questionnaire health answers',
    readStrategy:
        'Read-only unified field adapter without injury parsing rules.',
    cacheStrategy: 'Cacheable for 10 minutes via repository field snapshot.',
    missingBehaviour: 'Return an empty restrictions list.',
    futureMigrationNotes:
        'Add typed restriction models once canonical health storage is finalized.',
  );

  @override
  String get id => 'restrictions_context_provider';

  @override
  String get name => 'Restrictions Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.restrictions,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.restrictions,
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
  Duration get estimatedLatency => const Duration(milliseconds: 80);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 10);

  @override
  Future<CoachContextPatch> build(AIContextRequest request) async {
    final restrictions = await _repository.getRestrictions(request.userId);
    return CoachContextPatch(restrictions: restrictions);
  }
}
