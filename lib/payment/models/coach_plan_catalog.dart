import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/entitlement/entitlement_registry.dart';
import 'package:gymaipro/ai/entitlement/subscription_capability_map.dart';
import 'package:gymaipro/payment/models/ai_coach_plan_price.dart';
import 'package:gymaipro/payment/models/payment_plan.dart';
import 'package:gymaipro/payment/models/subscription.dart';

/// کاتالوگ پلن‌های قابل خرید مربی هوشمند + نگاشت به اشتراک اپ
class CoachPlanCatalog {
  const CoachPlanCatalog._();

  static const String coachProId = 'coach_pro';
  static const String ultimateAiId = 'ultimate_ai';

  /// پلن‌های فروش در فاز اول (به‌جز Free که فقط نمایش است)
  static const List<String> sellablePlanIds = <String>[
    coachProId,
    ultimateAiId,
  ];

  static CoachSubscriptionPlan planFromId(String planId) {
    switch (planId) {
      case coachProId:
        return CoachSubscriptionPlan.coachPro;
      case ultimateAiId:
        return CoachSubscriptionPlan.ultimateAI;
      case 'free':
        return CoachSubscriptionPlan.free;
      default:
        return CoachSubscriptionPlan.free;
    }
  }

  static String idFromPlan(CoachSubscriptionPlan plan) {
    switch (plan) {
      case CoachSubscriptionPlan.coachPro:
        return coachProId;
      case CoachSubscriptionPlan.ultimateAI:
        return ultimateAiId;
      case CoachSubscriptionPlan.free:
        return 'free';
      case CoachSubscriptionPlan.nutritionPro:
        return 'nutrition_pro';
      case CoachSubscriptionPlan.recoveryPro:
        return 'recovery_pro';
      case CoachSubscriptionPlan.enterprise:
        return 'enterprise';
      case CoachSubscriptionPlan.lifetime:
        return 'lifetime';
    }
  }

  static SubscriptionType subscriptionTypeForPlanId(String planId) {
    switch (planId) {
      case coachProId:
        return SubscriptionType.monthly;
      case ultimateAiId:
        return SubscriptionType.aiPremium;
      default:
        return SubscriptionType.monthly;
    }
  }

  static CoachSubscriptionPlan planFromSubscriptionType(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
      case SubscriptionType.trainerAccess:
        return CoachSubscriptionPlan.coachPro;
      case SubscriptionType.aiPremium:
      case SubscriptionType.fullAccess:
        return CoachSubscriptionPlan.ultimateAI;
    }
  }

  static String persianTitle(CoachSubscriptionPlan plan) {
    switch (plan) {
      case CoachSubscriptionPlan.free:
        return 'رایگان';
      case CoachSubscriptionPlan.coachPro:
        return 'Coach Pro';
      case CoachSubscriptionPlan.ultimateAI:
        return 'Ultimate AI';
      case CoachSubscriptionPlan.nutritionPro:
        return 'Nutrition Pro';
      case CoachSubscriptionPlan.recoveryPro:
        return 'Recovery Pro';
      case CoachSubscriptionPlan.enterprise:
        return 'سازمانی';
      case CoachSubscriptionPlan.lifetime:
        return 'مادام‌العمر';
    }
  }

  static String persianTitleForId(String planId) {
    return persianTitle(planFromId(planId));
  }

  static String persianCapabilityTitle(CoachCapability capability) {
    switch (capability) {
      case CoachCapability.generateWorkout:
        return 'ساخت برنامه تمرینی';
      case CoachCapability.modifyWorkout:
        return 'ویرایش برنامه';
      case CoachCapability.analyzeProgress:
        return 'تحلیل پیشرفت';
      case CoachCapability.explainHeatmap:
        return 'توضیح نقشه عضلانی';
      case CoachCapability.recoveryAnalysis:
        return 'تحلیل ریکاوری';
      case CoachCapability.nutritionPlanning:
        return 'برنامه تغذیه';
      case CoachCapability.supplementAdvice:
        return 'مشاوره مکمل';
      case CoachCapability.advancedMemory:
        return 'حافظه پیشرفته مربی';
      case CoachCapability.unlimitedMessages:
        return 'پیام‌های نامحدود';
      case CoachCapability.coachConversation:
        return 'گفتگو با مربی';
      case CoachCapability.aiWorkoutReview:
        return 'بازبینی تمرین با AI';
      case CoachCapability.aiProgramReview:
        return 'بازبینی برنامه با AI';
      case CoachCapability.aiNutritionReview:
        return 'بازبینی تغذیه با AI';
      case CoachCapability.premiumReasoning:
        return 'استدلال پیشرفته AI';
    }
  }

  static List<String> featureLabelsForPlan(CoachSubscriptionPlan plan) {
    final caps = SubscriptionCapabilityMap.capabilities[plan] ?? <CoachCapability>{};
    return caps.map(persianCapabilityTitle).toList(growable: false);
  }

  static AiCoachPlanPrice fallbackPrice(String planId) {
    final now = DateTime.now();
    switch (planId) {
      case ultimateAiId:
        return AiCoachPlanPrice(
          id: 'fallback_ultimate_ai',
          planId: ultimateAiId,
          title: 'Ultimate AI',
          description: 'دسترسی کامل به تمام قابلیت‌های مربی هوشمند',
          priceRial: 1990000,
          validityDays: 31,
          features: featureLabelsForPlan(CoachSubscriptionPlan.ultimateAI),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
      case coachProId:
      default:
        return AiCoachPlanPrice(
          id: 'fallback_coach_pro',
          planId: coachProId,
          title: 'Coach Pro',
          description: 'دسترسی پیشرفته مربی هوشمند برای تمرین و بازبینی برنامه',
          priceRial: 990000,
          validityDays: 31,
          features: featureLabelsForPlan(CoachSubscriptionPlan.coachPro),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
    }
  }

  static PaymentPlan toPaymentPlan(AiCoachPlanPrice price) {
    final plan = planFromId(price.planId);
    final features = price.features.isNotEmpty
        ? price.features
        : featureLabelsForPlan(plan);
    return PaymentPlan(
      id: price.planId,
      name: price.title.isNotEmpty ? price.title : persianTitle(plan),
      shortDescription: price.description,
      fullDescription: price.description,
      type: PaymentPlanType.subscription,
      accessLevel: plan == CoachSubscriptionPlan.ultimateAI
          ? PlanAccessLevel.premium
          : PlanAccessLevel.basic,
      price: price.priceRial,
      validityDays: price.validityDays,
      features: features,
      isPopular: price.planId == ultimateAiId,
      createdAt: price.createdAt,
      updatedAt: price.updatedAt,
    );
  }

  static String descriptionForPlan(CoachSubscriptionPlan plan) {
    switch (plan) {
      case CoachSubscriptionPlan.free:
        return 'دسترسی پایه به گفتگو و توضیح نقشه عضلانی';
      case CoachSubscriptionPlan.coachPro:
        return 'برنامه تمرینی، ویرایش، ریکاوری و بازبینی با مربی هوشمند';
      case CoachSubscriptionPlan.ultimateAI:
        return 'تمام قابلیت‌های مربی هوشمند شامل تغذیه و استدلال پیشرفته';
      case CoachSubscriptionPlan.nutritionPro:
      case CoachSubscriptionPlan.recoveryPro:
      case CoachSubscriptionPlan.enterprise:
      case CoachSubscriptionPlan.lifetime:
        return EntitlementRegistry.defaultPlans[plan]?.description ?? '';
    }
  }
}
