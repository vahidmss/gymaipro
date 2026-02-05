import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/widgets/food_item_card.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/theme/app_theme.dart';
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
    this.dailyCalorieTarget,
    this.note,
    super.key,
  });
  final String title;
  final IconData icon;
  final List<FoodLogItem> foodItems;
  final List<Food> allFoods;
  final VoidCallback onAddFood;
  final void Function(FoodLogItem, String) onEditAmount;
  final void Function(String, FoodLogItem, String) onFoodAction;
  final double? dailyCalorieTarget;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        // استفاده از MediaQuery برای اندازه واقعی صفحه
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        // محاسبه responsive margin بر اساس اندازه واقعی
        final verticalMargin = screenWidth > 600 ? 12.0 : 8.0;
        final containerMargin = EdgeInsets.symmetric(
          horizontal: 0,
          vertical: verticalMargin,
        );
        
        // محاسبه responsive border radius بر اساس اندازه واقعی
        final borderRadius = screenWidth > 600 ? 24.0 : 20.0;
        
        // محاسبه responsive padding بر اساس اندازه واقعی
        final horizontalPadding = screenWidth > 600 ? 18.0 : 14.0;
        final topPadding = screenWidth > 600 ? 18.0 : 14.0;
        final bottomPadding = screenWidth > 600 ? 12.0 : 10.0;
        final headerPadding = EdgeInsets.fromLTRB(
          horizontalPadding,
          topPadding,
          horizontalPadding,
          bottomPadding,
        );
        
        return Container(
          margin: containerMargin,
          decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.goldGradientColors[0].withValues(alpha: 0.15),
                  context.cardColor,
                  context.goldGradientColors[1].withValues(alpha: 0.1),
                ],
              ),
        color: isDark ? context.backgroundColor : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.35),
            blurRadius: 16.r,
            offset: Offset(0.w, 6.h),
            spreadRadius: 1.r,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : AppTheme.lightTextColor.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: headerPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // خط اول: آیکون + اسم وعده + مقدار کالری
                Row(
                  children: [
                    Image.asset(
                      MealLogUtils.getMealImageAsset(title),
                      width: 28.w,
                      height: 28.w,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        icon,
                        color: isDark ? AppTheme.goldColor : context.textColor,
                        size: 28.sp,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _getCalorieRangeText(),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.8)
                              : context.textColor.withValues(alpha: 0.7),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                // حائل خطی
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
                        : AppTheme.lightDividerColor.withValues(alpha: 0.5),
                  ),
                ),
                // خط دوم: + افزودن صبحانه
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        LucideIcons.plus,
                        color: isDark ? AppTheme.goldColor : context.textColor,
                        size: 18.sp,
                      ),
                      tooltip: 'افزودن ${title}',
                      onPressed: onAddFood,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    Text(
                      'افزودن ${title}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.8)
                            : context.textColor.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // یادداشت وعده (اگر وجود داشته باشد)
          if (note != null && note!.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.1 : 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.3 : 0.4,
                    ),
                    width: 1.5.w,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.messageCircle,
                      color: AppTheme.goldColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        note!,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.9)
                              : context.textColor,
                          fontSize: 13.sp,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
          // Total calories for this meal
          if (foodItems.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
                    : AppTheme.lightDividerColor.withValues(alpha: 0.5),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مجموع کالری',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark
                          ? AppTheme.goldColor.withValues(alpha: 0.8)
                          : context.textColor.withValues(alpha: 0.7),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    MealLogUtils.convertToPersianNumbers(
                      '${_calculateMealTotalCalories().toStringAsFixed(0)} کالری',
                    ),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark ? AppTheme.goldColor : context.textColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
        );
      },
    );
  }

  double _calculateMealTotalCalories() {
    double total = 0;
    for (final foodItem in foodItems) {
      final food = allFoods.firstWhere(
        (f) => f.id == foodItem.foodId,
        orElse: () => MealLogUtils.createDefaultFood(foodItem.foodId),
      );
      if (food.id != 0) {
        final ratio = foodItem.amount / 100.0;
        total += (double.tryParse(food.nutrition.calories) ?? 0) * ratio;
      }
    }
    return total;
  }

  String _getCalorieRangeText() {
    final range = MealLogUtils.getRecommendedCalorieRange(
      title,
      dailyCalorieTarget,
    );
    return '${range['min']} تا ${range['max']} کالری';
  }
}
