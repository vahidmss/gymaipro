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

  @override
  Widget build(BuildContext context) {
    final scaled = MealLogUtils.scaledItemNutrition(food, foodItem);
    final unitLabel =
        food.meta.servingUnits.resolve(foodItem.unit)?.displayLabel ??
        foodItem.unit;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.88,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: MealLogColors.sectionBackground(context),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
              border: Border.all(
                color: MealLogColors.accent(context).withValues(alpha: 0.35),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: MealLogColors.inputBorder(context),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Text(
                  food.displayTitle,
                  style: MealLogTypography.sectionTitle(context).copyWith(
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  MealLogUtils.convertToPersianNumbers(
                    '${foodItem.amount.toStringAsFixed(foodItem.amount % 1 == 0 ? 0 : 1)} $unitLabel',
                  ),
                  style: MealLogTypography.caption(context),
                ),
                if (food.meta.foodGroup.isNotEmpty ||
                    food.meta.mealTimes.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  _MetaChips(food: food),
                ],
                SizedBox(height: 14.h),
                _CalorieHero(
                  calories: scaled['calories'] ?? 0,
                ),
                SizedBox(height: 14.h),
                _MacroGrid(scaled: scaled),
                SizedBox(height: 14.h),
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
                  SizedBox(height: 12.h),
                  Text(
                    'نکات',
                    style: MealLogTypography.caption(
                      context,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6.h),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MealLogColors.accent(context).withValues(alpha: 0.18),
            MealLogColors.accent(context).withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: MealLogColors.accent(context).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.flame,
            color: MealLogColors.accent(context),
            size: 22.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            MealLogUtils.convertToPersianNumbers(
              calories.toStringAsFixed(0),
            ),
            style: MealLogTypography.statValue(
              context,
              color: MealLogColors.primaryText(context),
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            'کالری',
            style: MealLogTypography.statLabel(context),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: MealLogColors.isDark(context) ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Text(
            MealLogUtils.convertToPersianNumbers(
              '${value.toStringAsFixed(1)}g',
            ),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: MealLogColors.macroText(context, color),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: MealLogColors.macroText(context, color),
            ),
            textAlign: TextAlign.center,
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
    final items = <_MicroItem>[
      _MicroItem('فیبر', scaled['fiber'] ?? 0, 'g', LucideIcons.leaf),
      _MicroItem('قند', scaled['sugar'] ?? 0, 'g', LucideIcons.candy),
      _MicroItem('چربی اشباع', scaled['saturatedFat'] ?? 0, 'g', LucideIcons.droplet),
      _MicroItem('سدیم', scaled['sodium'] ?? 0, 'mg', LucideIcons.flaskConical),
      _MicroItem('پتاسیم', scaled['potassium'] ?? 0, 'mg', LucideIcons.zap),
      _MicroItem('کلسترول', scaled['cholesterol'] ?? 0, 'mg', LucideIcons.heartPulse),
    ].where((e) => e.value > 0.05).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'جزئیات تغذیه‌ای',
          style: MealLogTypography.caption(
            context,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8.h),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: _MicroRow(item: item),
          ),
        ),
      ],
    );
  }
}

class _MicroItem {
  const _MicroItem(this.label, this.value, this.unit, this.icon);

  final String label;
  final double value;
  final String unit;
  final IconData icon;
}

class _MicroRow extends StatelessWidget {
  const _MicroRow({required this.item});

  final _MicroItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: MealLogColors.chipFill(context, selected: false),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: MealLogColors.chipBorder(context, selected: false),
        ),
      ),
      child: Row(
        children: [
          Icon(
            item.icon,
            size: 14.sp,
            color: MealLogColors.iconOnSurface(context),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              item.label,
              style: MealLogTypography.caption(context),
            ),
          ),
          Text(
            MealLogUtils.convertToPersianNumbers(
              '${item.value.toStringAsFixed(item.unit == 'mg' ? 0 : 1)} ${item.unit}',
            ),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: MealLogColors.primaryText(context),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w600,
              color: MealLogColors.isDark(context)
                  ? color.withValues(alpha: 0.95)
                  : color.withValues(alpha: 0.88),
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.activity, size: 14.sp, color: color),
          SizedBox(width: 8.w),
          Text(
            '${FoodDisplayLabels.glycemicLabel(gi)} (${MealLogUtils.convertToPersianNumbers(gi.toStringAsFixed(0))})',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
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
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
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
