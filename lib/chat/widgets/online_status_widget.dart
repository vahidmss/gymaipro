import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class OnlineStatusWidget extends StatelessWidget {
  const OnlineStatusWidget({
    required this.isOnline,
    super.key,
    this.lastSeen,
    this.showText = true,
  });

  final bool isOnline;
  final DateTime? lastSeen;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    if (!showText) {
      return Container(
        width: 8.w,
        height: 8.h,
        decoration: BoxDecoration(
          color: isOnline ? AppTheme.goldColor : AppTheme.bodyStyle.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: isOnline ? AppTheme.goldColor : AppTheme.bodyStyle.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _getStatusText(),
          style: TextStyle(color: AppTheme.bodyStyle.color, fontSize: 12.sp),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (isOnline) {
      return 'آنلاین';
    }

    if (lastSeen == null) {
      return 'آفلاین';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) {
      return 'چند لحظه پیش';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} دقیقه پیش';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ساعت پیش';
    } else {
      return '${difference.inDays} روز پیش';
    }
  }
}
