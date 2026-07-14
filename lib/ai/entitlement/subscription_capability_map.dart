import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';

/// Capability bundles for each subscription plan.
///
/// This is the only place where plans map to capabilities. Runtime code should
/// depend on capabilities instead of inspecting plans directly.
class SubscriptionCapabilityMap {
  const SubscriptionCapabilityMap._();

  static const Map<CoachSubscriptionPlan, Set<CoachCapability>> capabilities =
      <CoachSubscriptionPlan, Set<CoachCapability>>{
        CoachSubscriptionPlan.free: <CoachCapability>{
          CoachCapability.explainHeatmap,
          CoachCapability.coachConversation,
        },
        CoachSubscriptionPlan.coachPro: <CoachCapability>{
          CoachCapability.generateWorkout,
          CoachCapability.modifyWorkout,
          CoachCapability.explainHeatmap,
          CoachCapability.recoveryAnalysis,
          CoachCapability.advancedMemory,
          CoachCapability.unlimitedMessages,
          CoachCapability.coachConversation,
          CoachCapability.aiWorkoutReview,
          CoachCapability.aiProgramReview,
        },
        CoachSubscriptionPlan.nutritionPro: <CoachCapability>{
          CoachCapability.nutritionPlanning,
          CoachCapability.supplementAdvice,
          CoachCapability.coachConversation,
          CoachCapability.aiNutritionReview,
        },
        CoachSubscriptionPlan.recoveryPro: <CoachCapability>{
          CoachCapability.explainHeatmap,
          CoachCapability.recoveryAnalysis,
          CoachCapability.coachConversation,
          CoachCapability.premiumReasoning,
        },
        CoachSubscriptionPlan.ultimateAI: <CoachCapability>{
          CoachCapability.generateWorkout,
          CoachCapability.modifyWorkout,
          CoachCapability.analyzeProgress,
          CoachCapability.explainHeatmap,
          CoachCapability.recoveryAnalysis,
          CoachCapability.nutritionPlanning,
          CoachCapability.supplementAdvice,
          CoachCapability.advancedMemory,
          CoachCapability.unlimitedMessages,
          CoachCapability.coachConversation,
          CoachCapability.aiWorkoutReview,
          CoachCapability.aiProgramReview,
          CoachCapability.aiNutritionReview,
          CoachCapability.premiumReasoning,
        },
        CoachSubscriptionPlan.enterprise: <CoachCapability>{
          CoachCapability.generateWorkout,
          CoachCapability.modifyWorkout,
          CoachCapability.analyzeProgress,
          CoachCapability.explainHeatmap,
          CoachCapability.recoveryAnalysis,
          CoachCapability.nutritionPlanning,
          CoachCapability.supplementAdvice,
          CoachCapability.advancedMemory,
          CoachCapability.unlimitedMessages,
          CoachCapability.coachConversation,
          CoachCapability.aiWorkoutReview,
          CoachCapability.aiProgramReview,
          CoachCapability.aiNutritionReview,
          CoachCapability.premiumReasoning,
        },
        CoachSubscriptionPlan.lifetime: <CoachCapability>{
          CoachCapability.generateWorkout,
          CoachCapability.modifyWorkout,
          CoachCapability.analyzeProgress,
          CoachCapability.explainHeatmap,
          CoachCapability.recoveryAnalysis,
          CoachCapability.nutritionPlanning,
          CoachCapability.supplementAdvice,
          CoachCapability.advancedMemory,
          CoachCapability.unlimitedMessages,
          CoachCapability.coachConversation,
          CoachCapability.aiWorkoutReview,
          CoachCapability.aiProgramReview,
          CoachCapability.aiNutritionReview,
          CoachCapability.premiumReasoning,
        },
      };

  /// Capabilities granted by [plan].
  static Set<CoachCapability> forPlan(CoachSubscriptionPlan plan) {
    return Set<CoachCapability>.unmodifiable(
      capabilities[plan] ?? const <CoachCapability>{},
    );
  }
}
