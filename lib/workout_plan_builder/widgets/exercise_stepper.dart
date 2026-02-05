import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExerciseStepper extends StatelessWidget {
  const ExerciseStepper({
    required this.value,
    required this.min,
    required this.onChanged,
    super.key,
    this.small = false,
  });
  final int value;
  final int min;
  final void Function(int) onChanged;
  final bool small;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFD4AF37);
    final double iconSize = small ? 14 : 18;
    final double fontSize = small ? 12 : 16;
    final double boxPad = small ? 1 : 6;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 1.r,
            offset: Offset(0.w, 1.h),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: boxPad),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: primaryColor, size: iconSize),
            splashRadius: small ? 13 : 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: small ? 2 : 6),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: fontSize,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: primaryColor, size: iconSize),
            splashRadius: small ? 13 : 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
