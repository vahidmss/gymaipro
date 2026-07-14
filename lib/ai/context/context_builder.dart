import 'package:gymaipro/ai/context/coach_context_patch.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/active_program_context_provider.dart';
import 'package:gymaipro/ai/context/providers/api_usage_context_provider.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';
import 'package:gymaipro/ai/context/providers/chat_context_provider.dart';
import 'package:gymaipro/ai/context/providers/equipment_context_provider.dart';
import 'package:gymaipro/ai/context/providers/goals_context_provider.dart';
import 'package:gymaipro/ai/context/providers/heatmap_context_provider.dart';
import 'package:gymaipro/ai/context/providers/preferences_context_provider.dart';
import 'package:gymaipro/ai/context/providers/profile_context_provider.dart';
import 'package:gymaipro/ai/context/providers/recovery_context_provider.dart';
import 'package:gymaipro/ai/context/providers/restrictions_context_provider.dart';
import 'package:gymaipro/ai/context/providers/workout_history_context_provider.dart';

/// Builds intermediate provider patches for coach context assembly.
///
/// Providers return partial [CoachContextPatch] values. The unified output is
/// assembled by [CoachContextAssembler] in the engine layer.
class AIContextBuilder {
  AIContextBuilder({List<AIContextProvider> providers = const []})
    : _providers = List<AIContextProvider>.unmodifiable(providers);

  /// Creates the phase-1 provider set with a shared repository adapter.
  factory AIContextBuilder.standard({AIContextRepository? repository}) {
    final sharedRepository = repository ?? AIContextRepository();
    return AIContextBuilder(
      providers: <AIContextProvider>[
        ProfileContextProvider(repository: sharedRepository),
        GoalsContextProvider(repository: sharedRepository),
        EquipmentContextProvider(repository: sharedRepository),
        RestrictionsContextProvider(repository: sharedRepository),
        PreferencesContextProvider(repository: sharedRepository),
        ActiveProgramContextProvider(repository: sharedRepository),
        WorkoutHistoryContextProvider(repository: sharedRepository),
        HeatmapContextProvider(repository: sharedRepository),
        ApiUsageContextProvider(repository: sharedRepository),
        // ignore: deprecated_member_use_from_same_package
        ChatContextProvider(repository: sharedRepository),
        // ignore: deprecated_member_use_from_same_package
        RecoveryContextProvider(repository: sharedRepository),
      ],
    );
  }

  final List<AIContextProvider> _providers;

  /// Providers registered for this builder.
  List<AIContextProvider> get providers => _providers;

  /// Builds context by applying provider patches in registration order.
  Future<CoachContextPatch> build(
    AIContextRequest request, {
    CoachContextPatch seed = CoachContextPatch.empty,
  }) async {
    return buildForProviders(request, _providers, seed: seed);
  }

  /// Builds context using only the selected providers.
  Future<CoachContextPatch> buildForProviders(
    AIContextRequest request,
    List<AIContextProvider> providers, {
    CoachContextPatch seed = CoachContextPatch.empty,
  }) async {
    var patch = seed;

    for (final provider in providers) {
      final providerPatch = await provider.build(request);
      patch = patch.merge(providerPatch);
    }

    return patch;
  }
}
