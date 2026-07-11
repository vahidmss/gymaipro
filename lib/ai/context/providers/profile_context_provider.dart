import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides the raw user profile for Coach v2.
class ProfileContextProvider implements AIContextProvider {
  ProfileContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  final AIContextRepository _repository;

  /// Architecture documentation for this provider.
  AIContextProviderDescriptor get descriptor =>
      const AIContextProviderDescriptor(
        dataSource: 'ProfileRepository.fetchProfile(userId)',
        readStrategy:
            'Read-only profile row fetch through AIContextRepository.',
        cacheStrategy:
            'Cacheable for 5 minutes; profile service may cache internally.',
        missingBehaviour: 'Return an empty profile context.',
        futureMigrationNotes:
            'Split stable coach profile fields into typed models.',
      );

  @override
  String get id => 'profile_context_provider';

  @override
  String get name => 'Profile Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.profile,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.userProfile,
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
  Duration get estimatedLatency => const Duration(milliseconds: 120);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 5);

  @override
  Future<PromptContextPatch> build(AIContextRequest request) async {
    final profile = await _repository.getProfile(request.userId);
    return PromptContextPatch(
      userProfile: AIUserProfileContext(data: profile ?? const {}),
    );
  }
}
