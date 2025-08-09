import 'package:flutter/material.dart';

class ExerciseStepper extends StatelessWidget {
  final int value;
  final int min;
  final void Function(int) onChanged;
  final bool small;

  const ExerciseStepper({
    Key? key,
    required this.value,
    required this.min,
    required this.onChanged,
    this.small = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.amber[700]!;
    final double iconSize = small ? 14 : 18;
    final double fontSize = small ? 12 : 16;
    final double boxPad = small ? 1 : 6;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: primaryColor.withOpacity(0.13), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.04),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: boxPad, vertical: 0),
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
