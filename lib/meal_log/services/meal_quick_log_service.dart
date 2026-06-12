import 'package:gymaipro/meal_log/models/meal_quick_log_entry.dart';
import 'package:gymaipro/meal_log/services/meal_log_service.dart';

/// Reads recent foods from **local** logs only — fast, no network.
class MealQuickLogService {
  MealQuickLogService({MealLogService? mealLogService})
    : _mealLogService = mealLogService ?? MealLogService();

  final MealLogService _mealLogService;

  Future<List<MealQuickLogEntry>> getRecentEntries({
    int limit = 5,
    int dayLookback = 14,
  }) async {
    if (limit <= 0) return const [];

    final dates = await _mealLogService.listLocalLogDates();
    if (dates.isEmpty) return const [];

    dates.sort((a, b) => b.compareTo(a));
    final cutoff = DateTime.now().subtract(Duration(days: dayLookback));

    final entries = <MealQuickLogEntry>[];
    final seenFoodIds = <int>{};

    for (final date in dates) {
      if (date.isBefore(cutoff)) break;

      final log = await _mealLogService.loadLogLocal(date);
      if (log == null) continue;

      for (final meal in log.meals.reversed) {
        for (final item in meal.foods.reversed) {
          if (item.amount <= 0) continue;
          if (seenFoodIds.contains(item.foodId)) continue;

          seenFoodIds.add(item.foodId);
          entries.add(
            MealQuickLogEntry(
              foodId: item.foodId,
              amount: item.amount,
              unit: item.unit,
              mealTitle: meal.title,
              lastUsed: date,
            ),
          );
          if (entries.length >= limit) return entries;
        }
      }
    }

    return entries;
  }
}
