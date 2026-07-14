import 'package:gymaipro/ai/context/coach_context_patch.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides available equipment for Coach v2.
class EquipmentContextProvider implements AIContextProvider {
  EquipmentContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  final AIContextRepository _repository;

  /// Architecture documentation for this provider.
  AIContextProviderDescriptor
  get descriptor => const AIContextProviderDescriptor(
    dataSource:
        'profiles.bb_equipment_access and questionnaire bb_equipment_access',
    readStrategy:
        'Read-only unified field adapter through AIContextRepository.',
    cacheStrategy: 'Cacheable for 30 minutes; equipment changes infrequently.',
    missingBehaviour:
        'Return an empty equipment list with no fallback guessing.',
    futureMigrationNotes:
        'Persist questionnaire equipment answers into profile consistently.',
  );

  @override
  String get id => 'equipment_context_provider';

  @override
  String get name => 'Equipment Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.equipment,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.equipment,
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
  Duration get estimatedLatency => const Duration(milliseconds: 100);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 30);

  @override
  Future<CoachContextPatch> build(AIContextRequest request) async {
    final equipment = await _repository.getEquipment(request.userId);
    return CoachContextPatch(equipment: equipment);
  }
}
