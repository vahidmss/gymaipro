import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/widgets/food_item_card.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
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
    this.isHighlighted = false,
    this.showEmptyHint = false,
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
  final bool isHighlighted;
  final bool showEmptyHint;

  @override
  Widget build(BuildContext context) {
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
    final isOver = progress >= 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: MealLogColors.sectionBackground(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isHighlighted
              ? MealLogColors.accent(context).withValues(alpha: 0.75)
              : MealLogColors.chipBorder(context, selected: false),
          width: isHighlighted ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: MealLogColors.isDark(context) ? 0.25 : 0.035,
            ),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 10.w, hasFoods ? 6.h : 10.h),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: SizedBox(
                    width: 36.w,
                    height: 36.w,
                    child: Image.asset(
                      MealLogUtils.getMealImageAsset(title),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: MealLogColors.chipFill(context, selected: false),
                        child: Icon(
                          icon,
                          color: MealLogColors.accent(context),
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: MealLogTypography.mealTitle(context).copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        MealLogUtils.convertToPersianNumbers(
                          hasFoods
                              ? '${totalCalories.round()} / ${range['min']}~${range['max']} کالری'
                              : '${range['min']} ~ ${range['max']} کالری',
                        ),
                        style: MealLogTypography.caption(
                          context,
                          color: hasFoods && isOver
                              ? MealLogColors.errorText(context)
                              : MealLogColors.mutedText(context),
                          fontWeight: FontWeight.w500,
                        ).copyWith(fontSize: 10.sp),
                      ),
                      if (hasFoods) ...[
                        SizedBox(height: 6.h),
                        _buildCalorieProgress(context, progress, isOver),
                        SizedBox(height: 6.h),
                        _buildMacroSummary(context, macros),
                      ] else if (showEmptyHint || isHighlighted) ...[
                        SizedBox(height: 4.h),
                        Text(
                          isHighlighted
                              ? 'الان وقت ثبت این وعده‌ست'
                              : 'برای ثبت غذا روی افزودن بزنید',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: MealLogColors.emptyHint(context),
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                _buildAddButton(context),
              ],
            ),
          ),
          if (note != null && note!.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: MealLogColors.noteBackground(context),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: MealLogColors.noteBorder(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.messageCircle,
                      color: MealLogColors.noteText(context),
                      size: 13.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(note!, style: MealLogTypography.note(context)),
                    ),
                  ],
                ),
              ),
            ),
          if (hasFoods)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Column(
                children: foodItems.map((foodItem) {
                  final food = MealLogUtils.resolveFood(
                    allFoods,
                    foodItem.foodId,
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
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAddFood,
        borderRadius: BorderRadius.circular(10.r),
        child: Ink(
          decoration: BoxDecoration(
            color: isHighlighted
                ? MealLogColors.accent(context).withValues(alpha: 0.14)
                : MealLogColors.chipFill(context, selected: false),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isHighlighted
                  ? MealLogColors.accent(context).withValues(alpha: 0.7)
                  : MealLogColors.chipBorder(context, selected: false),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.plus,
                  color: MealLogColors.accent(context),
                  size: 14.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  'افزودن',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: MealLogColors.accent(context),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieProgress(
    BuildContext context,
    double progress,
    bool isOver,
  ) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999.r),
        child: SizedBox(
          height: 3.5.h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: MealLogColors.inputBorder(context)),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOver
                            ? [
                                MealLogColors.errorText(context)
                                    .withValues(alpha: 0.7),
                                MealLogColors.errorText(context),
                              ]
                            : [
                                MealLogColors.accent(context)
                                    .withValues(alpha: 0.55),
                                MealLogColors.accent(context),
                              ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroSummary(BuildContext context, Map<String, double> macros) {
    return Row(
      children: [
        _macro(context, 'پ', macros['protein'] ?? 0, AppTheme.proteinColor),
        SizedBox(width: 8.w),
        _macro(context, 'ک', macros['carbs'] ?? 0, AppTheme.carbsColor),
        SizedBox(width: 8.w),
        _macro(context, 'چ', macros['fat'] ?? 0, AppTheme.fatColor),
      ],
    );
  }

  Widget _macro(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5.w,
          height: 5.w,
          decoration: BoxDecoration(
            color: MealLogColors.macroText(context, color),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 3.w),
        Text(
          MealLogUtils.convertToPersianNumbers(
            '$label ${value.toStringAsFixed(0)}گ',
          ),
          style: MealLogTypography.caption(
            context,
            color: MealLogColors.mutedText(context),
            fontWeight: FontWeight.w500,
          ).copyWith(fontSize: 9.5.sp),
        ),
      ],
    );
  }

  double _calculateMealTotalCalories() {
    double total = 0;
    for (final foodItem in foodItems) {
      final food = MealLogUtils.resolveFood(allFoods, foodItem.foodId);
      if (food.id != 0) {
        total +=
            MealLogUtils.scaledItemNutrition(food, foodItem)['calories'] ?? 0;
      }
    }
    return total;
  }

  Map<String, double> _calculateMealMacros() {
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    for (final foodItem in foodItems) {
      final food = MealLogUtils.resolveFood(allFoods, foodItem.foodId);
      if (food.id != 0) {
        final scaled = MealLogUtils.scaledItemNutrition(food, foodItem);
        protein += scaled['protein'] ?? 0;
        carbs += scaled['carbs'] ?? 0;
        fat += scaled['fat'] ?? 0;
      }
    }
    return {'protein': protein, 'carbs': carbs, 'fat': fat};
  }
}
