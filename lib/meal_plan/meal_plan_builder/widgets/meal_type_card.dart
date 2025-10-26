import 'package:flutter/material.dart';
// کارت انتخاب نوع وعده (Meal Type Card) مخصوص صفحه ساخت برنامه غذایی
// استفاده در MealPlanBuilderScreen
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MealTypeCardMealPlanBuilder extends StatelessWidget {
  const MealTypeCardMealPlanBuilder({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 0.7),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 2.r,
              offset: Offset(0.w, 1.h),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(icon, size: 16.sp, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.amber[100],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
