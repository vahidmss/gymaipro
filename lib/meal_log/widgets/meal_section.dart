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
      duration: const Duration(milliseconds: 280),
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: MealLogColors.sectionBackground(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isHighlighted
              ? MealLogColors.accent(context).withValues(alpha: 0.7)
              : hasFoods
              ? MealLogColors.accent(context).withValues(alpha: 0.45)
              : MealLogColors.chipBorder(context, selected: false),
          width: isHighlighted ? 1.8 : (hasFoods ? 1.2 : 0.8),
        ),
        boxShadow: [
          if (hasFoods || isHighlighted)
            BoxShadow(
              color: MealLogColors.accent(context).withValues(
                alpha: MealLogColors.isDark(context) ? 0.1 : 0.14,
              ),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          BoxShadow(
            color: MealLogColors.isDark(context)
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
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: MealLogColors.chipFill(context, selected: true),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: MealLogColors.chipBorder(context, selected: true),
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      MealLogUtils.getMealImageAsset(title),
                      width: 20.w,
                      height: 20.w,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        icon,
                        color: MealLogColors.accent(context),
                        size: 18.sp,
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
                        style: MealLogTypography.mealTitle(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          if (hasFoods) ...[
                            Text(
                              MealLogUtils.convertToPersianNumbers(
                                totalCalories.toStringAsFixed(0),
                              ),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: MealLogColors.accent(context),
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              MealLogUtils.convertToPersianNumbers(
                                ' / ${range['min']}~${range['max']} کالری',
                              ),
                              style: MealLogTypography.caption(
                                context,
                                color: MealLogColors.mutedText(context),
                                fontWeight: FontWeight.w400,
                              ).copyWith(fontSize: 9.sp),
                            ),
                          ] else ...[
                            Text(
                              MealLogUtils.convertToPersianNumbers(
                                '${range['min']} ~ ${range['max']} کالری',
                              ),
                              style: MealLogTypography.caption(
                                context,
                                color: MealLogColors.mutedText(context),
                                fontWeight: FontWeight.w400,
                              ).copyWith(fontSize: 9.sp),
                            ),
                          ],
                          SizedBox(width: 4.w),
                          Icon(
                            LucideIcons.info,
                            size: 9.sp,
                            color: MealLogColors.hintText(context),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'تقریبی',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: MealLogColors.hintText(context),
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildAddButton(context),
              ],
            ),
          ),
          if (hasFoods) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
              child: _buildCalorieProgress(context, progress, isOver),
            ),
          ],
          if (hasFoods) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 4.h),
              child: _buildMacroSummary(context, macros),
            ),
          ],
          if (!hasFoods)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 10.h),
              child: Text(
                'برای ثبت غذا روی + بزنید',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: MealLogColors.emptyHint(context),
                  fontSize: 10.sp,
                ),
              ),
            ),
          if (note != null && note!.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: MealLogColors.noteBackground(context),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: MealLogColors.noteBorder(context),
                  ),
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
                      child: Text(
                        note!,
                        style: MealLogTypography.note(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (hasFoods) ...[
            Padding(
              padding: EdgeInsets.only(top: 2.h),
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
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مجموع',
                    style: MealLogTypography.caption(
                      context,
                      color: MealLogColors.mutedText(context),
                    ),
                  ),
                  Text(
                    MealLogUtils.convertToPersianNumbers(
                      '${totalCalories.toStringAsFixed(0)} کالری',
                    ),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: MealLogColors.accent(context),
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

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddFood,
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          color: MealLogColors.chipFill(context, selected: true),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: MealLogColors.chipBorder(context, selected: true),
          ),
        ),
        child: Icon(
          LucideIcons.plus,
          color: MealLogColors.accent(context),
          size: 16.sp,
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
        borderRadius: BorderRadius.circular(2.r),
        child: SizedBox(
          height: 3.h,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: MealLogColors.inputBorder(context),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: Container(
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

  Widget _buildMacroSummary(
    BuildContext context,
    Map<String, double> macros,
  ) {
    return Row(
      children: [
        _buildMacroPill(
          context: context,
          label: 'پ',
          value: macros['protein'] ?? 0,
          color: AppTheme.proteinColor,
        ),
        SizedBox(width: 6.w),
        _buildMacroPill(
          context: context,
          label: 'ک',
          value: macros['carbs'] ?? 0,
          color: AppTheme.carbsColor,
        ),
        SizedBox(width: 6.w),
        _buildMacroPill(
          context: context,
          label: 'چ',
          value: macros['fat'] ?? 0,
          color: AppTheme.fatColor,
        ),
      ],
    );
  }

  Widget _buildMacroPill({
    required BuildContext context,
    required String label,
    required double value,
    required Color color,
  }) {
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
            '$label ${value.toStringAsFixed(0)}g',
          ),
          style: MealLogTypography.caption(
            context,
            color: MealLogColors.mutedText(context),
            fontWeight: FontWeight.w500,
          ).copyWith(fontSize: 9.sp),
        ),
      ],
    );
  }

  double _calculateMealTotalCalories() {
    double total = 0;
    for (final foodItem in foodItems) {
      final food = MealLogUtils.resolveFood(allFoods, foodItem.foodId);
      if (food.id != 0) {
        total += MealLogUtils.scaledItemNutrition(food, foodItem)['calories'] ??
            0;
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
