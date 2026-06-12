import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_meal_log.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/services/fitness_calculator.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:responsive_framework/responsive_framework.dart';

class DailyCalorieSummary extends StatefulWidget {
  const DailyCalorieSummary({
    required this.meals,
    required this.allFoods,
    required this.profileData,
    super.key,
  });

  final List<FoodMealLog> meals;
  final List<Food> allFoods;
  final Map<String, dynamic>? profileData;

  @override
  State<DailyCalorieSummary> createState() => _DailyCalorieSummaryState();
}

class _DailyCalorieSummaryState extends State<DailyCalorieSummary> {
  bool _isExpanded = false;
  bool _showChart = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // محاسبه کالری مجاز روزانه (TDEE)
    final dailyCalorieTarget = _calculateDailyCalorieTarget();

    // محاسبه totals از غذاهای ثبت شده
    final totals = MealLogUtils.calculateTotals(widget.meals, widget.allFoods);
    final consumedCalories = totals['calories'] ?? 0;
    final consumedProtein = totals['protein'] ?? 0;
    final consumedCarbs = totals['carbs'] ?? 0;
    final consumedFat = totals['fat'] ?? 0;

    // محاسبه درصد مصرف
    final progressPercentage = dailyCalorieTarget > 0
        ? (consumedCalories / dailyCalorieTarget).clamp(0.0, 1.0)
        : 0.0;

    // کالری باقیمانده
    final remainingCalories = (dailyCalorieTarget - consumedCalories).clamp(
      0.0,
      double.infinity,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // استفاده از MediaQuery برای اندازه واقعی صفحه
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;

        // محاسبه responsive padding بر اساس اندازه واقعی
        final containerPadding = screenWidth > 600
            ? (screenWidth * 0.03).clamp(16.0, 24.0)
            : (screenWidth * 0.032).clamp(12.0, 16.0);

        // محاسبه responsive margin بر اساس اندازه واقعی
        final verticalMargin = screenWidth > 600 ? 12.0 : 8.0;
        final containerMargin = EdgeInsets.symmetric(
          horizontal: 0,
          vertical: verticalMargin,
        );

        // محاسبه responsive border radius بر اساس اندازه واقعی
        final borderRadius = screenWidth > 600 ? 20.0 : 16.0;

        return Container(
          margin: containerMargin,
          padding: EdgeInsets.all(containerPadding),
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
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.15 : 0.35,
                ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ردیف اول: کالری مجاز و باقیمانده در یک خط + دکمه تغییر نمایش
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'کالری مجاز روزانه: ',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textColor.withValues(alpha: 0.7),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          dailyCalorieTarget.toStringAsFixed(0),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: context.textColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'کالری باقیمانده: ',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor.withValues(alpha: 0.7),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        remainingCalories.toStringAsFixed(0),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 8.w),
                  // دکمه تغییر نمایش
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showChart = !_showChart;
                        });
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppTheme.goldColor.withValues(alpha: 0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Icon(
                          _showChart
                              ? LucideIcons.barChart3
                              : LucideIcons.pieChart,
                          color: AppTheme.goldColor,
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // نمایش نمودار یا progress bar
              if (_showChart)
                _buildNutritionChart(
                  consumedCalories,
                  consumedProtein,
                  consumedCarbs,
                  consumedFat,
                  isDark,
                )
              else
                // Progress Bar با نشانگر
                _buildProgressBar(
                  progressPercentage,
                  consumedCalories,
                  dailyCalorieTarget,
                  isDark,
                ),

              SizedBox(height: 8.h),

              // فلش و بخش ماکرو
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      color: isDark ? AppTheme.goldColor : context.textColor,
                      size: 18.sp,
                    ),
                  ],
                ),
              ),

              // بخش ماکرو و تیپس (قابل باز شدن)
              if (_isExpanded) ...[
                SizedBox(height: 8.h),
                Divider(color: context.separatorColor, thickness: 1),
                SizedBox(height: 8.h),
                _buildMacroSection(
                  context,
                  consumedProtein,
                  consumedCarbs,
                  consumedFat,
                  isDark,
                ),
                SizedBox(height: 8.h),
                _buildTip(context, isDark),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutritionChart(
    double consumedCalories,
    double consumedProtein,
    double consumedCarbs,
    double consumedFat,
    bool isDark,
  ) {
    final double proteinCalories = consumedProtein * 4;
    final double carbsCalories = consumedCarbs * 4;
    final double fatCalories = consumedFat * 9;
    final double totalMacroCalories =
        proteinCalories + carbsCalories + fatCalories;

    if (totalMacroCalories == 0) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? context.backgroundColor : context.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.pieChart,
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.6 : 0.5),
              size: 48.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              'هیچ غذایی اضافه نشده',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor.withValues(alpha: 0.7),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      );
    }

    final double proteinPercent = (proteinCalories / totalMacroCalories) * 100;
    final double carbsPercent = (carbsCalories / totalMacroCalories) * 100;
    final double fatPercent = (fatCalories / totalMacroCalories) * 100;

    return Container(
      padding: EdgeInsets.all(12.w),
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
        borderRadius: BorderRadius.circular(16.r),
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
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 120.h,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: AppTheme.proteinColor,
                      value: proteinPercent,
                      title: '${proteinPercent.toStringAsFixed(1)}%',
                      radius: 40,
                      titleStyle: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextColor
                            : AppTheme.lightTextColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                    PieChartSectionData(
                      color: AppTheme.carbsColor,
                      value: carbsPercent,
                      title: '${carbsPercent.toStringAsFixed(1)}%',
                      radius: 40,
                      titleStyle: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextColor
                            : AppTheme.lightTextColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                    PieChartSectionData(
                      color: AppTheme.fatColor,
                      value: fatPercent,
                      title: '${fatPercent.toStringAsFixed(1)}%',
                      radius: 40,
                      titleStyle: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextColor
                            : AppTheme.lightTextColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 25,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldColor.withValues(alpha: 0.15),
                              AppTheme.goldColor.withValues(alpha: 0.08),
                            ],
                          ),
                    color: isDark
                        ? AppTheme.goldColor.withValues(alpha: 0.2)
                        : null,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(
                        alpha: isDark ? 0.4 : 0.3,
                      ),
                      width: 1.w,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        consumedCalories.toStringAsFixed(0),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'کالری کل',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppTheme.goldColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildMacroCard(
                        'پروتئین',
                        '${consumedProtein.toStringAsFixed(1)}g',
                        proteinPercent.toStringAsFixed(1),
                        AppTheme.proteinColor,
                        isDark,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: _buildMacroCard(
                        'کربوهیدرات',
                        '${consumedCarbs.toStringAsFixed(1)}g',
                        carbsPercent.toStringAsFixed(1),
                        AppTheme.carbsColor,
                        isDark,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: _buildMacroCard(
                        'چربی',
                        '${consumedFat.toStringAsFixed(1)}g',
                        fatPercent.toStringAsFixed(1),
                        AppTheme.fatColor,
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    String title,
    String amount,
    String percent,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.08),
                ],
              ),
        color: isDark ? color.withValues(alpha: 0.15) : null,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.25),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amount,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.1,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: color.withValues(alpha: isDark ? 0.9 : 0.8),
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            '$percent%',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: color.withValues(alpha: isDark ? 0.8 : 0.7),
              fontSize: 7.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    double progress,
    double consumed,
    double target,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final clampedProgress = progress.clamp(0.0, 1.0);
        final progressWidth = barWidth * clampedProgress;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            Stack(
              children: [
                // Background
                Container(
                  height: 8.h,
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                // Progress fill (از چپ به راست)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    height: 8.h,
                    width: progressWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.darkGold, AppTheme.goldColor],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8.r),
                        bottomLeft: Radius.circular(8.r),
                        topRight: clampedProgress < 1.0
                            ? Radius.zero
                            : Radius.circular(8.r),
                        bottomRight: clampedProgress < 1.0
                            ? Radius.zero
                            : Radius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // مقدار استفاده شده زیر progress bar
            SizedBox(height: 10.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.flame,
                        size: 12.sp,
                        color: AppTheme.goldColor,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'مصرف شده: ',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor.withValues(alpha: 0.7),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        consumed.toStringAsFixed(0),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        ' کالری',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor.withValues(alpha: 0.6),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTip(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        'کالری مجاز روزانه بر اساس محاسبات شما برای تثبیت وزن است، نه کاهش یا افزایش وزن.',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: context.textColor.withValues(alpha: 0.8),
          fontSize: 10.sp,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildMacroSection(
    BuildContext context,
    double consumedProtein,
    double consumedCarbs,
    double consumedFat,
    bool isDark,
  ) {
    // محاسبه نیازهای ماکرو
    final macroTargets = _calculateMacroTargets();
    final proteinTarget = macroTargets['protein'] ?? 0;
    final carbsTarget = macroTargets['carbs'] ?? 0;
    final fatTarget = macroTargets['fat'] ?? 0;

    // محاسبه درصد مصرف
    final proteinProgress = proteinTarget > 0
        ? (consumedProtein / proteinTarget).clamp(0.0, 1.0)
        : 0.0;
    final carbsProgress = carbsTarget > 0
        ? (consumedCarbs / carbsTarget).clamp(0.0, 1.0)
        : 0.0;
    final fatProgress = fatTarget > 0
        ? (consumedFat / fatTarget).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'دریافتی ماکرو',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark ? AppTheme.goldColor : context.textColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildCircularMacroCard(
                context,
                'پروتئین',
                consumedProtein,
                proteinTarget,
                'گرم',
                AppTheme.proteinColor,
                proteinProgress,
                isDark,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildCircularMacroCard(
                context,
                'کربوهیدرات',
                consumedCarbs,
                carbsTarget,
                'گرم',
                AppTheme.carbsColor,
                carbsProgress,
                isDark,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildCircularMacroCard(
                context,
                'چربی',
                consumedFat,
                fatTarget,
                'گرم',
                AppTheme.fatColor,
                fatProgress,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularMacroCard(
    BuildContext context,
    String label,
    double consumed,
    double target,
    String unit,
    Color color,
    double progress,
    bool isDark,
  ) {
    final circleSize = ResponsiveValue(
      context,
      defaultValue: 56.w,
      conditionalValues: [
        Condition.smallerThan(name: MOBILE, value: 52.w),
        Condition.largerThan(name: TABLET, value: 60.w),
      ],
    ).value;

    final strokeWidth = ResponsiveValue(
      context,
      defaultValue: 1.8.w,
      conditionalValues: [
        Condition.smallerThan(name: MOBILE, value: 1.5.w),
        Condition.largerThan(name: TABLET, value: 2.w),
      ],
    ).value;

    // اگر progress = 0 باشد، یک border ثابت نمایش می‌دهیم
    final hasProgress = progress > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // دایره با progress bar
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasProgress
                ? SweepGradient(
                    startAngle: 3.14159, // شروع از سمت راست (180 درجه)
                    endAngle: 3.14159 + (2 * 3.14159 * progress),
                    colors: [
                      AppTheme.goldColor.withValues(alpha: 0.25),
                      AppTheme.goldColor.withValues(alpha: 0.25),
                      AppTheme.goldColor.withValues(alpha: 0.35),
                      AppTheme.goldColor.withValues(alpha: 0.55),
                      AppTheme.goldColor.withValues(alpha: 0.75),
                      AppTheme.goldColor,
                      AppTheme.goldColor.withValues(alpha: 0.75),
                      AppTheme.goldColor.withValues(alpha: 0.55),
                      AppTheme.goldColor.withValues(alpha: 0.35),
                      AppTheme.goldColor.withValues(alpha: 0.25),
                      AppTheme.goldColor.withValues(alpha: 0.25),
                    ],
                    stops: const [
                      0.0,
                      0.05,
                      0.2,
                      0.35,
                      0.45,
                      0.5,
                      0.55,
                      0.65,
                      0.8,
                      0.95,
                      1.0,
                    ],
                  )
                : null,
            border: hasProgress
                ? null
                : Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.25),
                    width: strokeWidth,
                  ),
          ),
          child: Container(
            margin: EdgeInsets.all(strokeWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.cardColor,
                        color.withValues(alpha: 0.05),
                      ],
                    ),
              color: Theme.of(context).brightness == Brightness.dark
                  ? context.backgroundColor
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // مقدار مصرف شده / مقدار مورد نیاز
                Text(
                  MealLogUtils.convertToPersianNumbers(
                    '${consumed.toStringAsFixed(0)}/${target.toStringAsFixed(0)}',
                  ),
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: ResponsiveValue(
                      context,
                      defaultValue: 12.sp,
                      conditionalValues: [
                        Condition.smallerThan(name: MOBILE, value: 10.sp),
                        Condition.largerThan(name: TABLET, value: 12.sp),
                      ],
                    ).value,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 5.h),
        // عنوان زیر دایره
        Text(
          label,
          style: TextStyle(
            color: context.textColor.withValues(alpha: 0.9),
            fontSize: ResponsiveValue(
              context,
              defaultValue: 10.sp,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 9.sp),
                Condition.largerThan(name: TABLET, value: 11.sp),
              ],
            ).value,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 1.5.h),
        // واحد زیر عنوان
        Text(
          unit,
          style: TextStyle(
            color: isDark
                ? AppTheme.goldColor
                : context.textColor.withValues(alpha: 0.7),
            fontSize: ResponsiveValue(
              context,
              defaultValue: 9.sp,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 8.sp),
                Condition.largerThan(name: TABLET, value: 10.sp),
              ],
            ).value,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.05,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Map<String, double> _calculateMacroTargets() {
    if (widget.profileData == null) {
      // مقادیر پیش‌فرض بر اساس جنسیت (فرض: مرد با وزن 70 کیلوگرم)
      return {'protein': 154.0, 'carbs': 250.0, 'fat': 65.0};
    }

    final height =
        double.tryParse((widget.profileData!['height'] as String?) ?? '') ?? 0;
    final latestWeight = widget.profileData!['latest_weight'] as double?;
    final weight =
        latestWeight ??
        double.tryParse((widget.profileData!['weight'] as String?) ?? '') ??
        0;
    final birthDateStr = widget.profileData!['birth_date'] as String?;
    final isMale = (widget.profileData!['gender'] as String?) == 'male';

    // محاسبه سن
    int age = 25;
    if (birthDateStr != null && birthDateStr.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(birthDateStr);
        final now = DateTime.now();
        age =
            now.year -
            birthDate.year -
            ((now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day))
                ? 1
                : 0);
      } catch (_) {
        age = 25;
      }
    }

    // اگر اطلاعات کافی نداریم، مقدار پیش‌فرض برگردان
    if (height <= 0 || weight <= 0 || age <= 0) {
      return {'protein': 120.0, 'carbs': 250.0, 'fat': 65.0};
    }

    // محاسبه TDEE با استفاده از activity_level واقعی
    final bmr = FitnessCalculator.calculateBMR(weight, height, age, isMale);
    final activityLevelStr =
        (widget.profileData!['activity_level'] as String?) ?? 'moderate';
    final activityLevel = activityLevelStr.toActivityLevel();
    final tdee = FitnessCalculator.calculateTDEE(bmr, activityLevel);

    // محاسبه ماکروها با فرمول‌های علمی دقیق بر اساس جنسیت
    // پروتئین: تفاوت جنسیتی در نیاز پروتئین
    // مردان: 2-2.2 گرم/کیلوگرم (برای ورزشکاران)
    // زنان: 1.8-2 گرم/کیلوگرم (نیاز کمتر به دلیل تفاوت متابولیسم)
    final proteinTarget = isMale ? weight * 2.2 : weight * 1.9;

    // کربوهیدرات: تفاوت جنسیتی در نیاز کربوهیدرات
    // مردان: 45-50% از TDEE (نیاز بیشتر به انرژی)
    // زنان: 40-45% از TDEE (نیاز کمتر به کربوهیدرات)
    final carbsPercentage = isMale ? 0.47 : 0.42;
    final carbsTarget = (tdee * carbsPercentage) / 4.0;

    // چربی: تفاوت جنسیتی در نیاز چربی
    // مردان: 20-25% از TDEE
    // زنان: 25-30% از TDEE (نیاز بیشتر برای سلامت هورمون‌ها و سیکل قاعدگی)
    final fatPercentage = isMale ? 0.23 : 0.28;
    final fatTarget = (tdee * fatPercentage) / 9.0;

    return {'protein': proteinTarget, 'carbs': carbsTarget, 'fat': fatTarget};
  }

  double _calculateDailyCalorieTarget() {
    if (widget.profileData == null) return 2000.0; // مقدار پیش‌فرض

    final height =
        double.tryParse((widget.profileData!['height'] as String?) ?? '') ?? 0;
    // استفاده از آخرین وزن ثبت شده یا وزن پروفایل
    final latestWeight = widget.profileData!['latest_weight'] as double?;
    final weight =
        latestWeight ??
        double.tryParse((widget.profileData!['weight'] as String?) ?? '') ??
        0;
    final birthDateStr = widget.profileData!['birth_date'] as String?;
    final isMale = (widget.profileData!['gender'] as String?) == 'male';

    // محاسبه سن
    int age = 25;
    if (birthDateStr != null && birthDateStr.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(birthDateStr);
        final now = DateTime.now();
        age =
            now.year -
            birthDate.year -
            ((now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day))
                ? 1
                : 0);
      } catch (_) {
        age = 25;
      }
    }

    // اگر اطلاعات کافی نداریم، مقدار پیش‌فرض برگردان
    if (height <= 0 || weight <= 0 || age <= 0) {
      return 2000.0;
    }

    // محاسبه BMR
    final bmr = FitnessCalculator.calculateBMR(weight, height, age, isMale);

    // محاسبه TDEE با استفاده از activity_level واقعی از پروفایل
    final activityLevelStr =
        (widget.profileData!['activity_level'] as String?) ?? 'moderate';
    final activityLevel = activityLevelStr.toActivityLevel();
    final tdee = FitnessCalculator.calculateTDEE(bmr, activityLevel);

    return tdee;
  }
}
