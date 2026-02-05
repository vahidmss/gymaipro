import 'package:flutter/material.dart';
// تگ تغذیه (Nutrition Tag) مخصوص صفحه ساخت برنامه غذایی
// استفاده در MealPlanBuilderScreen
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NutritionTagMealPlanBuilder extends StatelessWidget {
  const NutritionTagMealPlanBuilder({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
