import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/food_meta.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bottom sheet with full nutrition facts for a logged food item.
class FoodNutritionDetailSheet extends StatelessWidget {
  const FoodNutritionDetailSheet({
    required this.food,
    required this.foodItem,
    super.key,
  });

  final Food food;
  final FoodLogItem foodItem;

  static Future<void> show(
    BuildContext context, {
    required Food food,
    required FoodLogItem foodItem,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.7)
          : AppTheme.lightTextColor.withValues(alpha: 0.5),
      builder: (context) => FoodNutritionDetailSheet(
        food: food,
        foodItem: foodItem,
      ),
    );
  }

  static String formatAmount(double value, {required bool isMg}) {
    if (isMg) return value.round().toString();
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final scaled = MealLogUtils.scaledItemNutrition(food, foodItem);
    final unitLabel =
        food.meta.servingUnits.resolve(foodItem.unit)?.displayLabel ??
        foodItem.unit;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.64,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: MealLogColors.sectionBackground(context),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              border: Border.all(
                color: MealLogColors.accent(context).withValues(alpha: 0.28),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: MealLogColors.inputBorder(context),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  food.displayTitle,
                  style: MealLogTypography.sectionTitle(context).copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  MealLogUtils.convertToPersianNumbers(
                    '${foodItem.amount.toStringAsFixed(foodItem.amount % 1 == 0 ? 0 : 1)} $unitLabel',
                  ),
                  style: MealLogTypography.caption(context).copyWith(
                    fontSize: 12.sp,
                  ),
                ),
                if (food.meta.foodGroup.isNotEmpty ||
                    food.meta.mealTimes.isNotEmpty ||
                    food.meta.foodType.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  _MetaChips(food: food),
                ],
                SizedBox(height: 16.h),
                _CalorieHero(calories: scaled['calories'] ?? 0),
                SizedBox(height: 12.h),
                _MacroGrid(scaled: scaled),
                SizedBox(height: 16.h),
                _MicroSection(scaled: scaled),
                if (food.meta.hasAllergens) ...[
                  SizedBox(height: 12.h),
                  _InfoBanner(
                    icon: LucideIcons.alertTriangle,
                    color: MealLogColors.warningText(context),
                    background: MealLogColors.warningBackground(context),
                    border: MealLogColors.warningBorder(context),
                    text: 'آلرژن: ${food.meta.allergens}',
                  ),
                ],
                if (food.meta.glycemicIndexValue != null) ...[
                  SizedBox(height: 8.h),
                  _GiBadge(gi: food.meta.glycemicIndexValue!),
                ],
                if (food.meta.hasTips) ...[
                  SizedBox(height: 16.h),
                  Text(
                    'نکات',
                    style: MealLogTypography.sectionTitle(context).copyWith(
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...food.meta.tips.map(
                    (tip) => Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: _InfoBanner(
                        icon: LucideIcons.lightbulb,
                        color: MealLogColors.noteText(context),
                        background: MealLogColors.noteBackground(context),
                        border: MealLogColors.noteBorder(context),
                        text: tip,
                      ),
                    ),
                  ),
                ],
                if (food.meta.servingNotes.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  _InfoBanner(
                    icon: LucideIcons.info,
                    color: MealLogColors.secondaryText(context),
                    background: MealLogColors.chipFill(
                      context,
                      selected: false,
                    ),
                    border: MealLogColors.chipBorder(
                      context,
                      selected: false,
                    ),
                    text: food.meta.servingNotes,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CalorieHero extends StatelessWidget {
  const _CalorieHero({required this.calories});

  final double calories;

  @override
  Widget build(BuildContext context) {
    final accent = MealLogColors.accent(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: accent.withValues(alpha: 0.16),
            ),
            child: Icon(LucideIcons.flame, color: accent, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'کالری این وعده',
                  style: MealLogTypography.statLabel(context).copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: MealLogUtils.convertToPersianNumbers(
                          calories.toStringAsFixed(0),
                        ),
                        style: MealLogTypography.statValue(context).copyWith(
                          fontSize: 28.sp,
                          height: 1.05,
                        ),
                      ),
                      TextSpan(
                        text: '  کالری',
                        style: MealLogTypography.caption(
                          context,
                          color: MealLogColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroGrid extends StatelessWidget {
  const _MacroGrid({required this.scaled});

  final Map<String, double> scaled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroTile(
            label: 'پروتئین',
            value: scaled['protein'] ?? 0,
            color: AppTheme.proteinColor,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _MacroTile(
            label: 'کربوهیدرات',
            value: scaled['carbs'] ?? 0,
            color: AppTheme.carbsColor,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _MacroTile(
            label: 'چربی',
            value: scaled['fat'] ?? 0,
            color: AppTheme.fatColor,
          ),
        ),
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final amount = FoodNutritionDetailSheet.formatAmount(value, isMg: false);
    final ink = MealLogColors.macroText(context, color);

    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 10.h),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: MealLogColors.isDark(context) ? 0.14 : 0.08,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: ink.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.h),
          Text(
            MealLogUtils.convertToPersianNumbers(amount),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: ink,
              height: 1,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'گرم',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: ink.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicroSection extends StatelessWidget {
  const _MicroSection({required this.scaled});

  final Map<String, double> scaled;

  @override
  Widget build(BuildContext context) {
    final candidates = <({
      String label,
      String key,
      bool isMg,
      IconData icon,
    })>[
      (label: 'فیبر', key: 'fiber', isMg: false, icon: LucideIcons.leaf),
      (label: 'قند', key: 'sugar', isMg: false, icon: LucideIcons.candy),
      (
        label: 'چربی اشباع',
        key: 'saturatedFat',
        isMg: false,
        icon: LucideIcons.droplet,
      ),
      (
        label: 'سدیم',
        key: 'sodium',
        isMg: true,
        icon: LucideIcons.flaskConical,
      ),
      (label: 'پتاسیم', key: 'potassium', isMg: true, icon: LucideIcons.zap),
      (
        label: 'کلسترول',
        key: 'cholesterol',
        isMg: true,
        icon: LucideIcons.heartPulse,
      ),
    ];

    final items = [
      for (final c in candidates)
        if ((scaled[c.key] ?? 0) > 0.05) c,
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'جزئیات تغذیه‌ای',
          style: MealLogTypography.sectionTitle(context).copyWith(
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        DecoratedBox(
          decoration: BoxDecoration(
            color: MealLogColors.panelBackground(context),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: MealLogColors.chipBorder(context, selected: false),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _MicroRow(
                  label: items[i].label,
                  value: scaled[items[i].key] ?? 0,
                  isMg: items[i].isMg,
                  icon: items[i].icon,
                ),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 44.w,
                    color: MealLogColors.inputBorder(context),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MicroRow extends StatelessWidget {
  const _MicroRow({
    required this.label,
    required this.value,
    required this.isMg,
    required this.icon,
  });

  final String label;
  final double value;
  final bool isMg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final amount = FoodNutritionDetailSheet.formatAmount(value, isMg: isMg);
    final unit = isMg ? 'میلی‌گرم' : 'گرم';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: MealLogColors.accent(context).withValues(alpha: 0.1),
            ),
            child: Icon(
              icon,
              size: 14.sp,
              color: MealLogColors.iconOnSurface(context),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: MealLogTypography.caption(
                context,
                color: MealLogColors.primaryText(context),
                fontWeight: FontWeight.w700,
              ).copyWith(fontSize: 12.5.sp),
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: MealLogUtils.convertToPersianNumbers(amount),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: MealLogColors.primaryText(context),
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: MealLogColors.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  const _MetaChips({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    final group = food.meta.foodGroup.trim();
    if (group.isNotEmpty) {
      final color = FoodDisplayLabels.groupColor(group);
      chips.add(
        _Chip(
          label: group,
          color: color,
          icon: FoodDisplayLabels.groupIcon(group),
        ),
      );
    }
    if (food.meta.foodType.isNotEmpty) {
      chips.add(
        _Chip(
          label: FoodDisplayLabels.foodTypeLabel(food.meta.foodType),
          color: MealLogColors.accent(context),
          icon: LucideIcons.tag,
        ),
      );
    }
    for (final meal in food.meta.mealTimes.take(2)) {
      chips.add(
        _Chip(
          label: meal,
          color: MealLogColors.secondaryText(context),
          icon: LucideIcons.clock,
        ),
      );
    }

    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      textDirection: TextDirection.rtl,
      children: chips,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
              color: MealLogColors.isDark(context)
                  ? color.withValues(alpha: 0.95)
                  : color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiBadge extends StatelessWidget {
  const _GiBadge({required this.gi});

  final double gi;

  @override
  Widget build(BuildContext context) {
    final color = FoodDisplayLabels.glycemicColor(gi);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.activity, size: 15.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${FoodDisplayLabels.glycemicLabel(gi)} · شاخص ${MealLogUtils.convertToPersianNumbers(gi.toStringAsFixed(0))}',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.background,
    required this.border,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final Color border;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
