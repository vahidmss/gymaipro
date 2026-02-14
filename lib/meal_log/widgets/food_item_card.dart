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
    final isFromPlan = foodItem.mealPlanId != null;
    final isManuallyAdded = !isFromPlan;

    final consumedAmount = foodItem.amount;
    final ratio = consumedAmount / 100.0;
    final calories = (double.tryParse(food.nutrition.calories) ?? 0) * ratio;
    final protein = (double.tryParse(food.nutrition.protein) ?? 0) * ratio;
    final carbs = (double.tryParse(food.nutrition.carbohydrates) ?? 0) * ratio;
    final fat = (double.tryParse(food.nutrition.fat) ?? 0) * ratio;

    // Macro total for proportional bars
    final macroTotal = protein + carbs + fat;
    final proteinFrac = macroTotal > 0 ? protein / macroTotal : 0.33;
    final carbsFrac = macroTotal > 0 ? carbs / macroTotal : 0.33;
    final fatFrac = macroTotal > 0 ? fat / macroTotal : 0.34;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left accent bar ──
            Container(
              width: 3.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isFromPlan
                      ? [
                          Colors.blue.withValues(alpha: 0.7),
                          Colors.blue.withValues(alpha: 0.3),
                        ]
                      : [
                          AppTheme.goldColor.withValues(alpha: 0.7),
                          AppTheme.goldColor.withValues(alpha: 0.2),
                        ],
                ),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 8.w),
            // ── Content ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: food name + calorie badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            food.title,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isDark ? Colors.white : context.textColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        // Calorie badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.goldColor.withValues(alpha: 0.12)
                                : AppTheme.goldColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            MealLogUtils.convertToPersianNumbers(
                              '${calories.toStringAsFixed(0)} kcal',
                            ),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isDark
                                  ? AppTheme.goldColor
                                  : AppTheme.darkGold,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    // Row 2: tag + amount + macro bar
                    Row(
                      children: [
                        // Plan/Free tag
                        _buildTag(isDark, isManuallyAdded, context),
                        SizedBox(width: 6.w),
                        // Amount (editable)
                        GestureDetector(
                          onTap: onEditAmount,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                MealLogUtils.convertToPersianNumbers(
                                  foodItem.plannedAmount != null
                                      ? '${foodItem.plannedAmount!.toStringAsFixed(0)}/${consumedAmount.toStringAsFixed(0)} ${foodItem.unit}'
                                      : '${consumedAmount.toStringAsFixed(0)} ${foodItem.unit}',
                                ),
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : context.textColor.withValues(
                                          alpha: 0.5,
                                        ),
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(
                                LucideIcons.edit2,
                                size: 9.sp,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : context.textColor.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Macro proportion bar
                        _buildMacroBar(
                          isDark,
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
            // ── Actions menu ──
            _buildActionMenu(isDark, isFromPlan, context),
          ],
        ),
      ),
    );
  }

  // ── Tag widget ──
  Widget _buildTag(bool isDark, bool isManual, BuildContext context) {
    if (isManual) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.goldColor.withValues(alpha: 0.1)
              : AppTheme.goldColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(3.r),
        ),
        child: Text(
          'آزاد',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark
                ? AppTheme.goldColor.withValues(alpha: 0.7)
                : AppTheme.darkGold.withValues(alpha: 0.6),
            fontSize: 8.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ColorFiltered(
          colorFilter: isDark
              ? ColorFilter.mode(Colors.blue[400]!, BlendMode.srcIn)
              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
          child: Image.asset(
            'images/program.png',
            width: 10.w,
            height: 10.h,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          'برنامه',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark ? Colors.blue[400] : Colors.blue[600],
            fontSize: 8.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Macro proportion bar ──
  Widget _buildMacroBar(
    bool isDark,
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
                child: Container(
                  color: AppTheme.proteinColor.withValues(
                    alpha: isDark ? 0.7 : 0.6,
                  ),
                ),
              ),
              Expanded(
                flex: (carbsFrac * 100).round().clamp(1, 100),
                child: Container(
                  color: AppTheme.carbsColor.withValues(
                    alpha: isDark ? 0.7 : 0.6,
                  ),
                ),
              ),
              Expanded(
                flex: (fatFrac * 100).round().clamp(1, 100),
                child: Container(
                  color: AppTheme.fatColor.withValues(
                    alpha: isDark ? 0.7 : 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions menu ──
  Widget _buildActionMenu(bool isDark, bool isFromPlan, BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isDark
            ? Colors.white.withValues(alpha: 0.25)
            : context.textColor.withValues(alpha: 0.25),
        size: 14.sp,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
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
                      size: 12.sp,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'تکمیل شده',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: Colors.green[400],
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
                        color: Colors.blue[400],
                        size: 12.sp,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'جایگزین کردن',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: Colors.blue[400],
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
                    Icon(Icons.delete, color: Colors.red[400], size: 12.sp),
                    SizedBox(width: 5.w),
                    Text(
                      'حذف',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: Colors.red[400],
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
