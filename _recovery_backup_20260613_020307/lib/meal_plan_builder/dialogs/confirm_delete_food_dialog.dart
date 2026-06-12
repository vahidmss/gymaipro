import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ConfirmDeleteFoodDialogMealPlanBuilder extends StatelessWidget {
  const ConfirmDeleteFoodDialogMealPlanBuilder({
    required this.foodTitle,
    required this.isSupplement,
    super.key,
  });

  final String foodTitle;
  final bool isSupplement;

  static Future<bool?> show(
    BuildContext context, {
    required String foodTitle,
    required bool isSupplement,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteFoodDialogMealPlanBuilder(
        foodTitle: foodTitle,
        isSupplement: isSupplement,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: isDark
            ? context.backgroundColor
            : context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
          ),
        ),
        title: Text(
          'حذف ${isSupplement ? 'مکمل' : 'غذا'}',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark ? AppTheme.goldColor : context.textColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'آیا از حذف "$foodTitle" اطمینان دارید؟',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark
                ? AppTheme.goldColor.withValues(alpha: 0.8)
                : context.textColor.withValues(alpha: 0.8),
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.goldColor,
            ),
            child: Text(
              'انصراف',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
            child: Text(
              'حذف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

