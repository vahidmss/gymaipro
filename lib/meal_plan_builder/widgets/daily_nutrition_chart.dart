import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DailyNutritionChartMealPlanBuilder extends StatelessWidget {
  const DailyNutritionChartMealPlanBuilder({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    super.key,
  });

  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  @override
  Widget build(BuildContext context) {
    final double proteinCalories = totalProtein * 4;
    final double carbsCalories = totalCarbs * 4;
    final double fatCalories = totalFat * 9;
    final double totalMacroCalories =
        proteinCalories + carbsCalories + fatCalories;

    if (totalMacroCalories == 0) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.pieChart,
              color: AppTheme.goldColor.withValues(alpha: 0.6),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'هیچ غذایی اضافه نشده',
              style: TextStyle(
                color: context.textColor.withValues(alpha: 0.7),
                fontSize: 16,
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
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldColor.withValues(alpha: 0.05),
            AppTheme.goldColor.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.25),
            blurRadius: 12.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  LucideIcons.pieChart,
                  color: AppTheme.goldColor,
                  size: 24.sp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'خلاصه تغذیه روزانه',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 150.h,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: AppTheme.proteinColor,
                          value: proteinPercent,
                          title: '${proteinPercent.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        PieChartSectionData(
                          color: AppTheme.carbsColor,
                          value: carbsPercent,
                          title: '${carbsPercent.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        PieChartSectionData(
                          color: AppTheme.fatColor,
                          value: fatPercent,
                          title: '${fatPercent.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                      ],
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.goldColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            totalCalories.toStringAsFixed(0),
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'کالری کل',
                            style: TextStyle(
                              color: AppTheme.goldColor,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MacroCard(
                            title: 'پروتئین',
                            amount: '${totalProtein.toStringAsFixed(1)}g',
                            percent: proteinPercent.toStringAsFixed(1),
                            color: AppTheme.proteinColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroCard(
                            title: 'کربوهیدرات',
                            amount: '${totalCarbs.toStringAsFixed(1)}g',
                            percent: carbsPercent.toStringAsFixed(1),
                            color: AppTheme.carbsColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroCard(
                            title: 'چربی',
                            amount: '${totalFat.toStringAsFixed(1)}g',
                            percent: fatPercent.toStringAsFixed(1),
                            color: AppTheme.fatColor,
                          ),
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
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.title,
    required this.amount,
    required this.percent,
    required this.color,
  });

  final String title;
  final String amount;
  final String percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 8),
          ),
          Text(
            '$percent%',
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 7),
          ),
        ],
      ),
    );
  }
}
