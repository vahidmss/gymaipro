import 'package:gymaipro/ai/context/coach_context_patch.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides the current active workout program for Coach v2.
class ActiveProgramContextProvider implements AIContextProvider {
  ActiveProgramContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  final AIContextRepository _repository;

  /// Architecture documentation for this provider.
  AIContextProviderDescriptor get descriptor =>
      const AIContextProviderDescriptor(
        dataSource: 'ActiveProgramService.getActiveProgramState()',
        readStrategy: 'Read-only active program state fetch.',
        cacheStrategy:
            'Cacheable for 2 minutes; program state can change in-session.',
        missingBehaviour: 'Return workout context with null activeProgram.',
        futureMigrationNotes:
            'Move to a typed ActiveProgramContext when available.',
      );

  @override
  String get id => 'active_program_context_provider';

  @override
  String get name => 'Active Program Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.activeProgram,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.workout,
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
  Duration get estimatedLatency => const Duration(milliseconds: 120);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 2);

  @override
  Future<CoachContextPatch> build(AIContextRequest request) async {
    final activeProgram = await _repository.getActiveProgram();
    return CoachContextPatch(activeProgram: activeProgram);
  }
}
