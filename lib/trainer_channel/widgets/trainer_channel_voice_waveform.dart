import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// موج صدا هنگام ضبط (شبیه تلگرام)
class TrainerChannelVoiceWaveform extends StatelessWidget {
  const TrainerChannelVoiceWaveform({
    required this.levels,
    this.activeColor,
    super.key,
  });

  /// مقادیر ۰..۱ برای ارتفاع هر میله
  final List<double> levels;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppTheme.goldColor;
    return SizedBox(
      height: 28.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(levels.length, (i) {
          final h = (4 + levels[i] * 22).clamp(4.0, 26.0);
          return Container(
            width: 3.w,
            height: h,
            margin: EdgeInsets.symmetric(horizontal: 1.2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.35 + levels[i] * 0.65),
              borderRadius: BorderRadius.circular(2.r),
            ),
          );
        }),
      ),
    );
  }
}
