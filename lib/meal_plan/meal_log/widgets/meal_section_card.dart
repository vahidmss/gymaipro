import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_plan/meal_log/models/food_log_item.dart';
import 'package:gymaipro/models/food.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MealSectionCard extends StatelessWidget {
  const MealSectionCard({
    required this.title,
    required this.icon,
    required this.foods,
    required this.allFoods,
    required this.onAddFood,
    required this.onEditAmount,
    required this.onFoodAction,
    required this.onRemoveFood,
    super.key,
  });
  final String title;
  final IconData icon;
  final List<FoodLogItem> foods;
  final List<Food> allFoods;
  final VoidCallback onAddFood;
  final void Function(FoodLogItem, String) onEditAmount;
  final void Function(String, FoodLogItem, String) onFoodAction;
  final void Function(FoodLogItem, String) onRemoveFood;

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
          ...foods.map(_buildFoodItem),
        ],
      ),
    );
  }

  Widget _buildFoodItem(FoodLogItem foodItem) {
    final food = allFoods.firstWhere(
      (f) => f.id == foodItem.foodId,
      orElse: () => _createDefaultFood(foodItem.foodId),
    );

    final isFromPlan = foodItem.mealPlanId != null;
    final isManuallyAdded = !isFromPlan;

    final plannedAmount = isFromPlan
        ? (foodItem.plannedAmount ?? foodItem.amount)
        : foodItem.amount;
    final consumedAmount = foodItem.amount;

    final completionPercentage = isManuallyAdded
        ? 1.0
        : (plannedAmount > 0
              ? (consumedAmount / plannedAmount).clamp(0.0, 2.0)
              : 0.0);

    final isCompleted = isManuallyAdded
        ? true
        : (foodItem.followedPlan == true ||
              (plannedAmount > 0 &&
                  (consumedAmount - plannedAmount).abs() < 0.01));
    final isOverConsumed = completionPercentage > 1.05;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFD4AF37).withValues(alpha: 0.35)
              : isOverConsumed
              ? Colors.orange.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.10),
          width: 1.2.w,
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
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    food.imageUrl,
                    width: 40.w,
                    height: 40.h,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8.r),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isFromPlan)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.15)
                                  : isOverConsumed
                                  ? Colors.orange.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: isCompleted
                                    ? const Color(0xFFD4AF37)
                                    : isOverConsumed
                                    ? Colors.orange
                                    : Colors.white.withValues(alpha: 0.15),
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Icon(
                              isCompleted
                                  ? LucideIcons.check
                                  : isOverConsumed
                                  ? LucideIcons.trendingUp
                                  : LucideIcons.circle,
                              color: isCompleted
                                  ? const Color(0xFFD4AF37)
                                  : isOverConsumed
                                  ? Colors.orange
                                  : Colors.white70,
                              size: 14.sp,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isFromPlan) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3.r),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: completionPercentage.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => onEditAmount(foodItem, title),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: const Color(
                                  0xFFD4AF37,
                                ).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${consumedAmount.toStringAsFixed(0)}g',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isFromPlan &&
                                    plannedAmount != consumedAmount) ...[
                                  Text(
                                    ' / ${plannedAmount.toStringAsFixed(0)}g',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          color: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('ویرایش مقدار'),
                            ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text('حذف'),
                            ),
                          ],
                          onSelected: (v) => onFoodAction(title, foodItem, v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
