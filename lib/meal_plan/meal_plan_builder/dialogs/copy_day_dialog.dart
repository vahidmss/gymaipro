import 'package:flutter/material.dart';
// دیالوگ کپی روز (CopyDayDialog) مخصوص meal plan
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CopyDayDialog extends StatefulWidget {
  const CopyDayDialog({
    required this.days,
    required this.currentDayIndex,
    super.key,
  });
  final List<String> days;
  final int currentDayIndex;

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
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1310),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16.r,
              offset: Offset(0.w, 8.h),
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
                Text(
                  'کپی وعده‌های یک روز',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.amber),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'به کدام روزها کپی شود؟',
              style: TextStyle(color: Colors.amberAccent),
            ),
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
                        : Colors.amber[200],
                  ),
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
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: _selectedTargetDays.isEmpty
                        ? null
                        : () {
                            Navigator.of(
                              context,
                            ).pop({'to': _selectedTargetDays.toList()});
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
                        borderRadius: BorderRadius.circular(12.r),
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
