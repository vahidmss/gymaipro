import 'package:gymaipro/ai/context/coach_context_patch.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';
import 'package:gymaipro/meal_log/models/food_log.dart';
import 'package:gymaipro/meal_log/services/meal_log_service.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/utils/meal_nutrition_targets.dart';
import 'package:gymaipro/meal_log/utils/nutrition_copy.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/services/active_meal_plan_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';

/// Provides real nutrition data for Coach v2 prompts.
///
/// Injects daily macro targets (TDEE-based), today's logged intake, weekly
/// logging consistency, and active meal plan state — so nutrition answers are
/// grounded in the user's actual data instead of generic advice.
class NutritionContextProvider implements AIContextProvider {
  NutritionContextProvider({
    MealLogService? mealLogService,
    ActiveMealPlanService? activeMealPlanService,
  }) : _mealLogService = mealLogService ?? MealLogService(),
       _activeMealPlanService =
           activeMealPlanService ?? ActiveMealPlanService();

  final MealLogService _mealLogService;
  final ActiveMealPlanService _activeMealPlanService;

  /// Architecture documentation for this provider.
  AIContextProviderDescriptor get descriptor =>
      const AIContextProviderDescriptor(
        dataSource:
            'MealLogService, MealNutritionTargets, ActiveMealPlanService',
        readStrategy:
            "Read-only fetch of today's food log, macro targets from "
            'profile, and active meal plan pointer.',
        cacheStrategy: 'Relies on underlying service caches; no local cache.',
        missingBehaviour: 'Return an empty nutrition patch on any failure.',
        futureMigrationNotes:
            'Add weekly macro adherence trend and water intake.',
      );

  @override
  String get id => 'nutrition_context_provider';

  @override
  String get name => 'Nutrition Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.nutrition,
    AIContextProviderKey.supplements,
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
  ContextPriority get priority => ContextPriority.high;

  @override
  double get estimatedCost => 0;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 400);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 5);

  @override
  Future<CoachContextPatch> build(AIContextRequest request) async {
    try {
      final nutrition = <String, Object?>{};

      final profile = await SimpleProfileService.getCurrentProfile();
      final targets = MealNutritionTargets.fromProfile(profile);
      nutrition['daily_targets'] = NutritionCopy.dailyTargetsMap(targets);

      final today = await _todaySnapshot();
      if (today != null) nutrition['today'] = today;

      final loggedDays = await _loggedDaysLastWeek();
      if (loggedDays != null) {
        nutrition['logged_days_last_7'] = loggedDays;
      }

      final activeMealPlanId = await _activeMealPlanService
          .getActiveMealPlanId();
      nutrition['has_active_meal_plan'] =
          activeMealPlanId != null && activeMealPlanId.isNotEmpty;

      // Citation-ready line so the LLM cannot claim "I couldn't fetch nutrition".
      nutrition['summary_fa'] = NutritionCopy.summaryFa(
        targets: targets,
        today: today,
      );

      return CoachContextPatch(nutrition: nutrition);
    } on Object {
      return CoachContextPatch.empty;
    }
  }

  Future<Map<String, Object?>?> _todaySnapshot() async {
    try {
      final log = await _mealLogService.getLogForDate(DateTime.now());
      if (log == null) {
        return <String, Object?>{'logged': false};
      }
      final hasFood = log.meals.any((meal) => meal.foods.isNotEmpty);
      if (!hasFood) {
        return <String, Object?>{'logged': false};
      }

      final snapshot = <String, Object?>{
        'logged': true,
        'meals': <Object?>[
          for (final meal in log.meals)
            if (meal.foods.isNotEmpty)
              <String, Object?>{
                'title': meal.title,
                'items': meal.foods.length,
              },
        ],
      };

      final totals = await _totalsFor(log);
      if (totals != null) {
        snapshot['consumed'] = <String, Object?>{
          'calories_kcal': (totals['calories'] ?? 0).round(),
          'protein_g': (totals['protein'] ?? 0).round(),
          'carbs_g': (totals['carbs'] ?? 0).round(),
          'fat_g': (totals['fat'] ?? 0).round(),
        };
      }
      if (log.supplements.isNotEmpty) {
        snapshot['supplements_logged'] = log.supplements.length;
      }
      return snapshot;
    } on Object {
      return null;
    }
  }

  Future<Map<String, double>?> _totalsFor(FoodLog log) async {
    try {
      // Prefer warm cache; a cold catalog fetch must not stall the chat.
      List<Food>? foods = FoodService().peekCachedFoods();
      foods ??= await FoodService().getFoods().timeout(
        const Duration(seconds: 4),
      );
      if (foods.isEmpty) return null;
      return MealLogUtils.calculateTotals(log.meals, foods);
    } on Object {
      return null;
    }
  }

  Future<int?> _loggedDaysLastWeek() async {
    try {
      final now = DateTime.now();
      final logs = await _mealLogService.getLogsForDateRange(
        now.subtract(const Duration(days: 6)),
        now,
      );
      return logs.where((log) => log.meals.isNotEmpty).length;
    } on Object {
      return null;
    }
  }
}
