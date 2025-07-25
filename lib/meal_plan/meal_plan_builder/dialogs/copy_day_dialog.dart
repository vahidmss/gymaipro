// دیالوگ کپی روز (CopyDayDialog) مخصوص meal plan
import 'package:flutter/material.dart';

class CopyDayDialog extends StatefulWidget {
  final List<String> days;
  final int currentDayIndex;
  const CopyDayDialog(
      {Key? key, required this.days, required this.currentDayIndex})
      : super(key: key);

  @override
  State<CopyDayDialog> createState() => _CopyDayDialogState();
}

class _CopyDayDialogState extends State<CopyDayDialog> {
  final Set<int> _selectedTargetDays = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1310),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.copy, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'کپی وعده‌های یک روز',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.amber),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('به کدام روزها کپی شود؟',
                style: TextStyle(color: Colors.amberAccent)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: List.generate(widget.days.length, (i) {
                if (i == widget.currentDayIndex) return const SizedBox();
                return FilterChip(
                  label: Text(widget.days[i]),
                  selected: _selectedTargetDays.contains(i),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTargetDays.add(i);
                      } else {
                        _selectedTargetDays.remove(i);
                      }
                    });
                  },
                  selectedColor: Colors.amber[700],
                  backgroundColor: Colors.grey[900],
                  labelStyle: TextStyle(
                      color: _selectedTargetDays.contains(i)
                          ? Colors.black
                          : Colors.amber[200]),
                );
              }),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _selectedTargetDays.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).pop({
                              'to': _selectedTargetDays.toList(),
                            });
                          },
                    child: const Text('کپی کن'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber[200],
                      side: const BorderSide(color: Colors.amber),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('انصراف'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
