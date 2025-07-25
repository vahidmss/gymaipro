import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/food_log_item.dart';
import '../../../models/food.dart';
import '../utils/meal_log_utils.dart';
import 'food_item_card.dart';

class MealSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<FoodLogItem> foodItems;
  final List<Food> allFoods;
  final VoidCallback onAddFood;
  final Function(FoodLogItem, String) onEditAmount;
  final Function(String, FoodLogItem, String) onFoodAction;

  const MealSection({
    super.key,
    required this.title,
    required this.icon,
    required this.foodItems,
    required this.allFoods,
    required this.onAddFood,
    required this.onEditAmount,
    required this.onFoodAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1810),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[700]?.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.amber[700], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.amber[200],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.plus, color: Colors.amber),
                  onPressed: onAddFood,
                ),
              ],
            ),
          ),
          // Food items
          ...foodItems.map((foodItem) {
            final food = allFoods.firstWhere(
              (f) => f.id == foodItem.foodId,
              orElse: () => MealLogUtils.createDefaultFood(foodItem.foodId),
            );
            return FoodItemCard(
              foodItem: foodItem,
              mealTitle: title,
              food: food,
              onEditAmount: () => onEditAmount(foodItem, title),
              onAction: onFoodAction,
            );
          }).toList(),
        ],
      ),
    );
  }
}
