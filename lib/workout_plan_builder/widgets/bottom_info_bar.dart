import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BottomInfoBar extends StatelessWidget {
  const BottomInfoBar({
    required this.exerciseCount,
    required this.updatedAt,
    super.key,
  });
  final int exerciseCount;
  final DateTime updatedAt;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inMinutes < 1) return 'همین الان';
      if (difference.inHours < 1) return '${difference.inMinutes} دقیقه پیش';
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ماه پیش';
    }
    return '${(difference.inDays / 365).floor()} سال پیش';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = (isDark ? AppTheme.goldColor : context.textColor).withValues(
      alpha: 0.65,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          top: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clipboardList, color: AppTheme.goldColor, size: 14.sp),
          SizedBox(width: 5.w),
          Text(
            'تعداد حرکات این روز: ',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: muted,
              fontSize: 11.sp,
            ),
          ),
          Text(
            '$exerciseCount',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.goldColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 14.w),
          Icon(LucideIcons.save, color: AppTheme.goldColor, size: 14.sp),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              exerciseCount > 0
                  ? 'آخرین ذخیره: ${_formatDate(updatedAt)}'
                  : 'هنوز ذخیره نشده',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: muted,
                fontSize: 11.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
