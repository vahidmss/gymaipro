import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/widgets/food_nutrition_detail_sheet.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final isFromPlan = foodItem.mealPlanId != null;
    final isManuallyAdded = !isFromPlan;

    final scaled = MealLogUtils.scaledItemNutrition(food, foodItem);
    final calories = scaled['calories'] ?? 0;
    final protein = scaled['protein'] ?? 0;
    final carbs = scaled['carbs'] ?? 0;
    final fat = scaled['fat'] ?? 0;

    final macroTotal = protein + carbs + fat;
    final proteinFrac = macroTotal > 0 ? protein / macroTotal : 0.33;
    final carbsFrac = macroTotal > 0 ? carbs / macroTotal : 0.33;
    final fatFrac = macroTotal > 0 ? fat / macroTotal : 0.34;

    final unitLabel =
        food.meta.servingUnits.resolve(foodItem.unit)?.displayLabel ??
        foodItem.unit;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isFromPlan
                      ? [
                          MealLogColors.planAccent(context).withValues(alpha: 0.75),
                          MealLogColors.planAccent(context).withValues(alpha: 0.25),
                        ]
                      : [
                          MealLogColors.accent(context).withValues(alpha: 0.75),
                          MealLogColors.accent(context).withValues(alpha: 0.2),
                        ],
                ),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => FoodNutritionDetailSheet.show(
                    context,
                    food: food,
                    foodItem: foodItem,
                  ),
                  borderRadius: BorderRadius.circular(6.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                food.displayTitle,
                                style: MealLogTypography.foodName(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: MealLogColors.chipFill(
                                  context,
                                  selected: true,
                                ),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: MealLogColors.chipBorder(
                                    context,
                                    selected: true,
                                  ),
                                ),
                              ),
                              child: Text(
                                MealLogUtils.convertToPersianNumbers(
                                  '${calories.toStringAsFixed(0)} kcal',
                                ),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: MealLogColors.accent(context),
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              LucideIcons.info,
                              size: 11.sp,
                              color: MealLogColors.hintText(context),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            _buildTag(isManuallyAdded, context),
                            SizedBox(width: 6.w),
                            GestureDetector(
                              onTap: onEditAmount,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    MealLogUtils.convertToPersianNumbers(
                                      foodItem.plannedAmount != null
                                          ? '${foodItem.plannedAmount!.toStringAsFixed(0)}/${foodItem.amount.toStringAsFixed(foodItem.amount % 1 == 0 ? 0 : 1)} $unitLabel'
                                          : '${foodItem.amount.toStringAsFixed(foodItem.amount % 1 == 0 ? 0 : 1)} $unitLabel',
                                    ),
                                    textDirection: TextDirection.rtl,
                                    style: MealLogTypography.caption(
                                      context,
                                      color: MealLogColors.mutedText(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Icon(
                                    LucideIcons.edit2,
                                    size: 9.sp,
                                    color: MealLogColors.hintText(context),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            _buildMacroBar(
                              proteinFrac,
                              carbsFrac,
                              fatFrac,
                              context,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildActionMenu(isFromPlan, context),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(bool isManual, BuildContext context) {
    if (isManual) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: MealLogColors.chipFill(context, selected: false),
          borderRadius: BorderRadius.circular(3.r),
          border: Border.all(
            color: MealLogColors.chipBorder(context, selected: false),
          ),
        ),
        child: Text(
          'آزاد',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: MealLogColors.accent(context),
            fontSize: 8.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.clipboardList,
          size: 10.sp,
          color: MealLogColors.planAccent(context),
        ),
        SizedBox(width: 2.w),
        Text(
          'برنامه',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: MealLogColors.planAccent(context),
            fontSize: 8.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroBar(
    double proteinFrac,
    double carbsFrac,
    double fatFrac,
    BuildContext context,
  ) {
    final barWidth = 50.w;
    final barHeight = 3.h;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: barWidth,
        height: barHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: Row(
            children: [
              Expanded(
                flex: (proteinFrac * 100).round().clamp(1, 100),
                child: Container(color: AppTheme.proteinColor),
              ),
              Expanded(
                flex: (carbsFrac * 100).round().clamp(1, 100),
                child: Container(color: AppTheme.carbsColor),
              ),
              Expanded(
                flex: (fatFrac * 100).round().clamp(1, 100),
                child: Container(color: AppTheme.fatColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(bool isFromPlan, BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: MealLogColors.hintText(context),
        size: 14.sp,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      color: MealLogColors.sectionBackground(context),
      itemBuilder: (context) => isFromPlan
          ? [
              PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: MealLogColors.successText(context),
                      size: 12.sp,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'تکمیل شده',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: MealLogColors.successText(context),
                        fontSize: 11.sp,
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
                        color: MealLogColors.planAccent(context),
                        size: 12.sp,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'جایگزین کردن',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: MealLogColors.planAccent(context),
                          fontSize: 11.sp,
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
                      color: MealLogColors.errorText(context),
                      size: 12.sp,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'حذف',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: MealLogColors.errorText(context),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
      onSelected: (value) => onAction(value, foodItem, mealTitle),
    );
  }
}
