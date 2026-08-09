import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Compact status strip for the students list — no nested card bloat.
class RelationshipStatsWidget extends StatelessWidget {
  const RelationshipStatsWidget({required this.stats, super.key});
  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      _StatItem(
        icon: LucideIcons.userCheck,
        label: 'فعال',
        count: stats['active'] ?? 0,
        color: AppTheme.successColor,
      ),
      _StatItem(
        icon: LucideIcons.clock4,
        label: 'در انتظار',
        count: stats['pending'] ?? 0,
        color: Colors.amber.shade700,
      ),
      _StatItem(
        icon: LucideIcons.shieldAlert,
        label: 'مسدود',
        count: stats['blocked'] ?? 0,
        color: AppTheme.errorColor,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: 8.w),
          Expanded(child: _buildChip(context, items[i], isDark)),
        ],
      ],
    );
  }

  Widget _buildChip(BuildContext context, _StatItem item, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: item.color.withValues(alpha: isDark ? 0.28 : 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 15.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.count.toString(),
                  style: TextStyle(
                    color: item.color,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                    height: 1.1,
                  ),
                ),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
}
