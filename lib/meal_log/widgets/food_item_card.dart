import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/theme/app_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Check if this food is from a meal plan
    final isFromPlan = foodItem.mealPlanId != null;
    final isManuallyAdded = !isFromPlan;

    final consumedAmount = foodItem.amount;

    // Calculate calories
    final ratio = consumedAmount / 100.0;
    final calories = (double.tryParse(food.nutrition.calories) ?? 0) * ratio;

    return LayoutBuilder(
      builder: (context, constraints) {
        // استفاده از MediaQuery برای اندازه واقعی صفحه
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        // محاسبه responsive margin و padding بر اساس اندازه واقعی
        final horizontalMargin = screenWidth > 600
            ? (screenWidth * 0.04).clamp(16.0, 24.0)
            : (screenWidth * 0.043).clamp(12.0, 20.0);
        final verticalMargin = screenWidth > 600 ? 4.0 : 2.0;
        final containerMargin = EdgeInsets.symmetric(
          horizontal: horizontalMargin,
          vertical: verticalMargin,
        );
        
        final horizontalPadding = screenWidth > 600 ? 16.0 : 12.0;
        final verticalPadding = screenWidth > 600 ? 12.0 : 8.0;
        final containerPadding = EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        );
        
        return Container(
          margin: containerMargin,
          padding: containerPadding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Food name | Calories
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        food.title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      MealLogUtils.convertToPersianNumbers(
                        '${calories.toStringAsFixed(0)} کالری',
                      ),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                // Row 2: آزاد/برنامه | Amount + Unit (editable)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // آزاد/برنامه تگ
                    isManuallyAdded
                        ? Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.goldColor.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'آزاد',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? AppTheme.goldColor.withValues(alpha: 0.8)
                                    : Colors.black,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ColorFiltered(
                                colorFilter: isDark
                                    ? ColorFilter.mode(
                                        Colors.blue[400]!,
                                        BlendMode.srcIn,
                                      )
                                    : const ColorFilter.mode(
                                        Colors.transparent,
                                        BlendMode.dst,
                                      ),
                                child: Image.asset(
                                  'images/program.png',
                                  width: 14.w,
                                  height: 14.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'برنامه',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: isDark
                                      ? Colors.blue[400]
                                      : Colors.blue[600],
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                    // Amount + Unit (editable)
                    GestureDetector(
                      onTap: onEditAmount,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            MealLogUtils.convertToPersianNumbers(
                              foodItem.plannedAmount != null
                                  ? '${consumedAmount.toStringAsFixed(0)}/${foodItem.plannedAmount!.toStringAsFixed(0)} ${foodItem.unit}'
                                  : '${consumedAmount.toStringAsFixed(0)} ${foodItem.unit}',
                            ),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isDark ? AppTheme.goldColor : Colors.black,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            foodItem.plannedAmount != null
                                ? LucideIcons.plus
                                : LucideIcons.edit2,
                            size: 11.sp,
                            color: isDark
                                ? AppTheme.goldColor.withValues(alpha: 0.7)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: context.textColor.withValues(alpha: 0.4),
              size: 16.sp,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            color: isDark ? context.backgroundColor : context.cardColor,
            itemBuilder: (context) => isFromPlan
                ? [
                    PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[400],
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'تکمیل شده',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Colors.green[400],
                              fontSize: 12.sp,
                            ),
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
                              size: 14.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'جایگزین کردن',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: Colors.blue[400],
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ]
                : [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            color: Colors.red[400],
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'حذف',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Colors.red[400],
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
            onSelected: (value) => onAction(value, foodItem, mealTitle),
          ),
        ],
      ),
        );
      },
    );
  }
}
