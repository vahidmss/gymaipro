import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class AppStatusAction {
  const AppStatusAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
}

class AppStatusCard extends StatelessWidget {
  const AppStatusCard({
    required this.icon,
    required this.title,
    required this.description,
    this.overlay = false,
    this.badgeText,
    this.showLoading = false,
    this.actions = const <AppStatusAction>[],
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool overlay;
  final String? badgeText;
  final bool showLoading;
  final List<AppStatusAction> actions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.goldColor, size: 32.sp),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              color: isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.78)
                  : AppTheme.lightTextSecondary,
            ),
          ),
          if (badgeText != null && badgeText!.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              badgeText!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.goldColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (showLoading) ...[
            SizedBox(height: 14.h),
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppTheme.goldColor,
              ),
            ),
          ],
          if (actions.isNotEmpty) SizedBox(height: 16.h),
          for (var i = 0; i < actions.length; i++) ...[
            SizedBox(
              width: double.infinity,
              child: actions[i].primary
                  ? FilledButton(
                      onPressed: actions[i].onPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: AppTheme.veryDarkBackground,
                      ),
                      child: Text(actions[i].label),
                    )
                  : OutlinedButton(
                      onPressed: actions[i].onPressed,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.goldColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(actions[i].label),
                    ),
            ),
            if (i != actions.length - 1) SizedBox(height: 8.h),
          ],
        ],
      ),
    );

    if (!overlay) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: card,
        ),
      );
    }

    return ColoredBox(
      color: isDark
          ? const Color(0xFF101010).withValues(alpha: 0.86)
          : AppTheme.darkTextColor.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: card,
        ),
      ),
    );
  }
}
