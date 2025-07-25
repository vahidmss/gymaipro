import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

class NutritionChart extends StatelessWidget {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final bool showChart;
  final VoidCallback onToggle;

  const NutritionChart({
    Key? key,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.showChart,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bottom info bar (clickable)
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2C1810),
                  Color(0xFF3D2317),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: Colors.amber[700]!.withOpacity(0.3),
                width: 1.5,
              ),
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
                          Icon(LucideIcons.flame,
                              color: Colors.amber[300], size: 16),
                          const SizedBox(width: 3),
                          Text(
                            'کالری: ',
                            style: TextStyle(
                              color: Colors.amber[200],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            totalCalories.toStringAsFixed(0),
                            style: TextStyle(
                              color: Colors.amber[100],
                              fontSize: 13,
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
                          Icon(LucideIcons.dumbbell,
                              color: Colors.blue[300], size: 16),
                          const SizedBox(width: 3),
                          Text(
                            'پروتئین: ',
                            style: TextStyle(
                              color: Colors.amber[200],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            totalProtein.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.amber[100],
                              fontSize: 13,
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
                          Icon(LucideIcons.wheat,
                              color: Colors.orange[300], size: 16),
                          const SizedBox(width: 3),
                          Text(
                            'کربو: ',
                            style: TextStyle(
                              color: Colors.amber[200],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            totalCarbs.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.amber[100],
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Chart toggle icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[700]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    showChart ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                    color: Colors.amber[300],
                    size: 20,
                  ),
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C1810),
            Color(0xFF3D2317),
            Color(0xFF4A2C1A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber[700]!.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[700]?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.pieChart,
                  color: Colors.amber[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'خلاصه تغذیه روزانه',
                style: TextStyle(
                  color: Colors.amber[200],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Pie chart
          SizedBox(
            height: 200,
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
                          color: Colors.blue[400]!,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: totalCarbs,
                          title: 'کربوهیدرات',
                          color: Colors.green[400]!,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: totalFat,
                          title: 'چربی',
                          color: Colors.orange[400]!,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
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
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('پروتئین', Colors.blue[400]!,
                          totalProtein.toStringAsFixed(1)),
                      const SizedBox(height: 8),
                      _buildLegendItem('کربوهیدرات', Colors.green[400]!,
                          totalCarbs.toStringAsFixed(1)),
                      const SizedBox(height: 8),
                      _buildLegendItem('چربی', Colors.orange[400]!,
                          totalFat.toStringAsFixed(1)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber[700]?.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'کالری: ${totalCalories.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.amber[200],
                            fontSize: 14,
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ${value}g',
            style: TextStyle(
              color: Colors.amber[100],
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
