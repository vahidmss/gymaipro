import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/context_repository.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';

/// Provides user training goals for Coach v2.
class GoalsContextProvider implements AIContextProvider {
  GoalsContextProvider({AIContextRepository? repository})
    : _repository = repository ?? AIContextRepository();

  final AIContextRepository _repository;

  /// Architecture documentation for this provider.
  AIContextProviderDescriptor
  get descriptor => const AIContextProviderDescriptor(
    dataSource:
        'profiles.fitness_goals, confidential lifestyle goals, questionnaire bb_goal_primary',
    readStrategy:
        'Read-only unified field adapter through AIContextRepository.',
    cacheStrategy: 'Cacheable for 10 minutes; goals rarely change in-session.',
    missingBehaviour: 'Return an empty goals list.',
    futureMigrationNotes:
        'Move goals into a typed CoachGoal model when stable.',
  );

  @override
  String get id => 'goals_context_provider';

  @override
  String get name => 'Goals Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.goals,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.goal,
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
  Duration get ttl => const Duration(minutes: 10);

  @override
  Future<PromptContextPatch> build(AIContextRequest request) async {
    final goals = await _repository.getGoals(request.userId);
    return PromptContextPatch(goal: AIGoalContext(goals: goals));
  }
}
