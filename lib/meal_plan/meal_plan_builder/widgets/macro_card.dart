// کارت ماکرو (Macro) مخصوص صفحه ساخت برنامه غذایی
// استفاده در MealPlanBuilderScreen

import 'package:flutter/material.dart';

class MacroCardMealPlanBuilder extends StatelessWidget {
  final String title;
  final String amount;
  final String percent;
  final Color color;

  const MacroCardMealPlanBuilder({
    Key? key,
    required this.title,
    required this.amount,
    required this.percent,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 8,
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              color: color.withOpacity(0.5),
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }
}
