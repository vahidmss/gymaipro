import 'package:gymaipro/ai/context/coach_context_patch.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_definitions.dart';

/// Human-readable provider architecture notes.
class AIContextProviderDescriptor {
  const AIContextProviderDescriptor({
    required this.dataSource,
    required this.readStrategy,
    required this.cacheStrategy,
    required this.missingBehaviour,
    required this.futureMigrationNotes,
  });

  /// Source of truth or placeholder source.
  final String dataSource;

  /// How the provider reads data.
  final String readStrategy;

  /// Cache policy description.
  final String cacheStrategy;

  /// Behavior when data is missing.
  final String missingBehaviour;

  /// Notes for future migration.
  final String futureMigrationNotes;
}

/// Contract for independently composable AI context providers.
///
/// Providers should be small adapters over existing services. New providers can
/// be added to the context builder without changing the engine itself.
abstract interface class AIContextProvider {
  /// Stable provider id used for logging and future diagnostics.
  String get id;

  /// Human-readable provider name.
  String get name;

  /// Granular provider capabilities used by intent-based selection.
  Set<AIContextProviderKey> get providedKeys;

  /// Context sections produced by this provider.
  Set<AIContextSection> get providedSections;

  /// Provider metadata used for selection, caching, and diagnostics.
  AIContextProviderMetadata get metadata;

  /// Default selection priority.
  ContextPriority get priority;

  /// Relative provider cost. Zero means no paid AI/API cost is expected.
  double get estimatedCost;

  /// Expected provider latency.
  Duration get estimatedLatency;

  /// Whether provider output can be cached safely.
  bool get cacheable;

  /// Suggested cache TTL.
  Duration get ttl;

  /// Builds a partial coach context patch for the given request.
  Future<CoachContextPatch> build(AIContextRequest request);
}

/// Provider selection result for a resolved intent.
class AIContextProviderSelection {
  const AIContextProviderSelection({
    required this.intentDefinition,
    required this.requiredProviders,
    required this.optionalProviders,
    required this.missingRequiredProviders,
    required this.missingOptionalProviders,
  });

  /// Intent definition used for selection.
  final AIIntentDefinition intentDefinition;

  /// Providers selected because they cover required context keys.
  final List<AIContextProvider> requiredProviders;

  /// Providers selected because they cover optional context keys.
  final List<AIContextProvider> optionalProviders;

  /// Required context keys that no registered provider can currently satisfy.
  final Set<AIContextProviderKey> missingRequiredProviders;

  /// Optional context keys that no registered provider can currently satisfy.
  final Set<AIContextProviderKey> missingOptionalProviders;

  /// All selected providers without duplicates.
  List<AIContextProvider> get providers {
    final byId = <String, AIContextProvider>{};
    for (final provider in requiredProviders) {
      byId[provider.id] = provider;
    }
    for (final provider in optionalProviders) {
      byId[provider.id] = provider;
    }
    return List<AIContextProvider>.unmodifiable(byId.values);
  }
}
