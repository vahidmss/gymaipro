import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ErrorBoundaryWidget extends StatelessWidget {
  const ErrorBoundaryWidget({
    required this.child,
    this.onRetry,
    this.errorTitle = 'خطا در نمایش چت',
    this.errorMessage = 'لطفاً صفحه را مجدداً بارگذاری کنید',
    super.key,
  });

  final Widget child;
  final VoidCallback? onRetry;
  final String errorTitle;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e) {
          debugPrint('=== ERROR BOUNDARY: Error in build: $e ===');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.alertTriangle,
                  color: AppTheme.goldColor.withValues(alpha: 0.5),
                  size: 64.sp,
                ),
                const SizedBox(height: 16),
                Text(
                  errorTitle,
                  style: AppTheme.headingStyle.copyWith(fontSize: 16.sp),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: AppTheme.bodyStyle.copyWith(fontSize: 14.sp),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('تلاش مجدد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: AppTheme.textColor,
                    ),
                  ),
                ],
              ],
            ),
          );
        }
      },
    );
  }
}
