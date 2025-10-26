import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_plan/meal_log/models/food_log_item.dart';
import 'package:gymaipro/models/food.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FoodItemCard extends StatelessWidget {
  const FoodItemCard({
    required this.foodItem,
    required this.mealTitle,
    required this.food,
    required this.onEditAmount,
    required this.onAction,
    super.key,
  });
  final FoodLogItem foodItem;
  final String mealTitle;
  final Food food;
  final VoidCallback onEditAmount;
  final void Function(String, FoodLogItem, String) onAction;

  @override
  Widget build(BuildContext context) {
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
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            if (isCompleted)
              Colors.green[900]!.withValues(alpha: 0.1)
            else
              isOverConsumed
                  ? Colors.orange[900]!.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
            if (isCompleted)
              Colors.green[800]!.withValues(alpha: 0.05)
            else
              isOverConsumed
                  ? Colors.orange[800]!.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isCompleted
              ? Colors.green[700]!.withValues(alpha: 0.3)
              : isOverConsumed
              ? Colors.orange[700]!.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
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
                        // Completion status icon (only for plan foods)
                        if (isFromPlan)
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green[700]
                                  : isOverConsumed
                                  ? Colors.orange[700]
                                  : Colors.grey[600],
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check
                                  : isOverConsumed
                                  ? Icons.trending_up
                                  : Icons.radio_button_unchecked,
                              color: Colors.white,
                              size: 12.sp,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // برنامه/آزاد تگ
                    Row(
                      children: [
                        if (isFromPlan)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[900]?.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'برنامه',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isManuallyAdded)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber[900]?.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'آزاد',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Progress bar (only for plan foods)
                    if (isFromPlan) ...[
                      Container(
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(2.r),
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
                              borderRadius: BorderRadius.circular(2.r),
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
                          onTap: onEditAmount,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[700]?.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.amber[700]!.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${consumedAmount.toStringAsFixed(0)}g',
                                  style: TextStyle(
                                    color: Colors.amber[200],
                                    fontSize: 12.sp,
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
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 10.sp,
                                  color: Colors.amber[300],
                                ),
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
                              fontSize: 11.sp,
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
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[400],
                                size: 16.sp,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'تکمیل شده',
                                style: TextStyle(color: Colors.green[400]),
                              ),
                            ],
                          ),
                        ),
                        if (foodItem.alternatives != null &&
                            foodItem.alternatives!.isNotEmpty)
                          PopupMenuItem(
                            value: 'substitute',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.swap_horiz,
                                  color: Colors.blue[400],
                                  size: 16.sp,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'جایگزین کردن',
                                  style: TextStyle(color: Colors.blue[400]),
                                ),
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
                              Icon(
                                Icons.delete,
                                color: Colors.red[400],
                                size: 16.sp,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'حذف',
                                style: TextStyle(color: Colors.red[400]),
                              ),
                            ],
                          ),
                        ),
                      ],
                onSelected: (value) => onAction(value, foodItem, mealTitle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
