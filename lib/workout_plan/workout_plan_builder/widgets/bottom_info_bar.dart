import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
      if (difference.inHours < 1) {
        return 'چند دقیقه پیش';
      }
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ماه پیش';
    } else {
      return '${(difference.inDays / 365).floor()} سال پیش';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20.r,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          width: 1.5.w,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.clipboardList,
                      color: const Color(0xFFD4AF37),
                      size: 16.sp,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'تعداد حرکات: ',
                      style: TextStyle(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      exerciseCount.toString(),
                      style: TextStyle(
                        color: const Color(0xFFD4AF37),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.clock,
                      color: const Color(0xFFD4AF37),
                      size: 16.sp,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'آخرین ویرایش: ',
                      style: TextStyle(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      exerciseCount > 0 ? _formatDate(updatedAt) : '-',
                      style: TextStyle(
                        color: const Color(0xFFD4AF37),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
