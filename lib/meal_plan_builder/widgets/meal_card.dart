// کارت وعده غذایی (Meal Card) مخصوص صفحه ساخت برنامه غذایی
// استفاده در MealPlanBuilderScreen
// طراحی مشابه MealSection در میل لاگ

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_plan_builder/dialogs/edit_food_dialog.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    required this.onDeleteAlternative,
    required this.onDeleteFood,
    required this.onAddFood,
    required this.allFoods,
    required this.calcMealNutrition,
    super.key,
    this.onMoveUp,
    this.onMoveDown,
    this.dailyCalorieTarget,
  });
  final MealItem meal;
  final int itemIdx;
  final ThemeData theme;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onDelete;
  final VoidCallback onNote;
  final void Function(int foodIdx) onAddAlternative;
  final void Function(int foodIdx, int altFoodId) onDeleteAlternative;
  final Future<void> Function(int foodIdx) onDeleteFood;
  final void Function() onAddFood;
  final List<Food> allFoods;
  final double Function(MealItem meal, String field) calcMealNutrition;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final double? dailyCalorieTarget;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCalories = calcMealNutrition(meal, 'calories');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
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
        borderRadius: BorderRadius.circular(20.r),
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
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // خط اول: آیکون + اسم وعده + مقدار کالری
                Row(
                  children: [
                    Image.asset(
                      MealLogUtils.getMealImageAsset(meal.title),
                      width: 28.w,
                      height: 28.w,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        MealLogUtils.getMealIcon(meal.title),
                        color: isDark ? AppTheme.goldColor : context.textColor,
                        size: 28.sp,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        meal.title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (dailyCalorieTarget != null) ...[
                          SizedBox(width: 6.w),
                          Tooltip(
                            message:
                                'این مقادیر کالری بر اساس TDEE (کل انرژی روزانه مورد نیاز) محاسبه شده و برای تثبیت وزن کاربر است. برای کاهش وزن باید کالری کمتر و برای افزایش وزن باید کالری بیشتری در نظر بگیرید.',
                            textStyle: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.sp,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.backgroundColor
                                  : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (dialogContext) {
                                      final dialogIsDark =
                                          Theme.of(dialogContext).brightness ==
                                          Brightness.dark;
                                      return AlertDialog(
                                        backgroundColor: dialogIsDark
                                            ? context.backgroundColor
                                            : context.cardColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          side: BorderSide(
                                            color: AppTheme.goldColor
                                                .withValues(
                                                  alpha: dialogIsDark
                                                      ? 0.3
                                                      : 0.5,
                                                ),
                                            width: 1.5.w,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Icon(
                                              LucideIcons.info,
                                              color: AppTheme.goldColor,
                                              size: 24.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Text(
                                                'اطلاعات کالری',
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTheme.fontFamily,
                                                  color: dialogIsDark
                                                      ? AppTheme.goldColor
                                                      : context.textColor,
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: SingleChildScrollView(
                                          child: Text(
                                            'این مقادیر کالری بر اساس TDEE (کل انرژی روزانه مورد نیاز) محاسبه شده و برای تثبیت وزن کاربر است.\n\n'
                                            '• برای کاهش وزن: باید کالری کمتر از TDEE مصرف شود (معمولاً 300-500 کالری کمتر)\n'
                                            '• برای افزایش وزن: باید کالری بیشتر از TDEE مصرف شود (معمولاً 300-500 کالری بیشتر)\n\n'
                                            'مقدار TDEE محاسبه شده: ${dailyCalorieTarget!.toStringAsFixed(0)} کالری',
                                            style: TextStyle(
                                              fontFamily: AppTheme.fontFamily,
                                              color: dialogIsDark
                                                  ? AppTheme.goldColor
                                                        .withValues(alpha: 0.9)
                                                  : context.textColor
                                                        .withValues(alpha: 0.9),
                                              fontSize: 14.sp,
                                              height: 1.6,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogContext),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppTheme.goldColor,
                                            ),
                                            child: Text(
                                              'متوجه شدم',
                                              style: TextStyle(
                                                fontFamily: AppTheme.fontFamily,
                                                color: AppTheme.goldColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14.sp,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  child: Icon(
                                    LucideIcons.helpCircle,
                                    color: AppTheme.goldColor.withValues(
                                      alpha: isDark ? 0.8 : 0.7,
                                    ),
                                    size: 16.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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
                // خط دوم: + افزودن وعده + دکمه‌های مدیریت
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // دکمه افزودن غذا
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            LucideIcons.plus,
                            color: isDark
                                ? AppTheme.goldColor
                                : context.textColor,
                            size: 18.sp,
                          ),
                          tooltip: 'افزودن ${meal.title}',
                          onPressed: onAddFood,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                        Text(
                          'افزودن ${meal.title}',
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
                    // دکمه یادداشت
                    IconButton(
                      icon: Icon(
                        LucideIcons.messageCircle,
                        color: meal.note != null && meal.note!.isNotEmpty
                            ? AppTheme.goldColor
                            : isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.5)
                            : context.textColor.withValues(alpha: 0.5),
                        size: 18.sp,
                      ),
                      tooltip: meal.note != null && meal.note!.isNotEmpty
                          ? 'ویرایش یادداشت'
                          : 'افزودن یادداشت',
                      onPressed: onNote,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Food items
          ...[
            ...meal.foods.asMap().entries.expand<Widget>((entry) {
              final foodIdx = entry.key;
              final mf = entry.value;
              final isLastItem = foodIdx == meal.foods.length - 1;
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

              // محاسبه کالری
              final ratio = mf.amount / 100.0;
              final calories =
                  (double.tryParse(food.nutrition.calories) ?? 0) * ratio;

              // بررسی اینکه آیا این یک مکمل است
              final bool isSupplement = food.type == 'supplement';

              // استخراج یادداشت از content (اگر مکمل باشد)
              String? supplementNote;
              if (isSupplement && food.content.isNotEmpty) {
                try {
                  // content به صورت "SUPPLEMENT_NOTE:note" است
                  if (food.content.startsWith('SUPPLEMENT_NOTE:')) {
                    supplementNote = food.content.substring(
                      'SUPPLEMENT_NOTE:'.length,
                    );
                    if (supplementNote.isEmpty) {
                      supplementNote = null;
                    }
                  }
                } catch (e) {
                  // در صورت خطا، نادیده بگیر
                }
              }

              final widget = Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: Food name | Calories
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    // آیکون مکمل
                                    if (isSupplement) ...[
                                      Image.asset(
                                        'images/whey.png',
                                        width: 20.w,
                                        height: 20.w,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            SizedBox(width: 18.w, height: 18.w),
                                      ),
                                      SizedBox(width: 6.w),
                                    ],
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
                                  ],
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  MealLogUtils.convertToPersianNumbers(
                                    '${calories.toStringAsFixed(0)} کالری',
                                  ),
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: context.textColor.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 12.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          // Row 2: Amount + Unit (editable) | Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Amount + Unit (editable)
                              GestureDetector(
                                onTap: () async {
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
                                    meal.foods[foodIdx] = MealFood(
                                      foodId: mf.foodId,
                                      amount: (result['amount'] as num)
                                          .toDouble(),
                                      unit: result['unit'] as String?,
                                      alternatives: mf.alternatives,
                                    );
                                    (context as Element).markNeedsBuild();
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      MealLogUtils.convertToPersianNumbers(
                                        '${mf.amount.toStringAsFixed(0)} ${mf.unit ?? 'گرم'}',
                                      ),
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        color: isDark
                                            ? AppTheme.goldColor
                                            : Colors.black,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      LucideIcons.edit2,
                                      size: 11.sp,
                                      color: isDark
                                          ? AppTheme.goldColor.withValues(
                                              alpha: 0.7,
                                            )
                                          : Colors.black.withValues(alpha: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                              // Actions (مکمل‌ها دکمه جایگزین ندارند)
                              if (!isSupplement)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // دکمه جایگزین
                                    IconButton(
                                      icon: Icon(
                                        LucideIcons.refreshCw,
                                        color: AppTheme.goldColor,
                                        size: 16.sp,
                                      ),
                                      tooltip: 'جایگزین',
                                      onPressed: () =>
                                          onAddAlternative(foodIdx),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                    // دکمه حذف
                                    IconButton(
                                      icon: Icon(
                                        LucideIcons.trash2,
                                        color: Colors.red[600],
                                        size: 16.sp,
                                      ),
                                      tooltip: 'حذف',
                                      onPressed: () async =>
                                          await onDeleteFood(foodIdx),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                  ],
                                )
                              else
                                // فقط دکمه حذف برای مکمل
                                IconButton(
                                  icon: Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red[600],
                                    size: 16.sp,
                                  ),
                                  tooltip: 'حذف',
                                  onPressed: () async =>
                                      await onDeleteFood(foodIdx),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                            ],
                          ),
                          // نمایش یادداشت مکمل
                          if (isSupplement && supplementNote != null) ...[
                            SizedBox(height: 6.h),
                            Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: AppTheme.goldColor.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    LucideIcons.messageCircle,
                                    size: 12.sp,
                                    color: isDark
                                        ? AppTheme.goldColor.withValues(
                                            alpha: 0.8,
                                          )
                                        : context.textColor.withValues(
                                            alpha: 0.7,
                                          ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      supplementNote,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 11.sp,
                                        color: isDark
                                            ? AppTheme.goldColor.withValues(
                                                alpha: 0.8,
                                              )
                                            : context.textColor.withValues(
                                                alpha: 0.7,
                                              ),
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // نمایش جایگزین‌ها اگر وجود دارند (فقط برای غذاهای عادی)
                          if (!isSupplement &&
                              mf.alternatives != null &&
                              mf.alternatives!.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 4.h,
                              children: mf.alternatives!.map((alt) {
                                final altFood = allFoods.firstWhere(
                                  (f) => f.id == alt['food_id'],
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
                                final altFoodId = alt['food_id'] as int;
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4.r),
                                    border: Border.all(
                                      color: AppTheme.goldColor.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.refreshCw,
                                        size: 10.sp,
                                        color: AppTheme.goldColor,
                                      ),
                                      SizedBox(width: 4.w),
                                      Flexible(
                                        child: Text(
                                          '${altFood.title} (${alt['amount']}${mf.unit ?? ''})',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 10.sp,
                                            color: isDark
                                                ? AppTheme.goldColor
                                                : Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      GestureDetector(
                                        onTap: () => onDeleteAlternative(
                                          foodIdx,
                                          altFoodId,
                                        ),
                                        child: Icon(
                                          LucideIcons.x,
                                          size: 10.sp,
                                          color: Colors.red[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );

              // اضافه کردن divider بین آیتم‌ها (به جز آخرین)
              if (isLastItem) {
                return [widget];
              } else {
                return [
                  widget,
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 6.h,
                    ),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkGreySeparator.withValues(alpha: 0.6)
                            : AppTheme.lightDividerColor.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(0.5.r),
                      ),
                    ),
                  ),
                ];
              }
            }).toList(),
            // یادداشت وعده (قبل از مجموع کالری)
            if (meal.note != null && meal.note!.isNotEmpty) ...[
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
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppTheme.goldColor.withValues(
                            alpha: isDark ? 0.4 : 0.5,
                          ),
                          width: 1.5.w,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.messageSquare,
                            color: AppTheme.goldColor,
                            size: 18.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              meal.note!,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? AppTheme.goldColor
                                    : context.textColor,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // Total calories for this meal
            if (meal.foods.isNotEmpty) ...[
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
                    Flexible(
                      child: Text(
                        'مجموع کالری',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.8)
                              : context.textColor.withValues(alpha: 0.7),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        MealLogUtils.convertToPersianNumbers(
                          '${totalCalories.toStringAsFixed(0)} کالری',
                        ),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _getCalorieRangeText() {
    final range = MealLogUtils.getRecommendedCalorieRange(
      meal.title,
      dailyCalorieTarget,
    );
    return '${range['min']} تا ${range['max']} کالری';
  }
}
