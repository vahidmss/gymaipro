import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class OnlineStatusWidget extends StatefulWidget {
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
  State<OnlineStatusWidget> createState() => _OnlineStatusWidgetState();
}

class _OnlineStatusWidgetState extends State<OnlineStatusWidget> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !widget.isOnline) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Never use AppTheme.bodyStyle here — it's white@0.6 for dark UIs only.
    final onlineColor =
        isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
    final offlineColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF525252);
    final statusColor = widget.isOnline ? onlineColor : offlineColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.9),
              width: 1,
            ),
            boxShadow: widget.isOnline
                ? [
                    BoxShadow(
                      color: onlineColor.withValues(alpha: 0.45),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        ),
        if (widget.showText) ...[
          SizedBox(width: 6.w),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: statusColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.fontFamily,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusText() {
    if (widget.isOnline) {
      return 'آنلاین';
    }

    final lastSeen = widget.lastSeen;
    if (lastSeen == null) {
      return 'آفلاین';
    }

    final difference = DateTime.now().difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'چند لحظه پیش';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} دقیقه پیش';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} ساعت پیش';
    }
    return '${difference.inDays} روز پیش';
  }
}
