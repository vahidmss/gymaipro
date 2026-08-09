import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_meal_log.dart';
import 'package:gymaipro/meal_log/services/meal_insight_engine.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/utils/meal_nutrition_targets.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نوار فشردهٔ خلاصهٔ روزانه — جزئیات فقط با expand.
class DailyCalorieSummary extends StatefulWidget {
  const DailyCalorieSummary({
    required this.meals,
    required this.allFoods,
    required this.profileData,
    this.barGuidance,
    this.referenceTime,
    super.key,
  });

  final List<FoodMealLog> meals;
  final List<Food> allFoods;
  final Map<String, dynamic>? profileData;
  final MealCalorieBarGuidance? barGuidance;
  final DateTime? referenceTime;

  @override
  State<DailyCalorieSummary> createState() => _DailyCalorieSummaryState();
}

class _DailyCalorieSummaryState extends State<DailyCalorieSummary>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showChart = false;

  MealNutritionTargets? _cachedTargets;
  Map<String, dynamic>? _cachedProfileRef;
  Map<String, double>? _cachedTotals;
  int? _cachedMealsSignature;
  List<Food>? _cachedFoodsRef;
  bool _cachedExtended = false;

  late final AnimationController _progressAnim;

  static int _mealsContentSignature(List<FoodMealLog> meals) {
    var hash = meals.length;
    for (final meal in meals) {
      hash = Object.hash(hash, meal.title, meal.foods.length, meal.note);
      for (final food in meal.foods) {
        hash = Object.hash(
          hash,
          food.foodId,
          food.amount,
          food.unit,
          food.plannedAmount,
          food.followedPlan,
        );
      }
    }
    return hash;
  }

  @override
  void initState() {
    super.initState();
    _progressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant DailyCalorieSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSig = _mealsContentSignature(oldWidget.meals);
    final newSig = _mealsContentSignature(widget.meals);
    if (oldSig != newSig) {
      _progressAnim
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _progressAnim.dispose();
    super.dispose();
  }

  void _ensureComputed() {
    final profile = widget.profileData;
    if (_cachedProfileRef != profile) {
      _cachedProfileRef = profile;
      _cachedTargets = MealNutritionTargets.fromProfile(profile);
    }

    final needsExtended = _isExpanded;
    final mealsSignature = _mealsContentSignature(widget.meals);
    if (_cachedMealsSignature != mealsSignature ||
        _cachedFoodsRef != widget.allFoods ||
        _cachedExtended != needsExtended ||
        _cachedTotals == null) {
      _cachedMealsSignature = mealsSignature;
      _cachedFoodsRef = widget.allFoods;
      _cachedExtended = needsExtended;
      _cachedTotals = MealLogUtils.calculateTotals(
        widget.meals,
        widget.allFoods,
        extended: needsExtended,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureComputed();

    final targets = _cachedTargets!;
    final dailyCalorieTarget = targets.calorieTarget;
    final totals = _cachedTotals!;
    final consumedCalories = totals['calories'] ?? 0;
    final consumedProtein = totals['protein'] ?? 0;
    final consumedCarbs = totals['carbs'] ?? 0;
    final consumedFat = totals['fat'] ?? 0;

    final calorieDelta = dailyCalorieTarget - consumedCalories;
    final isOver = calorieDelta < 0;
    final progress = dailyCalorieTarget > 0
        ? (consumedCalories / dailyCalorieTarget).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progress * 100).round();
    final barGuidance = widget.barGuidance ?? MealCalorieBarGuidance.empty;
    final remainingAbs = isOver ? -calorieDelta : calorieDelta;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: MealLogColors.sectionBackground(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: MealLogColors.chipBorder(context, selected: false),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: MealLogColors.isDark(context) ? 0.28 : 0.04,
            ),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOver ? 'بیش از مرجع' : 'باقیمانده',
                        style: MealLogTypography.statLabel(context),
                      ),
                      SizedBox(height: 2.h),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: remainingAbs),
                        duration: const Duration(milliseconds: 680),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: MealLogUtils.convertToPersianNumbers(
                                    value.round().toString(),
                                  ),
                                  style: MealLogTypography.statValue(
                                    context,
                                    color: isOver
                                        ? MealLogColors.errorText(context)
                                        : MealLogColors.accent(context),
                                  ).copyWith(fontSize: 28.sp),
                                ),
                                TextSpan(
                                  text: ' کالری',
                                  style: MealLogTypography.caption(
                                    context,
                                    color: MealLogColors.mutedText(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            textDirection: TextDirection.rtl,
                          );
                        },
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        MealLogUtils.convertToPersianNumbers(
                          '$percentage٪ از مرجع',
                        ),
                        style: MealLogTypography.caption(
                          context,
                          color: _pctColor(context, progress, isOver),
                          fontWeight: FontWeight.w700,
                        ).copyWith(fontSize: 10.sp),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 44.h,
                  color: MealLogColors.inputBorder(context),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مصرف شده',
                        style: MealLogTypography.statLabel(context),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        MealLogUtils.convertToPersianNumbers(
                          '${consumedCalories.round()} کالری',
                        ),
                        style: MealLogTypography.sectionTitle(context).copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        MealLogUtils.convertToPersianNumbers(
                          '${targets.calorieReferenceTitle}: ${dailyCalorieTarget.round()}',
                        ),
                        style: MealLogTypography.caption(
                          context,
                          color: MealLogColors.mutedText(context),
                          fontWeight: FontWeight.w500,
                        ).copyWith(fontSize: 10.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
            child: AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_progressAnim.value);
                return _CalorieProgressBar(
                  progress: progress * t,
                  isOver: isOver,
                );
              },
            ),
          ),
          if (barGuidance.hasContent)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 0),
              child: _GuidanceLine(guidance: barGuidance),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(_isExpanded ? 0 : 14.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Icon(
                  _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16.sp,
                  color: MealLogColors.mutedText(context),
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _ExpandedBody(
              consumedProtein: consumedProtein,
              consumedCarbs: consumedCarbs,
              consumedFat: consumedFat,
              consumedCalories: consumedCalories,
              proteinTarget: targets.proteinTarget,
              carbsTarget: targets.carbsTarget,
              fatTarget: targets.fatTarget,
              referenceHint: targets.calorieReferenceHint,
              totals: totals,
              showChart: _showChart,
              onToggleChart: () => setState(() => _showChart = !_showChart),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 240),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Color _pctColor(BuildContext context, double progress, bool isOver) {
    if (isOver) return MealLogColors.errorText(context);
    if (progress >= 0.85) return MealLogColors.successText(context);
    if (progress >= 0.5) return MealLogColors.accent(context);
    return MealLogColors.mutedText(context);
  }
}

class _CalorieProgressBar extends StatelessWidget {
  const _CalorieProgressBar({
    required this.progress,
    required this.isOver,
  });

  final double progress;
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999.r),
        child: SizedBox(
          height: 7.h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: MealLogColors.inputBorder(context)),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: clamped,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOver
                            ? [
                                MealLogColors.errorText(context)
                                    .withValues(alpha: 0.75),
                                MealLogColors.errorText(context),
                              ]
                            : [
                                AppTheme.darkGold,
                                AppTheme.goldColor,
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
}

class _GuidanceLine extends StatelessWidget {
  const _GuidanceLine({required this.guidance});

  final MealCalorieBarGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final accent = _tone(context, guidance.tone);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Icon(_icon(guidance.tone), size: 14.sp, color: accent),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            guidance.message,
            style: MealLogTypography.caption(
              context,
              color: MealLogColors.primaryText(context),
            ).copyWith(fontSize: 11.sp, height: 1.4),
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Color _tone(BuildContext context, MealInsightTone tone) {
    switch (tone) {
      case MealInsightTone.success:
        return MealLogColors.successText(context);
      case MealInsightTone.warning:
        return MealLogColors.errorText(context);
      case MealInsightTone.tip:
      case MealInsightTone.info:
        return MealLogColors.accent(context);
    }
  }

  static IconData _icon(MealInsightTone tone) {
    switch (tone) {
      case MealInsightTone.success:
        return LucideIcons.checkCircle;
      case MealInsightTone.warning:
        return LucideIcons.alertTriangle;
      case MealInsightTone.tip:
        return LucideIcons.sparkles;
      case MealInsightTone.info:
        return LucideIcons.lightbulb;
    }
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFat,
    required this.consumedCalories,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    required this.referenceHint,
    required this.totals,
    required this.showChart,
    required this.onToggleChart,
  });

  final double consumedProtein;
  final double consumedCarbs;
  final double consumedFat;
  final double consumedCalories;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;
  final String referenceHint;
  final Map<String, double> totals;
  final bool showChart;
  final VoidCallback onToggleChart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, color: MealLogColors.inputBorder(context)),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  showChart ? 'توزیع کالری ماکرو' : 'دریافتی ماکرو',
                  style: MealLogTypography.sectionTitle(context).copyWith(
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleChart,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Icon(
                      showChart ? LucideIcons.activity : LucideIcons.pieChart,
                      size: 16.sp,
                      color: MealLogColors.accent(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (showChart)
            _MacroPie(
              protein: consumedProtein,
              carbs: consumedCarbs,
              fat: consumedFat,
              calories: consumedCalories,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _MacroRing(
                    label: 'پروتئین',
                    consumed: consumedProtein,
                    target: proteinTarget,
                    color: AppTheme.proteinColor,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _MacroRing(
                    label: 'کربوهیدرات',
                    consumed: consumedCarbs,
                    target: carbsTarget,
                    color: AppTheme.carbsColor,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _MacroRing(
                    label: 'چربی',
                    consumed: consumedFat,
                    target: fatTarget,
                    color: AppTheme.fatColor,
                  ),
                ),
              ],
            ),
          if ((totals['fiber'] ?? 0) > 0.05 ||
              (totals['sugar'] ?? 0) > 0.05 ||
              (totals['sodium'] ?? 0) > 0.05) ...[
            SizedBox(height: 10.h),
            _MicroWrap(totals: totals),
          ],
          SizedBox(height: 10.h),
          Text(
            referenceHint,
            style: MealLogTypography.caption(
              context,
              color: MealLogColors.mutedText(context),
              fontWeight: FontWeight.w500,
            ).copyWith(fontSize: 10.sp, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _MacroRing extends StatelessWidget {
  const _MacroRing({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  final String label;
  final double consumed;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final over = target > 0 && consumed > target;

    return Column(
      children: [
        SizedBox(
          width: 56.w,
          height: 56.w,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                painter: _RingPainter(
                  progress: value,
                  color: over ? MealLogColors.errorText(context) : color,
                  track: MealLogColors.inputBorder(context),
                ),
                child: Center(
                  child: Text(
                    MealLogUtils.convertToPersianNumbers(
                      '${consumed.round()}/${target.round()}',
                    ),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: MealLogColors.primaryText(context),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: MealLogTypography.caption(
            context,
            color: MealLogColors.secondaryText(context),
            fontWeight: FontWeight.w700,
          ).copyWith(fontSize: 10.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'گرم',
          style: MealLogTypography.caption(
            context,
            color: MealLogColors.hintText(context),
            fontWeight: FontWeight.w500,
          ).copyWith(fontSize: 9.sp),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 3;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.track != track;
}

class _MacroPie extends StatelessWidget {
  const _MacroPie({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
  });

  final double protein;
  final double carbs;
  final double fat;
  final double calories;

  @override
  Widget build(BuildContext context) {
    final pCal = protein * 4;
    final cCal = carbs * 4;
    final fCal = fat * 9;
    final total = pCal + cCal + fCal;

    if (total <= 0) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Text(
          'هنوز غذایی ثبت نشده',
          textAlign: TextAlign.center,
          style: MealLogTypography.caption(
            context,
            color: MealLogColors.mutedText(context),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140.h,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 28,
                sections: [
                  PieChartSectionData(
                    color: AppTheme.proteinColor,
                    value: pCal,
                    title: '${((pCal / total) * 100).round()}٪',
                    radius: 36,
                    titleStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: AppTheme.carbsColor,
                    value: cCal,
                    title: '${((cCal / total) * 100).round()}٪',
                    radius: 36,
                    titleStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: AppTheme.fatColor,
                    value: fCal,
                    title: '${((fCal / total) * 100).round()}٪',
                    radius: 36,
                    titleStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                MealLogUtils.convertToPersianNumbers(
                  '${calories.round()} کالری',
                ),
                style: MealLogTypography.sectionTitle(context).copyWith(
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 8.h),
              _legend(context, 'پروتئین', AppTheme.proteinColor),
              _legend(context, 'کربوهیدرات', AppTheme.carbsColor),
              _legend(context, 'چربی', AppTheme.fatColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, String label, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: MealLogTypography.caption(context).copyWith(fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}

class _MicroWrap extends StatelessWidget {
  const _MicroWrap({required this.totals});

  final Map<String, double> totals;

  @override
  Widget build(BuildContext context) {
    final items = <(String, double, String)>[
      ('فیبر', totals['fiber'] ?? 0, 'g'),
      ('قند', totals['sugar'] ?? 0, 'g'),
      ('سدیم', totals['sodium'] ?? 0, 'mg'),
      ('پتاسیم', totals['potassium'] ?? 0, 'mg'),
    ].where((e) => e.$2 > 0.05).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      textDirection: TextDirection.rtl,
      children: items.map((item) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: MealLogColors.chipFill(context, selected: false),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: MealLogColors.chipBorder(context, selected: false),
            ),
          ),
          child: Text(
            MealLogUtils.convertToPersianNumbers(
              '${item.$1} ${item.$2.toStringAsFixed(item.$3 == 'mg' ? 0 : 1)}${item.$3}',
            ),
            style: MealLogTypography.caption(context).copyWith(fontSize: 9.sp),
          ),
        );
      }).toList(),
    );
  }
}
