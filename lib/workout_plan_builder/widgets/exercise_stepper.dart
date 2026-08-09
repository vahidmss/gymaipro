import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ExerciseStepper extends StatelessWidget {
  const ExerciseStepper({
    required this.value,
    required this.min,
    required this.onChanged,
    super.key,
    this.max,
    this.small = false,
    this.suffix,
  });
  final int value;
  final int min;
  final int? max;
  final void Function(int) onChanged;
  final bool small;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = AppTheme.goldColor;
    final double iconSize = small ? 14 : 18;
    final double fontSize = small ? 12 : 16;
    final double boxPad = small ? 1 : 6;
    final canDec = value > min;
    final canInc = max == null || value < max!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.1),
            blurRadius: 2.r,
            offset: Offset(0.w, 1.h),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: boxPad),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.remove,
              color: canDec
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.35),
              size: iconSize,
            ),
            splashRadius: small ? 13 : 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
            onPressed: canDec ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: small ? 2 : 6),
            child: Text(
              suffix == null ? value.toString() : '$value$suffix',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: fontSize,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: canInc
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.35),
              size: iconSize,
            ),
            splashRadius: small ? 13 : 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
            onPressed: canInc ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
