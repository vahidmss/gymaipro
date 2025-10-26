import 'package:flutter/material.dart';
// کارت ماکرو (Macro) مخصوص صفحه ساخت برنامه غذایی
// استفاده در MealPlanBuilderScreen
 import 'package:flutter_screenutil/flutter_screenutil.dart';
class MacroCardMealPlanBuilder extends StatelessWidget {
  const MacroCardMealPlanBuilder({
    required this.title,
    required this.amount,
    required this.percent,
    required this.color,
    super.key,
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
            style: TextStyle(color: color.withValues(alpha: 0.1), fontSize: 8),
          ),
          Text(
            '$percent%',
            style: TextStyle(color: color.withValues(alpha: 0.1), fontSize: 7),
          ),
        ],
      ),
    );
  }
}
