import 'package:flutter/material.dart';
import 'nutrition_tag.dart';

class DailyNutritionBarMealPlanBuilder extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  const DailyNutritionBarMealPlanBuilder({
    Key? key,
    required this.calories,
    required this.protein,
    required this.carbs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.amber[700]!.withOpacity(0.3),
          width: 1.5,
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
