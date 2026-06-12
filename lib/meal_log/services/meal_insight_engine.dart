import 'package:gymaipro/meal_log/models/food_meal_log.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/utils/meal_nutrition_targets.dart';
import 'package:gymaipro/models/food.dart';

enum MealInsightTone { info, success, warning, tip }

class MealFoodSuggestion {
  const MealFoodSuggestion({
    required this.foodId,
    required this.label,
    this.mealTitle,
    this.amount,
    this.unit = 'گرم',
  });

  final int foodId;
  final String label;
  final String? mealTitle;
  final double? amount;
  final String unit;
}

class MealCalorieBarGuidance {
  const MealCalorieBarGuidance({
    required this.message,
    required this.tone,
  });

  final String message;
  final MealInsightTone tone;

  static const empty = MealCalorieBarGuidance(
    message: '',
    tone: MealInsightTone.info,
  );

  bool get hasContent => message.isNotEmpty;
}

class MealInsightResult {
  const MealInsightResult({
    required this.message,
    required this.tone,
    this.barGuidance = MealCalorieBarGuidance.empty,
    this.streakDays = 0,
    this.suggestions = const [],
    this.highlightMealTitle,
  });

  final String message;
  final MealInsightTone tone;
  final MealCalorieBarGuidance barGuidance;
  final int streakDays;
  final List<MealFoodSuggestion> suggestions;
  final String? highlightMealTitle;

  static const empty = MealInsightResult(
    message: '',
    tone: MealInsightTone.info,
  );

  bool get hasContent => message.isNotEmpty;

  /// Card body text — empty when bar guidance already covers the same facts.
  String get cardMessage =>
      hasDistinctCardMessage ? message : '';

  bool get hasDistinctCardMessage =>
      hasContent &&
      (!barGuidance.hasContent ||
          !MealInsightEngine.messagesAreRedundant(message, barGuidance.message));

  /// Show insight card only when there is a distinct message or food chips.
  bool get shouldShowInsightCard =>
      suggestions.isNotEmpty || hasDistinctCardMessage;
}

/// Rule-based coaching for the daily meal log — sync, no network.
class MealInsightEngine {
  static const _defaultMeals = [
    'صبحانه',
    'میان‌وعده 1',
    'ناهار',
    'میان‌وعده 2',
    'شام',
    'میان‌وعده 3',
  ];

  static MealInsightResult analyze({
    required List<FoodMealLog> meals,
    required List<Food> allFoods,
    required Map<String, dynamic>? profileData,
    required Map<DateTime, bool> loggedDates,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    if (!_isSameDay(now, DateTime.now())) {
      return _analyzeHistoricalDay(
        day: now,
        meals: meals,
        allFoods: allFoods,
        profileData: profileData,
      );
    }

    final totals = MealLogUtils.calculateTotals(meals, allFoods);
    final targets = MealNutritionTargets.fromProfile(profileData);
    final streak = computeStreak(loggedDates, anchor: now);

    final consumedCalories = totals['calories'] ?? 0;
    final consumedProtein = totals['protein'] ?? 0;
    final proteinGap = targets.proteinTarget - consumedProtein;
    final calorieGap = targets.calorieTarget - consumedCalories;
    final loggedFoodCount = _countLoggedFoods(meals);
    final nextMeal = suggestedMealForHour(now.hour);
    final nextMealLogged = _mealHasLoggedFood(meals, nextMeal);

    final barGuidance = _buildBarGuidance(
      targets: targets,
      consumedCalories: consumedCalories,
      consumedProtein: consumedProtein,
      proteinGap: proteinGap,
      calorieGap: calorieGap,
      loggedFoodCount: loggedFoodCount,
      nextMeal: nextMeal,
      nextMealLogged: nextMealLogged,
      referenceTime: now,
    );

    // امروز هنوز خالیه
    if (loggedFoodCount == 0) {
      final goalLabel = targets.goalAdjustmentLabel;
      final goalBadge = goalLabel != null ? ' ($goalLabel)' : '';
      final String msg;
      if (streak > 4) {
        msg = '🔥 $streak روز پشت سر هم ثبت کردی$goalBadge — رشته‌تو نشکن! $nextMeal رو الان بزن.';
      } else if (streak > 1) {
        msg = '💪 $streak روز متوالی — امروز هم بیا$goalBadge! $nextMeal رو ثبت کن.';
      } else if (now.hour >= 5 && now.hour < 12) {
        msg = '${_greeting(now.hour)}$goalBadge! صبحانه‌ات رو ثبت کن تا روز خوبی داشته باشی.';
      } else if (now.hour >= 12 && now.hour < 17) {
        msg = '${_greeting(now.hour)}$goalBadge! $nextMeal منتظرته — بیا ثبتش کن.';
      } else {
        msg = '${_greeting(now.hour)}$goalBadge! $nextMeal رو ثبت کن — هنوز وقت داری.';
      }
      return MealInsightResult(
        message: msg,
        tone: streak > 1 ? MealInsightTone.success : MealInsightTone.tip,
        barGuidance: barGuidance,
        streakDays: streak,
        highlightMealTitle: nextMeal,
        suggestions: _suggestFoods(
          allFoods: allFoods,
          meals: meals,
          preferProtein: true,
          mealTitle: nextMeal,
          limit: 3,
        ),
      );
    }

    // از مرجع گذشته
    if (consumedCalories > targets.calorieTarget * 1.08) {
      return MealInsightResult(
        message:
            'امروز یکم بیشتر از مرجع رفتی — اشکال نداره، فردا سبک‌تر جبران کن 💪',
        tone: MealInsightTone.warning,
        barGuidance: barGuidance,
        streakDays: streak,
      );
    }

    // کمبود پروتئین بعدازظهر
    if (proteinGap > 25 && now.hour >= 14) {
      final targetMeal = !nextMealLogged ? nextMeal : 'وعده بعدی';
      final suggestions = _suggestFoods(
        allFoods: allFoods,
        meals: meals,
        preferProtein: true,
        mealTitle: !nextMealLogged ? nextMeal : null,
        limit: 3,
      );
      return MealInsightResult(
        message:
            'پروتئین امروزت ${proteinGap.round()} گرم کمتره — برای $targetMeal یه گزینه پروتئینی بزن.',
        tone: MealInsightTone.info,
        barGuidance: barGuidance,
        streakDays: streak,
        highlightMealTitle: !nextMealLogged ? nextMeal : null,
        suggestions: suggestions,
      );
    }

    // وعده بعدی هنوز ثبت نشده
    if (!nextMealLogged && now.hour >= 7 && now.hour <= 22) {
      return MealInsightResult(
        message: '$nextMeal وقتشه ⏰ — چی میخوری؟ یه گزینه سریع انتخاب کن.',
        tone: MealInsightTone.tip,
        barGuidance: barGuidance,
        streakDays: streak,
        highlightMealTitle: nextMeal,
        suggestions: _suggestFoods(
          allFoods: allFoods,
          meals: meals,
          preferProtein: proteinGap > 10,
          mealTitle: nextMeal,
          limit: 3,
        ),
      );
    }

    // نزدیک مرجع و پروتئین هم خوب
    if (calorieGap > 0 &&
        calorieGap < targets.calorieTarget * 0.15 &&
        proteinGap <= 15) {
      return MealInsightResult(
        message: streak > 1
            ? '✨ $streak روز متوالی و امروز هم تقریباً کاملی — عالیه!'
            : '✨ نزدیک نیاز روزانه‌ات هستی — همین‌طور ادامه بده!',
        tone: MealInsightTone.success,
        barGuidance: barGuidance,
        streakDays: streak,
      );
    }

    // پروتئین خوب، هنوز کالری جا داره
    if (proteinGap <= 10 && calorieGap > targets.calorieTarget * 0.2) {
      return MealInsightResult(
        message:
            'پروتئین خوبه ✓ — ${calorieGap.round()} کالری دیگه میتونی بخوری.',
        tone: MealInsightTone.success,
        barGuidance: barGuidance,
        streakDays: streak,
      );
    }

    return MealInsightResult(
      message: streak > 2
          ? '🔥 $streak روز پشت سر هم — عادت داری شکل می‌گیره!'
          : 'هر وعده‌ای که ثبت می‌کنی یه قدم جلوتره — ادامه بده!',
      tone: MealInsightTone.info,
      barGuidance: barGuidance,
      streakDays: streak,
    );
  }

  static String _greeting(int hour) {
    if (hour >= 5 && hour < 12) return 'صبح بخیر';
    if (hour >= 12 && hour < 17) return 'ظهر بخیر';
    if (hour >= 17 && hour < 21) return 'عصر بخیر';
    return 'شب بخیر';
  }

  static MealInsightResult _analyzeHistoricalDay({
    required DateTime day,
    required List<FoodMealLog> meals,
    required List<Food> allFoods,
    required Map<String, dynamic>? profileData,
  }) {
    final totals = MealLogUtils.calculateTotals(meals, allFoods);
    final targets = MealNutritionTargets.fromProfile(profileData);
    final consumedCalories = totals['calories'] ?? 0;
    final consumedProtein = totals['protein'] ?? 0;
    final proteinGap = targets.proteinTarget - consumedProtein;
    final calorieGap = targets.calorieTarget - consumedCalories;
    final loggedFoodCount = _countLoggedFoods(meals);

    final barGuidance = _buildHistoricalBarGuidance(
      targets: targets,
      consumedCalories: consumedCalories,
      consumedProtein: consumedProtein,
      proteinGap: proteinGap,
      calorieGap: calorieGap,
      loggedFoodCount: loggedFoodCount,
      isFuture: _isFutureDay(day),
      dayLabel: _historicalDayLabel(day),
    );

    return MealInsightResult(
      message: '',
      tone: barGuidance.tone,
      barGuidance: barGuidance,
    );
  }

  static String _historicalDayLabel(DateTime day) {
    if (_isFutureDay(day)) return 'این روز';
    if (_isYesterday(day)) return 'دیروز';
    return MealLogUtils.getPersianFormattedDate(day);
  }

  static bool _isYesterday(DateTime day) {
    final target = _dateOnly(day);
    final yesterday = _dateOnly(DateTime.now().subtract(const Duration(days: 1)));
    return target == yesterday;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isFutureDay(DateTime day) {
    return _dateOnly(day).isAfter(_dateOnly(DateTime.now()));
  }

  /// True when card message repeats status facts already shown under the bar.
  static bool messagesAreRedundant(String card, String bar) {
    final c = card.trim();
    final b = bar.trim();
    if (c.isEmpty || b.isEmpty) return false;
    if (c == b) return true;

    const statusTokens = [
      'کالری مونده',
      'کالری تا',
      'گرم کمه',
      'گرم پروتئین',
      'پروتئین',
      '٪ مصرف',
      'نزدیک مرجع',
      'از مرجع',
      'مصرف شده',
    ];
    final cStatus = statusTokens.any(c.contains);
    final bStatus = statusTokens.any(b.contains);
    if (cStatus && bStatus) return true;

    return false;
  }

  /// Compact, contextual hint shown directly under the calorie progress bar.
  static MealCalorieBarGuidance buildBarGuidance({
    required List<FoodMealLog> meals,
    required List<Food> allFoods,
    required Map<String, dynamic>? profileData,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final totals = MealLogUtils.calculateTotals(meals, allFoods);
    final targets = MealNutritionTargets.fromProfile(profileData);
    final consumedCalories = totals['calories'] ?? 0;
    final consumedProtein = totals['protein'] ?? 0;
    final proteinGap = targets.proteinTarget - consumedProtein;
    final calorieGap = targets.calorieTarget - consumedCalories;
    final loggedFoodCount = _countLoggedFoods(meals);

    if (!_isSameDay(now, DateTime.now())) {
      return _buildHistoricalBarGuidance(
        targets: targets,
        consumedCalories: consumedCalories,
        consumedProtein: consumedProtein,
        proteinGap: proteinGap,
        calorieGap: calorieGap,
        loggedFoodCount: loggedFoodCount,
        isFuture: _isFutureDay(now),
        dayLabel: _historicalDayLabel(now),
      );
    }

    final nextMeal = suggestedMealForHour(now.hour);
    final nextMealLogged = _mealHasLoggedFood(meals, nextMeal);

    return _buildBarGuidance(
      targets: targets,
      consumedCalories: consumedCalories,
      consumedProtein: consumedProtein,
      proteinGap: proteinGap,
      calorieGap: calorieGap,
      loggedFoodCount: loggedFoodCount,
      nextMeal: nextMeal,
      nextMealLogged: nextMealLogged,
      referenceTime: now,
    );
  }

  static MealCalorieBarGuidance _buildBarGuidance({
    required MealNutritionTargets targets,
    required double consumedCalories,
    required double consumedProtein,
    required double proteinGap,
    required double calorieGap,
    required int loggedFoodCount,
    required String nextMeal,
    required bool nextMealLogged,
    required DateTime referenceTime,
  }) {
    final ref = targets.calorieTarget.round();
    final referenceWord =
        targets.goalAdjustmentLabel != null ? 'برآورد روزانه' : 'نیاز روزانه';

    if (loggedFoodCount == 0) {
      return MealCalorieBarGuidance(
        message: '$referenceWord شما $ref کالریه — با $nextMeal شروع کن.',
        tone: MealInsightTone.tip,
      );
    }

    if (calorieGap < 0) {
      final over = (-calorieGap).round();
      return MealCalorieBarGuidance(
        message: '+$over کالری از مرجع — وعده بعدی رو سبک بگیر.',
        tone: MealInsightTone.warning,
      );
    }

    if (proteinGap > 25 && referenceTime.hour >= 14) {
      final targetMeal = !nextMealLogged ? nextMeal : 'وعده بعدی';
      return MealCalorieBarGuidance(
        message: 'پروتئین ${proteinGap.round()} گرم کمه — $targetMeal پروتئینی بزن.',
        tone: MealInsightTone.info,
      );
    }

    final progress = targets.calorieTarget > 0
        ? consumedCalories / targets.calorieTarget
        : 0.0;

    if (progress >= 0.85 && calorieGap > 0) {
      return MealCalorieBarGuidance(
        message: 'نزدیک مرجع — فقط ${calorieGap.round()} کالری مونده ✓',
        tone: MealInsightTone.success,
      );
    }

    if (progress >= 0.5 && calorieGap > 0) {
      return MealCalorieBarGuidance(
        message:
            '${calorieGap.round()} کالری مونده | ${consumedProtein.round()} گرم پروتئین تا الان',
        tone: MealInsightTone.info,
      );
    }

    if (!nextMealLogged &&
        referenceTime.hour >= 7 &&
        referenceTime.hour <= 22) {
      return MealCalorieBarGuidance(
        message: '$nextMeal هنوز ثبت نشده — ${calorieGap.round()} کالری مونده.',
        tone: MealInsightTone.tip,
      );
    }

    if (calorieGap > targets.calorieTarget * 0.35) {
      return MealCalorieBarGuidance(
        message:
            '${(progress * 100).round()}٪ مصرف — ${calorieGap.round()} کالری تا $referenceWord.',
        tone: MealInsightTone.info,
      );
    }

    return MealCalorieBarGuidance(
      message: '${calorieGap.round()} کالری تا $referenceWord.',
      tone: MealInsightTone.info,
    );
  }

  static MealCalorieBarGuidance _buildHistoricalBarGuidance({
    required MealNutritionTargets targets,
    required double consumedCalories,
    required double consumedProtein,
    required double proteinGap,
    required double calorieGap,
    required int loggedFoodCount,
    required bool isFuture,
    required String dayLabel,
  }) {
    final referenceWord =
        targets.goalAdjustmentLabel != null ? 'برآورد روزانه' : 'نیاز روزانه';
    final progress = targets.calorieTarget > 0
        ? consumedCalories / targets.calorieTarget
        : 0.0;
    final pct = (progress * 100).round();

    if (loggedFoodCount == 0) {
      if (isFuture) {
        return MealCalorieBarGuidance(
          message: 'برای $dayLabel هنوز چیزی ثبت نشده.',
          tone: MealInsightTone.tip,
        );
      }
      return MealCalorieBarGuidance(
        message:
            '$dayLabel ثبت نشده — اگه چیزی خورده بودی می‌تونی الان اضافه کنی.',
        tone: MealInsightTone.info,
      );
    }

    if (calorieGap < 0) {
      final over = (-calorieGap).round();
      return MealCalorieBarGuidance(
        message:
            '$dayLabel: ${consumedCalories.round()} کالری (+$over از مرجع) — $pct٪',
        tone: MealInsightTone.warning,
      );
    }

    if (progress >= 0.85 && proteinGap <= 15) {
      return MealCalorieBarGuidance(
        message:
            '$dayLabel: ${consumedCalories.round()} کالری — $pct٪ از $referenceWord ✓',
        tone: MealInsightTone.success,
      );
    }

    if (proteinGap > 25) {
      return MealCalorieBarGuidance(
        message:
            '$dayLabel: $pct٪ مصرف — پروتئین ${proteinGap.round()} گرم کمتر از برآورد',
        tone: MealInsightTone.info,
      );
    }

    return MealCalorieBarGuidance(
      message:
          '$dayLabel: ${consumedCalories.round()} کالری — $pct٪ از $referenceWord',
      tone: MealInsightTone.info,
    );
  }

  static String suggestedMealForHour(int hour) {
    if (hour >= 5 && hour < 10) return 'صبحانه';
    if (hour >= 10 && hour < 12) return 'میان‌وعده 1';
    if (hour >= 12 && hour < 15) return 'ناهار';
    if (hour >= 15 && hour < 17) return 'میان‌وعده 2';
    if (hour >= 17 && hour < 21) return 'شام';
    if (hour >= 21) return 'میان‌وعده 3';
    return 'صبحانه';
  }

  static int computeStreak(
    Map<DateTime, bool> loggedDates, {
    DateTime? anchor,
  }) {
    if (loggedDates.isEmpty) return 0;

    var cursor = _dateOnly(anchor ?? DateTime.now());
    if (!_hasLogOnDate(loggedDates, cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (_hasLogOnDate(loggedDates, cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static List<MealFoodSuggestion> _suggestFoods({
    required List<Food> allFoods,
    required List<FoodMealLog> meals,
    required bool preferProtein,
    required String? mealTitle,
    required int limit,
  }) {
    if (allFoods.isEmpty) return const [];

    final loggedIds = {
      for (final meal in meals)
        for (final item in meal.foods)
          if (item.amount > 0) item.foodId,
    };

    final candidates = allFoods.where((food) {
      if (loggedIds.contains(food.id)) return false;
      if (mealTitle != null && food.meta.mealTimes.isNotEmpty) {
        return food.meta.mealTimes.any(
          (t) => mealTitle.contains(t) || t.contains(mealTitle.split(' ').first),
        );
      }
      return true;
    }).toList();

    if (candidates.isEmpty) {
      candidates.addAll(
        allFoods.where((f) => !loggedIds.contains(f.id)).take(limit * 4),
      );
    }

    candidates.sort((a, b) {
      if (preferProtein) {
        return _proteinPer100(b).compareTo(_proteinPer100(a));
      }
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return b.likes.compareTo(a.likes);
    });

    return candidates.take(limit).map((food) {
      return MealFoodSuggestion(
        foodId: food.id,
        label: food.displayTitle,
        mealTitle: mealTitle,
        amount: 100,
        unit: 'گرم',
      );
    }).toList();
  }

  static double _proteinPer100(Food food) =>
      double.tryParse(food.nutrition.protein.replaceAll(',', '.')) ?? 0;

  static int _countLoggedFoods(List<FoodMealLog> meals) {
    var count = 0;
    for (final meal in meals) {
      for (final item in meal.foods) {
        if (item.amount > 0) count++;
      }
    }
    return count;
  }

  static bool _mealHasLoggedFood(List<FoodMealLog> meals, String title) {
    for (final meal in meals) {
      if (meal.title != title) continue;
      return meal.foods.any((item) => item.amount > 0);
    }
    return false;
  }

  static bool _hasLogOnDate(Map<DateTime, bool> dates, DateTime day) {
    final target = _dateOnly(day);
    for (final entry in dates.entries) {
      if (entry.value != true) continue;
      final key = _dateOnly(entry.key);
      if (key == target) return true;
    }
    return false;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isStandardMealTitle(String title) =>
      _defaultMeals.contains(title) ||
      title.startsWith('میان‌وعده');
}
