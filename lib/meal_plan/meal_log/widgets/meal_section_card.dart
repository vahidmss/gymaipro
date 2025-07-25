import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../models/food_log.dart';
import '../../../models/food.dart';

class MealSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<FoodLogItem> foods;
  final List<Food> allFoods;
  final VoidCallback onAddFood;
  final Function(FoodLogItem, String) onEditAmount;
  final Function(String, FoodLogItem, String) onFoodAction;
  final Function(FoodLogItem, String) onRemoveFood;

  const MealSectionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.foods,
    required this.allFoods,
    required this.onAddFood,
    required this.onEditAmount,
    required this.onFoodAction,
    required this.onRemoveFood,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1810),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                    color: Colors.amber[700]?.withOpacity(0.2),
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
          ...foods.map((foodItem) => _buildFoodItem(foodItem)).toList(),
        ],
      ),
    );
  }

  Widget _buildFoodItem(FoodLogItem foodItem) {
    final food = allFoods.firstWhere(
      (f) => f.id == foodItem.foodId,
      orElse: () => _createDefaultFood(foodItem.foodId),
    );

    // Check if this food is from a meal plan
    final isFromPlan = foodItem.mealPlanId != null;
    final isManuallyAdded = !isFromPlan;

    // Calculate completion percentage
    final plannedAmount = isFromPlan
        ? (foodItem.plannedAmount ?? foodItem.amount)
        : foodItem.amount;
    final consumedAmount = foodItem.amount;

    // For manually added foods, always show as completed (no tracking needed)
    final completionPercentage = isManuallyAdded
        ? 1.0
        : (plannedAmount > 0
            ? (consumedAmount / plannedAmount).clamp(0.0, 2.0)
            : 0.0);

    // For plan foods, show as completed if followedPlan==true OR consumed==planned
    final isCompleted = isManuallyAdded
        ? true
        : (foodItem.followedPlan == true ||
            (plannedAmount > 0 &&
                (consumedAmount - plannedAmount).abs() < 0.01));
    final isOverConsumed = completionPercentage > 1.05;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isCompleted
                ? Colors.green[900]!.withOpacity(0.1)
                : isOverConsumed
                    ? Colors.orange[900]!.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
            isCompleted
                ? Colors.green[800]!.withOpacity(0.05)
                : isOverConsumed
                    ? Colors.orange[800]!.withOpacity(0.05)
                    : Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted
              ? Colors.green[700]!.withOpacity(0.3)
              : isOverConsumed
                  ? Colors.orange[700]!.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
          width: isCompleted || isOverConsumed ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Food image
              if (food.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    food.imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.image, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              // Food info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            food.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Completion status icon (only for plan foods)
                        if (isFromPlan)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green[700]
                                  : isOverConsumed
                                      ? Colors.orange[700]
                                      : Colors.grey[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check
                                  : isOverConsumed
                                      ? Icons.trending_up
                                      : Icons.radio_button_unchecked,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress bar (only for plan foods)
                    if (isFromPlan) ...[
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: completionPercentage.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green[500]
                                  : isOverConsumed
                                      ? Colors.orange[500]
                                      : Colors.amber[500],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Amount info with edit button
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => onEditAmount(foodItem, title),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber[700]?.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.amber[700]!.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${consumedAmount.toStringAsFixed(0)}g',
                                  style: TextStyle(
                                    color: Colors.amber[200],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Show planned amount only for plan foods
                                if (isFromPlan &&
                                    plannedAmount != consumedAmount) ...[
                                  Text(
                                    ' / ${plannedAmount.toStringAsFixed(0)}g',
                                    style: TextStyle(
                                      color: Colors.amber[300],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 4),
                                Icon(Icons.edit,
                                    size: 10, color: Colors.amber[300]),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Show percentage only for plan foods
                        if (isFromPlan)
                          Text(
                            '${(completionPercentage * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: isCompleted
                                  ? Colors.green[400]
                                  : isOverConsumed
                                      ? Colors.orange[400]
                                      : Colors.grey[400],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions - different menus for plan vs manual foods
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                color: const Color(0xFF2C1810),
                itemBuilder: (context) => isFromPlan
                    ? [
                        // Plan food actions
                        PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green[400], size: 16),
                              const SizedBox(width: 8),
                              Text('تکمیل شده',
                                  style: TextStyle(color: Colors.green[400])),
                            ],
                          ),
                        ),
                        if ((foodItem.alternatives != null &&
                            foodItem.alternatives!.isNotEmpty))
                          PopupMenuItem(
                            value: 'substitute',
                            child: Row(
                              children: [
                                Icon(Icons.swap_horiz,
                                    color: Colors.blue[400], size: 16),
                                const SizedBox(width: 8),
                                Text('جایگزین کردن',
                                    style: TextStyle(color: Colors.blue[400])),
                              ],
                            ),
                          ),
                      ]
                    : [
                        // Manual food actions (simple)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete,
                                  color: Colors.red[400], size: 16),
                              const SizedBox(width: 8),
                              Text('حذف',
                                  style: TextStyle(color: Colors.red[400])),
                            ],
                          ),
                        ),
                      ],
                onSelected: (value) => onFoodAction(value, foodItem, title),
              ),
            ],
          ),
          // Show alternatives if present
          if (foodItem.alternatives != null &&
              foodItem.alternatives!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                children: foodItem.alternatives!.map((alt) {
                  final altId = alt['food_id'] as int;
                  final altFood = allFoods.firstWhere(
                    (f) => f.id == altId,
                    orElse: () => _createDefaultFood(altId),
                  );
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber[700]?.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.amber[700]!.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (altFood.imageUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              altFood.imageUrl,
                              width: 16,
                              height: 16,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          altFood.title,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${alt['amount'].toString()}g',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to create default Food object
  Food _createDefaultFood(int id) {
    return Food(
      id: id,
      title: 'نامشخص',
      content: '',
      imageUrl: '',
      slug: '',
      date: DateTime.now(),
      modified: DateTime.now(),
      status: '',
      type: '',
      link: '',
      featuredMedia: 0,
      nutrition: FoodNutrition(
        protein: '0',
        calories: '0',
        carbohydrates: '0',
        fat: '0',
        saturatedFat: '0',
        fiber: '0',
        sugar: '0',
        cholesterol: '0',
        sodium: '0',
        potassium: '0',
      ),
      foodCategories: [],
      classList: [],
    );
  }
}
