import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NutritionChart extends StatelessWidget {
  const NutritionChart({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.showChart,
    required this.onToggle,
    super.key,
  });
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final bool showChart;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!showChart)
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  // Nutrition summary
                  Expanded(
                    child: Row(
                      children: [
                        // Calories
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.flame,
                              color: Colors.amber[300],
                              size: 16.sp,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'کالری: ',
                              style: TextStyle(
                                color: Colors.amber[200],
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              totalCalories.toStringAsFixed(0),
                              style: TextStyle(
                                color: Colors.amber[100],
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Protein
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.dumbbell,
                              color: Colors.blue[300],
                              size: 16.sp,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'پروتئین: ',
                              style: TextStyle(
                                color: Colors.amber[200],
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              totalProtein.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.amber[100],
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Carbs
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.wheat,
                              color: Colors.orange[300],
                              size: 16.sp,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'کربو: ',
                              style: TextStyle(
                                color: Colors.amber[200],
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              totalCarbs.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.amber[100],
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chart toggle icon
                  Icon(
                    showChart ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                    color: const Color(0xFFD4AF37),
                    size: 22.sp,
                  ),
                ],
              ),
            ),
          ),

        // Nutrition Chart Overlay
        if (showChart)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20.r,
                  offset: Offset(0.w, 8.h),
                ),
              ],
            ),
            child: _buildDailyNutritionChart(),
          ),
      ],
    );
  }

  Widget _buildDailyNutritionChart() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.amber[700]?.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  LucideIcons.pieChart,
                  color: Colors.amber[700],
                  size: 20.sp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'خلاصه تغذیه روزانه',
                  style: TextStyle(
                    color: Colors.amber[200],
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.x,
                  color: const Color(0xFFD4AF37),
                  size: 20.sp,
                ),
                onPressed: onToggle,
                tooltip: 'بستن',
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Pie chart
          SizedBox(
            height: 200.h,
            child: Row(
              children: [
                // Chart
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: totalProtein,
                          title: 'پروتئین',
                          color: Colors.blue[400],
                          radius: 60,
                          titleStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: totalCarbs,
                          title: 'کربوهیدرات',
                          color: Colors.green[400],
                          radius: 60,
                          titleStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: totalFat,
                          title: 'چربی',
                          color: Colors.orange[400],
                          radius: 60,
                          titleStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(
                        'پروتئین',
                        Colors.blue[400]!,
                        totalProtein.toStringAsFixed(1),
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        'کربوهیدرات',
                        Colors.green[400]!,
                        totalCarbs.toStringAsFixed(1),
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        'چربی',
                        Colors.orange[400]!,
                        totalFat.toStringAsFixed(1),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.amber[700]?.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'کالری: ${totalCalories.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.amber[200],
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildLegendItem(String label, Color color, String value) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ${value}g',
            style: TextStyle(color: Colors.amber[100], fontSize: 12),
          ),
        ),
      ],
    );
  }
}
