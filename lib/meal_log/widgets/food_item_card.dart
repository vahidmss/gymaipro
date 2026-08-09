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
    final scaled = MealLogUtils.scaledItemNutrition(food, foodItem);
    final calories = scaled['calories'] ?? 0;
    final unitLabel =
        food.meta.servingUnits.resolve(foodItem.unit)?.displayLabel ??
        foodItem.unit;
    final amountText = foodItem.plannedAmount != null
        ? '${foodItem.plannedAmount!.toStringAsFixed(0)}/${foodItem.amount.toStringAsFixed(foodItem.amount % 1 == 0 ? 0 : 1)} $unitLabel'
        : '${foodItem.amount.toStringAsFixed(foodItem.amount % 1 == 0 ? 0 : 1)} $unitLabel';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => FoodNutritionDetailSheet.show(
          context,
          food: food,
          foodItem: foodItem,
        ),
        onLongPress: onEditAmount,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 6.h, 4.w, 6.h),
          child: Row(
            children: [
              Container(
                width: 3.w,
                height: 34.h,
                decoration: BoxDecoration(
                  color: (isFromPlan
                          ? MealLogColors.planAccent(context)
                          : MealLogColors.accent(context))
                      .withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            food.displayTitle,
                            style: MealLogTypography.foodName(context).copyWith(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          MealLogUtils.convertToPersianNumbers(
                            '${calories.round()} کالری',
                          ),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: MealLogColors.accent(context),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        if (isFromPlan) ...[
                          Icon(
                            LucideIcons.clipboardList,
                            size: 10.sp,
                            color: MealLogColors.planAccent(context),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'برنامه',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: MealLogColors.planAccent(context),
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8.w),
                        ],
                        GestureDetector(
                          onTap: onEditAmount,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                MealLogUtils.convertToPersianNumbers(amountText),
                                textDirection: TextDirection.rtl,
                                style: MealLogTypography.caption(
                                  context,
                                  color: MealLogColors.mutedText(context),
                                  fontWeight: FontWeight.w500,
                                ).copyWith(fontSize: 10.sp),
                              ),
                              SizedBox(width: 3.w),
                              Icon(
                                LucideIcons.pencil,
                                size: 10.sp,
                                color: MealLogColors.hintText(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildActionMenu(isFromPlan, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(bool isFromPlan, BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        LucideIcons.ellipsisVertical,
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
                child: Text(
                  'تکمیل شده',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: MealLogColors.successText(context),
                    fontSize: 12.sp,
                  ),
                ),
              ),
              if (foodItem.alternatives != null &&
                  foodItem.alternatives!.isNotEmpty)
                PopupMenuItem(
                  value: 'substitute',
                  child: Text(
                    'جایگزین کردن',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: MealLogColors.planAccent(context),
                      fontSize: 12.sp,
                    ),
                  ),
                ),
            ]
          : [
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'حذف',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: MealLogColors.errorText(context),
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
      onSelected: (value) => onAction(value, foodItem, mealTitle),
    );
  }
}
