import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Helper class for showing common dialogs
class DialogHelpers {
  /// Show error dialog
  static void showError(
    BuildContext context,
    String message, {
    String title = 'خطا',
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: AppTheme.errorColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppTheme.errorColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'باشه',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.goldColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show success dialog
  static void showSuccess(
    BuildContext context,
    String message, {
    String title = 'موفقیت',
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: AppTheme.successColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppTheme.successColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'باشه',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.goldColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show network error dialog
  static void showNetworkError(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        title: Text(
          'خطا در اتصال',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'لطفاً اتصال اینترنت خود را بررسی کنید و دوباره تلاش کنید.',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textSecondary,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'باشه',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.goldColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

