import 'package:gymaipro/ai/context/coach_context_patch.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides user coaching and app preferences for Coach v2.
class PreferencesContextProvider implements AIContextProvider {
  PreferencesContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  final AIContextRepository _repository;

  /// Architecture documentation for this provider.
  AIContextProviderDescriptor
  get descriptor => const AIContextProviderDescriptor(
    dataSource:
        'profile training fields, confidential lifestyle_preferences, questionnaire preference answers',
    readStrategy:
        'Read-only unified field adapter through AIContextRepository.',
    cacheStrategy: 'Cacheable for 15 minutes; preferences are user-edited.',
    missingBehaviour: 'Return an empty preferences map.',
    futureMigrationNotes: 'Create typed coaching preference models.',
  );

  @override
  String get id => 'preferences_context_provider';

  @override
  String get name => 'Preferences Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.preferences,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.preferences,
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
  Duration get estimatedLatency => const Duration(milliseconds: 80);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 15);

  @override
  Future<CoachContextPatch> build(AIContextRequest request) async {
    final preferences = await _repository.getPreferences(request.userId);
    return CoachContextPatch(preferences: preferences);
  }
}
