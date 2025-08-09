import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onDayChanged;

  const DaySelector({
    Key? key,
    required this.selectedDay,
    required this.onDayChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final daysFa = [
      'روز ۱',
      'روز ۲',
      'روز ۳',
      'روز ۴',
      'روز ۵',
      'روز ۶',
      'روز ۷'
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, idx) {
          final isSelected = selectedDay == idx;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ChoiceChip(
                label: Text(
                  daysFa[idx],
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF1A1A1A)
                        : Colors.amber[200],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) onDayChanged(idx);
                },
                selectedColor: Colors.amber[700],
                backgroundColor: const Color(0xFF2C1810),
                side: BorderSide(
                  color: isSelected
                      ? Colors.amber[700]!
                      : Colors.amber[700]!.withOpacity(0.3),
                  width: 1.5,
                ),
                elevation: isSelected ? 6 : 2,
                shadowColor: Colors.black.withOpacity(0.3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          );
        },
      ),
    );
  }
}
