import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/widgets/food_item_card.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final hasFoods = foodItems.isNotEmpty;
    final totalCalories = _calculateMealTotalCalories();
    final macros = _calculateMealMacros();
    final range = MealLogUtils.getRecommendedCalorieRange(
      title,
      dailyCalorieTarget,
    );
    final maxCalories = (range['max'] ?? 500).toDouble();
    final progress = maxCalories > 0
        ? (totalCalories / maxCalories).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? context.backgroundColor : context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasFoods
              ? AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.5)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
          width: hasFoods ? 1.2 : 0.8,
        ),
        boxShadow: [
          if (hasFoods)
            BoxShadow(
              color: AppTheme.goldColor.withValues(
                alpha: isDark ? 0.08 : 0.12,
              ),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
            child: Row(
              children: [
                // Meal icon
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.15 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Image.asset(
                      MealLogUtils.getMealImageAsset(title),
                      width: 20.w,
                      height: 20.w,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        icon,
                        color: AppTheme.goldColor,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                // Title + calorie text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? Colors.white
                              : context.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          if (hasFoods) ...[
                            Text(
                              MealLogUtils.convertToPersianNumbers(
                                '${totalCalories.toStringAsFixed(0)}',
                              ),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? AppTheme.goldColor.withValues(alpha: 0.9)
                                    : AppTheme.darkGold,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              MealLogUtils.convertToPersianNumbers(
                                ' / ${range['min']}~${range['max']} کالری',
                              ),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : context.textColor.withValues(alpha: 0.35),
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ] else ...[
                            Text(
                              MealLogUtils.convertToPersianNumbers(
                                '${range['min']} ~ ${range['max']} کالری',
                              ),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : context.textColor.withValues(alpha: 0.35),
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                          SizedBox(width: 4.w),
                          Icon(
                            LucideIcons.info,
                            size: 9.sp,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : context.textColor.withValues(alpha: 0.2),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'تقریبی',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : context.textColor.withValues(alpha: 0.2),
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Add button
                _buildAddButton(isDark, context),
              ],
            ),
          ),

          // ── Progress bar (only when foods exist) ──
          if (hasFoods) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
              child: _buildCalorieProgress(isDark, progress, context),
            ),
          ],

          // ── Macro summary (only when foods exist) ──
          if (hasFoods) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 4.h),
              child: _buildMacroSummary(isDark, macros, context),
            ),
          ],

          // ── Empty state hint ──
          if (!hasFoods)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 10.h),
              child: Text(
                'برای ثبت غذا روی + بزنید',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : context.textColor.withValues(alpha: 0.3),
                  fontSize: 10.sp,
                ),
              ),
            ),

          // ── Note ──
          if (note != null && note!.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.08 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.messageCircle,
                      color: AppTheme.goldColor.withValues(alpha: 0.7),
                      size: 13.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        note!,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.8)
                              : context.textColor.withValues(alpha: 0.7),
                          fontSize: 11.sp,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Food items ──
          if (hasFoods) ...[
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Column(
                children: foodItems.map((foodItem) {
                  final food = allFoods.firstWhere(
                    (f) => f.id == foodItem.foodId,
                    orElse: () =>
                        MealLogUtils.createDefaultFood(foodItem.foodId),
                  );
                  return FoodItemCard(
                    foodItem: foodItem,
                    mealTitle: title,
                    food: food,
                    onEditAmount: () => onEditAmount(foodItem, title),
                    onAction: onFoodAction,
                  );
                }).toList(),
              ),
            ),
            // ── Footer: total ──
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مجموع',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : context.textColor.withValues(alpha: 0.4),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    MealLogUtils.convertToPersianNumbers(
                      '${totalCalories.toStringAsFixed(0)} کالری',
                    ),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark
                          ? AppTheme.goldColor
                          : context.textColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Add Button ──
  Widget _buildAddButton(bool isDark, BuildContext context) {
    return GestureDetector(
      onTap: onAddFood,
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          color: AppTheme.goldColor.withValues(
            alpha: isDark ? 0.15 : 0.12,
          ),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(
              alpha: isDark ? 0.3 : 0.25,
            ),
            width: 1,
          ),
        ),
        child: Icon(
          LucideIcons.plus,
          color: AppTheme.goldColor,
          size: 16.sp,
        ),
      ),
    );
  }

  // ── Calorie Progress Bar ──
  Widget _buildCalorieProgress(
    bool isDark,
    double progress,
    BuildContext context,
  ) {
    final isOver = progress >= 1.0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.r),
        child: SizedBox(
          height: 3.h,
          child: Stack(
            children: [
              // Track
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOver
                          ? [
                              Colors.red.withValues(alpha: 0.7),
                              Colors.red.withValues(alpha: 0.9),
                            ]
                          : [
                              AppTheme.goldColor.withValues(alpha: 0.6),
                              AppTheme.goldColor,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Macro Summary Row ──
  Widget _buildMacroSummary(
    bool isDark,
    Map<String, double> macros,
    BuildContext context,
  ) {
    return Row(
      children: [
        _buildMacroPill(
          label: 'پ',
          value: macros['protein'] ?? 0,
          color: AppTheme.proteinColor,
          isDark: isDark,
          context: context,
        ),
        SizedBox(width: 6.w),
        _buildMacroPill(
          label: 'ک',
          value: macros['carbs'] ?? 0,
          color: AppTheme.carbsColor,
          isDark: isDark,
          context: context,
        ),
        SizedBox(width: 6.w),
        _buildMacroPill(
          label: 'چ',
          value: macros['fat'] ?? 0,
          color: AppTheme.fatColor,
          isDark: isDark,
          context: context,
        ),
      ],
    );
  }

  Widget _buildMacroPill({
    required String label,
    required double value,
    required Color color,
    required bool isDark,
    required BuildContext context,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5.w,
          height: 5.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.8 : 0.7),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 3.w),
        Text(
          MealLogUtils.convertToPersianNumbers(
            '$label ${value.toStringAsFixed(0)}g',
          ),
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark
                ? Colors.white.withValues(alpha: 0.45)
                : context.textColor.withValues(alpha: 0.45),
            fontSize: 9.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Calculations ──
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

  Map<String, double> _calculateMealMacros() {
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    for (final foodItem in foodItems) {
      final food = allFoods.firstWhere(
        (f) => f.id == foodItem.foodId,
        orElse: () => MealLogUtils.createDefaultFood(foodItem.foodId),
      );
      if (food.id != 0) {
        final ratio = foodItem.amount / 100.0;
        protein += (double.tryParse(food.nutrition.protein) ?? 0) * ratio;
        carbs +=
            (double.tryParse(food.nutrition.carbohydrates) ?? 0) * ratio;
        fat += (double.tryParse(food.nutrition.fat) ?? 0) * ratio;
      }
    }
    return {'protein': protein, 'carbs': carbs, 'fat': fat};
  }

}
