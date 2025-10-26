// کارت وعده غذایی (Meal Card) مخصوص صفحه ساخت برنامه غذایی
// استفاده در MealPlanBuilderScreen

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_plan/meal_plan_builder/dialogs/edit_food_dialog.dart';
import 'package:gymaipro/meal_plan/meal_plan_builder/widgets/nutrition_tag.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MealCardMealPlanBuilder extends StatelessWidget {
  const MealCardMealPlanBuilder({
    required this.meal,
    required this.itemIdx,
    required this.theme,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onDelete,
    required this.onNote,
    required this.onAddAlternative,
    required this.onDeleteFood,
    required this.onAddFood,
    required this.allFoods,
    required this.calcMealNutrition,
    super.key,
    this.onMoveUp,
    this.onMoveDown,
  });
  final MealItem meal;
  final int itemIdx;
  final ThemeData theme;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onDelete;
  final VoidCallback onNote;
  final void Function(int foodIdx) onAddAlternative;
  final void Function(int foodIdx) onDeleteFood;
  final void Function() onAddFood;
  final List<Food> allFoods;
  final double Function(MealItem meal, String field) calcMealNutrition;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final isSnack = meal.mealType.startsWith('snack');
    final primaryColor = isSnack ? Colors.orange[600]! : Colors.green[600]!;
    final backgroundColor = isSnack ? Colors.orange[50]! : Colors.green[50]!;
    final borderColor = isSnack ? Colors.orange[200]! : Colors.green[200]!;
    return Column(
      key: ValueKey('meal_${meal.id}_$itemIdx'),
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [backgroundColor, backgroundColor.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.1),
                blurRadius: 12.r,
                offset: Offset(0.w, 4.h),
              ),
            ],
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (onMoveUp != null)
                      IconButton(
                        icon: Icon(
                          Icons.arrow_upward,
                          color: Colors.amber[700],
                          size: 20.sp,
                        ),
                        tooltip: 'انتقال به بالا',
                        onPressed: onMoveUp,
                      ),
                    if (onMoveDown != null)
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: Colors.amber[700],
                          size: 20.sp,
                        ),
                        tooltip: 'انتقال به پایین',
                        onPressed: onMoveDown,
                      ),
                    const SizedBox(width: 12),
                    // Icon
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isSnack
                            ? Icon(
                                LucideIcons.coffee,
                                color: primaryColor,
                                size: 18.sp,
                                key: const ValueKey('snack'),
                              )
                            : Icon(
                                LucideIcons.utensils,
                                color: primaryColor,
                                size: 18.sp,
                                key: const ValueKey('main'),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meal.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                          fontSize: 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    // Note icon button
                    IconButton(
                      icon: Icon(
                        LucideIcons.messageCircle,
                        color: meal.note != null && meal.note!.isNotEmpty
                            ? Colors.amber[700]
                            : Colors.grey[400],
                        size: 18.sp,
                      ),
                      tooltip: meal.note != null && meal.note!.isNotEmpty
                          ? 'ویرایش یادداشت'
                          : 'افزودن یادداشت',
                      onPressed: onNote,
                    ),
                    // Collapse/Expand button
                    IconButton(
                      icon: AnimatedRotation(
                        turns: isCollapsed ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          LucideIcons.chevronDown,
                          color: primaryColor,
                          size: 20.sp,
                        ),
                      ),
                      onPressed: onToggleCollapse,
                      tooltip: isCollapsed ? 'نمایش جزئیات' : 'جمع کردن',
                    ),
                    // Delete button
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          color: Colors.red[600],
                          size: 18.sp,
                        ),
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
                // Show note if present
                if (meal.note != null && meal.note!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h, bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.messageCircle,
                          color: Colors.amber[700],
                          size: 14.sp,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            meal.note!,
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontSize: 12.sp,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Collapsible content
                if (isCollapsed)
                  Container(height: 56.h, alignment: Alignment.center)
                else
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      // Food items
                      ...meal.foods.asMap().entries.map((fEntry) {
                        final fIdx = fEntry.key;
                        final mf = fEntry.value;
                        final food = allFoods.firstWhere(
                          (f) => f.id == mf.foodId,
                          orElse: () => Food(
                            id: mf.foodId,
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
                          ),
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6.r,
                                offset: Offset(0.w, 2.h),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 16,
                              children: [
                                // Food image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: food.imageUrl.isNotEmpty
                                      ? Image.network(
                                          food.imageUrl,
                                          width: 50.w,
                                          height: 50.h,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 50.w,
                                          height: 50.h,
                                          color: Colors.grey[200],
                                          child: Icon(
                                            LucideIcons.image,
                                            color: Colors.grey[400],
                                            size: 24.sp,
                                          ),
                                        ),
                                ),
                                // Food details
                                SizedBox(
                                  width: 110.w,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food.title,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[800],
                                              fontSize: 12.sp,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // Add alternative button
                                      Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            onTap: () => onAddAlternative(fIdx),
                                            child: Container(
                                              padding: EdgeInsets.all(6.w),
                                              decoration: BoxDecoration(
                                                color: Colors.amber[700]
                                                    ?.withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                border: Border.all(
                                                  color: Colors.amber[700]!
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Icon(
                                                LucideIcons.refreshCw,
                                                color: Colors.amber[700],
                                                size: 16.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${mf.amount.toStringAsFixed(0)} ${mf.unit ?? 'گرم'}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.amber[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      // Alternatives chips (در صورت وجود)
                                      if (mf.alternatives != null &&
                                          mf.alternatives!.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: 8.h,
                                            bottom: 2.h,
                                          ),
                                          child: Wrap(
                                            spacing: 8.w,
                                            runSpacing: 6.h,
                                            children: mf.alternatives!.map((
                                              alt,
                                            ) {
                                              final altFood = allFoods
                                                  .firstWhere(
                                                    (f) =>
                                                        f.id == alt['food_id'],
                                                    orElse: () => Food(
                                                      id: alt['food_id'] as int,
                                                      title: 'جایگزین',
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
                                                    ),
                                                  );
                                              return Chip(
                                                avatar: Icon(
                                                  LucideIcons.refreshCw,
                                                  color: Colors.amber[700],
                                                  size: 14.sp,
                                                ),
                                                label: Text(
                                                  '${altFood.title} (${alt['amount']}${mf.unit ?? ''})',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    Colors.amber[50],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        10.r,
                                                      ),
                                                  side: BorderSide(
                                                    color: Colors.amber[400]!,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Delete button
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      LucideIcons.trash2,
                                      color: Colors.red[600],
                                      size: 18.sp,
                                    ),
                                    onPressed: () => onDeleteFood(fIdx),
                                  ),
                                ),
                                // Edit button
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.amber,
                                    size: 20.sp,
                                  ),
                                  tooltip: 'ویرایش',
                                  onPressed: () async {
                                    final result =
                                        await showDialog<Map<String, dynamic>>(
                                          context: context,
                                          builder: (context) => EditFoodDialog(
                                            food: food,
                                            initialAmount: mf.amount,
                                            initialUnit: mf.unit,
                                          ),
                                        );
                                    if (result != null &&
                                        result['amount'] != null) {
                                      meal.foods[fIdx] = MealFood(
                                        foodId: mf.foodId,
                                        amount: (result['amount'] as num)
                                            .toDouble(),
                                        unit: result['unit'] as String?,
                                        alternatives: mf.alternatives,
                                      );
                                      (context as Element).markNeedsBuild();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: 8.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: const Text('افزودن غذا'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: primaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              side: BorderSide(
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          onPressed: onAddFood,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.barChart2,
                                  color: Colors.amber[700],
                                  size: 20.sp,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'مجموع تغذیه این وعده:',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                NutritionTagMealPlanBuilder(
                                  label: 'کالری',
                                  value: calcMealNutrition(
                                    meal,
                                    'calories',
                                  ).toStringAsFixed(0),
                                  color: Colors.orange,
                                ),
                                NutritionTagMealPlanBuilder(
                                  label: 'پروتئین',
                                  value:
                                      '${calcMealNutrition(meal, 'protein').toStringAsFixed(1)}g',
                                  color: Colors.green,
                                ),
                                NutritionTagMealPlanBuilder(
                                  label: 'کربوهیدرات',
                                  value:
                                      '${calcMealNutrition(meal, 'carbs').toStringAsFixed(1)}g',
                                  color: Colors.blue,
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
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
