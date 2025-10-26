import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NutritionChartToggle extends StatelessWidget {
  const NutritionChartToggle({
    required this.showNutritionChart,
    required this.onToggle,
    super.key,
  });
  final bool showNutritionChart;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Toggle button
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber[700]!.withValues(alpha: 0.1),
                  Colors.amber[700]!.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: Colors.amber[700]!.withValues(alpha: 0.3),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15.r),
                onTap: onToggle,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.amber[700]?.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          showNutritionChart
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                          color: Colors.amber[700],
                          size: 20.sp,
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
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        showNutritionChart
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        color: Colors.amber[700],
                        size: 20.sp,
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
