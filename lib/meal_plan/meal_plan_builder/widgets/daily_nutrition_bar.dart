import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_plan/meal_plan_builder/widgets/nutrition_tag.dart';

class DailyNutritionBarMealPlanBuilder extends StatelessWidget {
  const DailyNutritionBarMealPlanBuilder({
    required this.calories,
    required this.protein,
    required this.carbs,
    super.key,
  });
  final double calories;
  final double protein;
  final double carbs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C1810), Color(0xFF3D2317)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16.r,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(
          color: Colors.amber[700]!.withValues(alpha: 0.1),
          width: 1.5.w,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                NutritionTagMealPlanBuilder(
                  label: 'کالری:',
                  value: calories.toStringAsFixed(0),
                  color: Colors.red[300]!,
                ),
                NutritionTagMealPlanBuilder(
                  label: 'پروتئین:',
                  value: protein.toStringAsFixed(1),
                  color: Colors.blue[300]!,
                ),
                NutritionTagMealPlanBuilder(
                  label: 'کربو:',
                  value: carbs.toStringAsFixed(1),
                  color: Colors.orange[300]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
