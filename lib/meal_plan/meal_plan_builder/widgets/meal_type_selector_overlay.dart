import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_plan/meal_plan_builder/widgets/meal_type_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MealTypeSelectorOverlayMealPlanBuilder extends StatelessWidget {
  const MealTypeSelectorOverlayMealPlanBuilder({
    required this.onSelectType,
    required this.onClose,
    super.key,
  });
  final void Function(String) onSelectType;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Container(
              width: 220.w,
              margin: EdgeInsets.all(10.w),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12.r,
                    offset: Offset(0.w, 6.h),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with close button
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFD4AF37,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          LucideIcons.utensils,
                          color: const Color(0xFFD4AF37),
                          size: 14.sp,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'نوع وعده غذایی را انتخاب کنید',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Container(
                        width: 30.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            color: Colors.white70,
                            size: 14.sp,
                          ),
                          onPressed: onClose,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 260.h,
                    width: 200.w,
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 0.8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        MealTypeCardMealPlanBuilder(
                          title: 'صبحانه',
                          icon: LucideIcons.sunrise,
                          color: Colors.orange[400]!,
                          onTap: () => onSelectType('صبحانه'),
                        ),
                        MealTypeCardMealPlanBuilder(
                          title: 'ناهار',
                          icon: LucideIcons.sun,
                          color: Colors.green[400]!,
                          onTap: () => onSelectType('ناهار'),
                        ),
                        MealTypeCardMealPlanBuilder(
                          title: 'شام',
                          icon: LucideIcons.moon,
                          color: Colors.blue[400]!,
                          onTap: () => onSelectType('شام'),
                        ),
                        MealTypeCardMealPlanBuilder(
                          title: 'میان وعده',
                          icon: LucideIcons.coffee,
                          color: Colors.purple[400]!,
                          onTap: () => onSelectType('میان وعده'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
