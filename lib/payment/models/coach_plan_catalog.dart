import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/entitlement/entitlement_registry.dart';
import 'package:gymaipro/ai/entitlement/subscription_capability_map.dart';
import 'package:gymaipro/payment/models/ai_coach_plan_price.dart';
import 'package:gymaipro/payment/models/payment_plan.dart';
import 'package:gymaipro/payment/models/subscription.dart';

/// کاتالوگ محصول مربی هوشمند — یک SKU قابل فروش (برنامه AI).
class CoachPlanCatalog {
  const CoachPlanCatalog._();

  /// شناسه پایدار محصول در DB / ادمین قیمت‌ها.
  static const String coachProId = 'coach_pro';

  /// نگه داشته می‌شود فقط برای اشتراک‌های قدیمی Ultimate.
  static const String ultimateAiId = 'ultimate_ai';

  /// مدت پیش‌فرض دسترسی برنامه (روز).
  static const int defaultValidityDays = 33;

  /// فقط یک محصول قابل خرید.
  static const List<String> sellablePlanIds = <String>[coachProId];

  /// عنوان محصول‌محور برای UI فروش.
  static const String productTitle = 'برنامه مربی هوشمند';

  static const String productDescription =
      'یک برنامه تمرینی منعطف با مربی هوشمند — تا ۳۳ روز ساخت، اصلاح، '
      'تمرین لایو و گفتگو در اختیارت است.';

  static const List<String> productFeatures = <String>[
    'ساخت برنامه تمرینی شخصی با هوش مصنوعی',
    'اصلاح و تنظیم برنامه در طول دوره',
    'تمرین امروز و لایو هوشمند',
    'گفتگو و راهنمایی مربی',
    'ریکاوری و بازبینی جلسه',
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

  /// True when this plan grants the AI program toolkit (active pass).
  static bool isPaidAiProgramPlan(CoachSubscriptionPlan plan) {
    return plan != CoachSubscriptionPlan.free &&
        plan != CoachSubscriptionPlan.nutritionPro &&
        plan != CoachSubscriptionPlan.recoveryPro;
  }

  static String persianTitle(CoachSubscriptionPlan plan) {
    switch (plan) {
      case CoachSubscriptionPlan.free:
        return 'رایگان';
      case CoachSubscriptionPlan.coachPro:
      case CoachSubscriptionPlan.ultimateAI:
        return productTitle;
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
    if (plan == CoachSubscriptionPlan.coachPro ||
        plan == CoachSubscriptionPlan.ultimateAI) {
      return productFeatures;
    }
    final caps =
        SubscriptionCapabilityMap.capabilities[plan] ?? <CoachCapability>{};
    return caps.map(persianCapabilityTitle).toList(growable: false);
  }

  static AiCoachPlanPrice fallbackPrice(String planId) {
    final now = DateTime.now();
    // Single sellable product — ultimate id maps to same product for legacy rows.
    return AiCoachPlanPrice(
      id: 'fallback_ai_program',
      planId: coachProId,
      title: productTitle,
      description: productDescription,
      priceRial: 990000,
      validityDays: defaultValidityDays,
      features: productFeatures,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  static PaymentPlan toPaymentPlan(AiCoachPlanPrice price) {
    final plan = planFromId(price.planId);
    final features = price.features.isNotEmpty
        ? price.features
        : featureLabelsForPlan(plan);
    final title = price.title.isNotEmpty ? price.title : productTitle;
    return PaymentPlan(
      id: price.planId == ultimateAiId ? coachProId : price.planId,
      name: title,
      shortDescription: price.description.isNotEmpty
          ? price.description
          : productDescription,
      fullDescription: price.description.isNotEmpty
          ? price.description
          : productDescription,
      type: PaymentPlanType.subscription,
      accessLevel: PlanAccessLevel.basic,
      price: price.priceRial,
      validityDays: price.validityDays > 0
          ? price.validityDays
          : defaultValidityDays,
      features: features,
      isPopular: true,
      createdAt: price.createdAt,
      updatedAt: price.updatedAt,
    );
  }

  static String descriptionForPlan(CoachSubscriptionPlan plan) {
    switch (plan) {
      case CoachSubscriptionPlan.free:
        return 'وضعیت و ریکاوری محلی؛ برای برنامه هوشمند، برنامه بخر.';
      case CoachSubscriptionPlan.coachPro:
      case CoachSubscriptionPlan.ultimateAI:
        return productDescription;
      case CoachSubscriptionPlan.nutritionPro:
      case CoachSubscriptionPlan.recoveryPro:
      case CoachSubscriptionPlan.enterprise:
      case CoachSubscriptionPlan.lifetime:
        return EntitlementRegistry.defaultPlans[plan]?.description ?? '';
    }
  }

  /// برچسب بج هاب: روز مانده یا دعوت به خرید.
  static String hubBadgeLabel({
    required CoachSubscriptionPlan plan,
    int? daysRemaining,
  }) {
    if (!isPaidAiProgramPlan(plan)) {
      return 'خرید برنامه';
    }
    if (daysRemaining == null) return productTitle;
    if (daysRemaining <= 0) return 'خرید برنامه';
    if (daysRemaining == 1) return '۱ روز مانده';
    return '$daysRemaining روز مانده';
  }
}
