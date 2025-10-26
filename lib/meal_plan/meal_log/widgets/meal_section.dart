import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_plan/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_plan/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_plan/meal_log/widgets/food_item_card.dart';
import 'package:gymaipro/models/food.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MealSection extends StatelessWidget {
  const MealSection({
    required this.title,
    required this.icon,
    required this.foodItems,
    required this.allFoods,
    required this.onAddFood,
    required this.onEditAmount,
    required this.onFoodAction,
    super.key,
  });
  final String title;
  final IconData icon;
  final List<FoodLogItem> foodItems;
  final List<Food> allFoods;
  final VoidCallback onAddFood;
  final void Function(FoodLogItem, String) onEditAmount;
  final void Function(String, FoodLogItem, String) onFoodAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.22),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14.r,
            offset: Offset(0.w, 6.h),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.06),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(icon, color: const Color(0xFFD4AF37), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.plus,
                      color: const Color(0xFFD4AF37),
                      size: 18.sp,
                    ),
                    tooltip: 'افزودن غذا',
                    onPressed: onAddFood,
                  ),
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
          }),
        ],
      ),
    );
  }
}
