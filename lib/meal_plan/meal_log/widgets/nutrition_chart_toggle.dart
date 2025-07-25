import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NutritionChartToggle extends StatelessWidget {
  final bool showNutritionChart;
  final VoidCallback onToggle;

  const NutritionChartToggle({
    super.key,
    required this.showNutritionChart,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Toggle button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber[700]!.withValues(alpha: 0.1),
                  Colors.amber[700]!.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border:
                  Border.all(color: Colors.amber[700]!.withValues(alpha: 0.3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber[700]?.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          showNutritionChart
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                          color: Colors.amber[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          showNutritionChart
                              ? 'مخفی کردن نمودار تغذیه'
                              : 'نمایش نمودار تغذیه',
                          style: TextStyle(
                            color: Colors.amber[200],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        showNutritionChart
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
