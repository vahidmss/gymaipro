import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/utils/responsive_dialog_utils.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/theme/app_theme.dart';

class SubstituteFoodDialog extends StatelessWidget {
  const SubstituteFoodDialog({
    required this.foodItem,
    required this.allFoods,
    super.key,
  });

  final FoodLogItem foodItem;
  final List<Food> allFoods;

  @override
  Widget build(BuildContext context) {
    final alternatives = foodItem.alternatives ?? [];
    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: ResponsiveDialogUtils.getStandardInsetPadding(context),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveDialogUtils.getStandardMaxWidth(context),
        ),
        padding: ResponsiveDialogUtils.getStandardDialogPadding(context),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(
            ResponsiveDialogUtils.getStandardBorderRadius(context),
          ),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'انتخاب جایگزین',
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18.sp),
            ),
            SizedBox(height: 20.h),
            ...alternatives.map((alt) {
              final altFood = allFoods.firstWhere(
                (f) => f.id == (alt['food_id'] as int),
                orElse: () =>
                    MealLogUtils.createDefaultFood(alt['food_id'] as int),
              );
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(alt),
                child: Card(
                  color: context.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8.h),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.asset(
                            'images/gymaifoodplaceholder.png',
                            width: 44.w,
                            height: 44.h,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 44.w,
                              height: 44.h,
                              color: Colors.grey.withValues(alpha: 0.3),
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                altFood.title,
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${alt['amount']} گرم',
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.swap_horiz,
                          color: AppTheme.goldColor,
                          size: 22.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
