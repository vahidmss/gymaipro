import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/entitlement/subscription_capability_map.dart';

/// Registry for entitlement capability and plan metadata.
class EntitlementRegistry {
  const EntitlementRegistry({
    this.capabilities = defaultCapabilities,
    this.plans = defaultPlans,
  });

  /// Default capability metadata.
  static const Map<CoachCapability, CoachCapabilityDefinition>
  defaultCapabilities = <CoachCapability, CoachCapabilityDefinition>{
    CoachCapability.generateWorkout: CoachCapabilityDefinition(
      capability: CoachCapability.generateWorkout,
      id: 'generate_workout',
      title: 'Generate Workout',
      description: 'Create a personalized workout program.',
      requiresOnlineAI: true,
      defaultDailyLimit: 1,
      tags: <String>['workout', 'generation'],
    ),
    CoachCapability.modifyWorkout: CoachCapabilityDefinition(
      capability: CoachCapability.modifyWorkout,
      id: 'modify_workout',
      title: 'Modify Workout',
      description: 'Modify an existing workout plan or session.',
      requiresOnlineAI: true,
      defaultDailyLimit: 3,
      tags: <String>['workout', 'editing'],
    ),
    CoachCapability.analyzeProgress: CoachCapabilityDefinition(
      capability: CoachCapability.analyzeProgress,
      id: 'analyze_progress',
      title: 'Analyze Progress',
      description: 'Analyze training progress and trend signals.',
      requiresOnlineAI: true,
      defaultDailyLimit: 2,
      tags: <String>['progress'],
    ),
    CoachCapability.explainHeatmap: CoachCapabilityDefinition(
      capability: CoachCapability.explainHeatmap,
      id: 'explain_heatmap',
      title: 'Explain Heatmap',
      description: 'Explain muscle heatmap and weekly load.',
      defaultDailyLimit: 5,
      tags: <String>['heatmap', 'local'],
    ),
    CoachCapability.recoveryAnalysis: CoachCapabilityDefinition(
      capability: CoachCapability.recoveryAnalysis,
      id: 'recovery_analysis',
      title: 'Recovery Analysis',
      description: 'Analyze readiness and recovery needs.',
      requiresOnlineAI: true,
      defaultDailyLimit: 3,
      tags: <String>['recovery'],
    ),
    CoachCapability.nutritionPlanning: CoachCapabilityDefinition(
      capability: CoachCapability.nutritionPlanning,
      id: 'nutrition_planning',
      title: 'Nutrition Planning',
      description: 'Plan nutrition and meal guidance.',
      requiresOnlineAI: true,
      defaultDailyLimit: 2,
      tags: <String>['nutrition'],
    ),
    CoachCapability.supplementAdvice: CoachCapabilityDefinition(
      capability: CoachCapability.supplementAdvice,
      id: 'supplement_advice',
      title: 'Supplement Advice',
      description: 'Provide supplement guidance.',
      requiresOnlineAI: true,
      defaultDailyLimit: 3,
      tags: <String>['nutrition', 'supplement'],
    ),
    CoachCapability.advancedMemory: CoachCapabilityDefinition(
      capability: CoachCapability.advancedMemory,
      id: 'advanced_memory',
      title: 'Advanced Memory',
      description: 'Use long-term coach memory.',
      tags: <String>['memory'],
    ),
    CoachCapability.unlimitedMessages: CoachCapabilityDefinition(
      capability: CoachCapability.unlimitedMessages,
      id: 'unlimited_messages',
      title: 'Unlimited Messages',
      description: 'Remove standard daily message limits.',
      tags: <String>['usage'],
    ),
    CoachCapability.coachConversation: CoachCapabilityDefinition(
      capability: CoachCapability.coachConversation,
      id: 'coach_conversation',
      title: 'Coach Conversation',
      description: 'Use conversational GymAI Coach.',
      defaultDailyLimit: 10,
      tags: <String>['chat'],
    ),
    CoachCapability.aiWorkoutReview: CoachCapabilityDefinition(
      capability: CoachCapability.aiWorkoutReview,
      id: 'ai_workout_review',
      title: 'AI Workout Review',
      description: 'Review workout logs and execution quality.',
      requiresOnlineAI: true,
      defaultDailyLimit: 3,
      tags: <String>['workout', 'review'],
    ),
    CoachCapability.aiProgramReview: CoachCapabilityDefinition(
      capability: CoachCapability.aiProgramReview,
      id: 'ai_program_review',
      title: 'AI Program Review',
      description: 'Review program structure and fit.',
      requiresOnlineAI: true,
      defaultDailyLimit: 2,
      tags: <String>['program', 'review'],
    ),
    CoachCapability.aiNutritionReview: CoachCapabilityDefinition(
      capability: CoachCapability.aiNutritionReview,
      id: 'ai_nutrition_review',
      title: 'AI Nutrition Review',
      description: 'Review nutrition logs or plans.',
      requiresOnlineAI: true,
      defaultDailyLimit: 2,
      tags: <String>['nutrition', 'review'],
    ),
    CoachCapability.premiumReasoning: CoachCapabilityDefinition(
      capability: CoachCapability.premiumReasoning,
      id: 'premium_reasoning',
      title: 'Premium Reasoning',
      description: 'Use deeper AI reasoning for complex coach requests.',
      requiresOnlineAI: true,
      defaultTokenLimit: 100000,
      tags: <String>['reasoning'],
    ),
  };

  /// Default subscription plan metadata.
  static const Map<CoachSubscriptionPlan, CoachSubscriptionPlanDefinition>
  defaultPlans = <CoachSubscriptionPlan, CoachSubscriptionPlanDefinition>{
    CoachSubscriptionPlan.free: CoachSubscriptionPlanDefinition(
      plan: CoachSubscriptionPlan.free,
      id: 'free',
      title: 'Free',
      description: 'Starter access to basic Coach capabilities.',
    ),
    CoachSubscriptionPlan.coachPro: CoachSubscriptionPlanDefinition(
      plan: CoachSubscriptionPlan.coachPro,
      id: 'coach_pro',
      title: 'Coach Pro',
      description: 'Workout-focused Coach capabilities.',
      rank: 20,
    ),
    CoachSubscriptionPlan.nutritionPro: CoachSubscriptionPlanDefinition(
      plan: CoachSubscriptionPlan.nutritionPro,
      id: 'nutrition_pro',
      title: 'Nutrition Pro',
      description: 'Nutrition-focused Coach capabilities.',
      rank: 20,
    ),
    CoachSubscriptionPlan.recoveryPro: CoachSubscriptionPlanDefinition(
      plan: CoachSubscriptionPlan.recoveryPro,
      id: 'recovery_pro',
      title: 'Recovery Pro',
      description: 'Recovery-focused Coach capabilities.',
      rank: 20,
    ),
    CoachSubscriptionPlan.ultimateAI: CoachSubscriptionPlanDefinition(
      plan: CoachSubscriptionPlan.ultimateAI,
      id: 'ultimate_ai',
      title: 'Ultimate AI',
      description: 'All AI Coach capabilities.',
      rank: 100,
    ),
    CoachSubscriptionPlan.enterprise: CoachSubscriptionPlanDefinition(
      plan: CoachSubscriptionPlan.enterprise,
      id: 'enterprise',
      title: 'Enterprise',
      description: 'Organization-managed Coach capabilities.',
      rank: 200,
    ),
    CoachSubscriptionPlan.lifetime: CoachSubscriptionPlanDefinition(
      plan: CoachSubscriptionPlan.lifetime,
      id: 'lifetime',
      title: 'Lifetime',
      description: 'Permanent Coach capability access.',
      rank: 300,
    ),
  };

  /// Capability definitions.
  final Map<CoachCapability, CoachCapabilityDefinition> capabilities;

  /// Plan definitions.
  final Map<CoachSubscriptionPlan, CoachSubscriptionPlanDefinition> plans;

  /// Returns metadata for [capability].
  CoachCapabilityDefinition? capabilityDefinition(CoachCapability capability) {
    return capabilities[capability];
  }

  /// Returns metadata for [plan].
  CoachSubscriptionPlanDefinition? planDefinition(CoachSubscriptionPlan plan) {
    return plans[plan];
  }

  /// Capabilities granted by [plan].
  Set<CoachCapability> capabilitiesForPlan(CoachSubscriptionPlan plan) {
    return SubscriptionCapabilityMap.forPlan(plan);
  }

  /// Finds the lowest-ranked active plan that includes [capability].
  CoachSubscriptionPlanDefinition? upgradePlanFor(CoachCapability capability) {
    final candidates = <CoachSubscriptionPlanDefinition>[];
    for (final entry in plans.entries) {
      final definition = entry.value;
      if (!definition.active) continue;
      if (capabilitiesForPlan(entry.key).contains(capability)) {
        candidates.add(definition);
      }
    }
    candidates.sort((a, b) => a.rank.compareTo(b.rank));
    return candidates.isEmpty ? null : candidates.first;
  }
}
