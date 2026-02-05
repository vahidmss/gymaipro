import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RelationshipStatsWidget extends StatelessWidget {
  const RelationshipStatsWidget({required this.stats, super.key});
  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppTheme.goldColor.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'آمار شاگردان',
            style: TextStyle(
              color: context.textColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.userCheck,
                  title: 'فعال',
                  count: stats['active'] ?? 0,
                  color: AppTheme.successColor,
                  context: context,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.clock4,
                  title: 'در انتظار',
                  count: stats['pending'] ?? 0,
                  color: Colors.amber,
                  context: context,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.shieldAlert,
                  title: 'مسدود',
                  count: stats['blocked'] ?? 0,
                  color: AppTheme.errorColor,
                  context: context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(height: 10.h),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
              height: 1.1,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
