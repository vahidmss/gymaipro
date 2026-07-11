import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/services/progress_analysis_limit_service.dart';
import 'package:gymaipro/ai/widgets/ai_hub_ui.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// رنگ accent بخش تحلیل پیشرفت
const Color kProgressAccent = AppTheme.proteinColor;

class ProgressAnalysisCard extends StatelessWidget {
  const ProgressAnalysisCard({
    required this.child,
    super.key,
    this.padding,
    this.accent = kProgressAccent,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = Color.lerp(context.separatorColor, accent, 0.42)!;

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: borderColor.withValues(alpha: isDark ? 0.72 : 0.62),
        ),
        boxShadow: [
          BoxShadow(
            color: context.headerShadowColor,
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ProgressPeriodChip extends StatelessWidget {
  const ProgressPeriodChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: selected
                ? kProgressAccent.withValues(alpha: isDark ? 0.16 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected
                  ? kProgressAccent.withValues(alpha: 0.75)
                  : context.separatorColor.withValues(alpha: 0.8),
              width: selected ? 1.5.w : 1.w,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: selected
                    ? kProgressAccent
                    : context.textSecondary.withValues(alpha: 0.85),
              ),
              SizedBox(height: 6.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: selected ? context.textColor : context.textSecondary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10.sp,
                  height: 1.2,
                  color: context.textSecondary.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressUsageBanner extends StatelessWidget {
  const ProgressUsageBanner({required this.stats, super.key});

  final ProgressAnalysisLimitStats stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNearLimit = !stats.hasSubscription && stats.remainingFree <= 1;
    final accent = stats.hasSubscription
        ? AppTheme.goldColor
        : isNearLimit
        ? AppTheme.fatColor
        : kProgressAccent;

    return ProgressAnalysisCard(
      accent: accent,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          AiHubIconBadge(
            icon: stats.hasSubscription
                ? Icons.workspace_premium_rounded
                : isNearLimit
                ? Icons.warning_amber_rounded
                : Icons.insights_rounded,
            gradientColors: aiHubAccentGradient(accent),
            size: 42.w,
            iconSize: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.hasSubscription
                      ? 'اشتراک فعال — تحلیل نامحدود'
                      : 'تحلیل رایگان: ${stats.freeUsed} از ${stats.freeLimit}',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                  ),
                ),
                if (!stats.hasSubscription) ...[
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: stats.freeUsagePercent / 100,
                      minHeight: 5.h,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    isNearLimit
                        ? 'یک تحلیل رایگان باقی مانده'
                        : '${stats.remainingFree} تحلیل رایگان باقی مانده',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressGradientButton extends StatelessWidget {
  const ProgressGradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.accent = kProgressAccent,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: disabled
            ? LinearGradient(
                colors: [
                  context.textSecondary.withValues(alpha: 0.35),
                  context.textSecondary.withValues(alpha: 0.25),
                ],
              )
            : LinearGradient(
                colors: [
                  Color.lerp(accent, Colors.white, 0.1)!,
                  Color.lerp(accent, Colors.black, 0.12)!,
                ],
              ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressInsightTile extends StatelessWidget {
  const ProgressInsightTile({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: kProgressAccent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: kProgressAccent.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16.sp, color: kProgressAccent),
            SizedBox(height: 4.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressEmptyState extends StatelessWidget {
  const ProgressEmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 12.w),
      child: Column(
        children: [
          AiHubIconBadge(
            icon: icon,
            gradientColors: aiHubAccentGradient(kProgressAccent),
            size: 72.w,
            iconSize: 32.sp,
          ),
          SizedBox(height: 20.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.5.sp,
              height: 1.5,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
