import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WorkoutLogAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String persianDate;
  final VoidCallback onBackPressed;
  final VoidCallback onDatePickerPressed;

  const WorkoutLogAppBar({
    Key? key,
    required this.persianDate,
    required this.onBackPressed,
    required this.onDatePickerPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C1810),
              Color(0xFF3D2317),
              Color(0xFF4A2C1A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.amber[700]?.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber[700]!.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.arrowRight,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    onPressed: onBackPressed,
                    tooltip: 'بازگشت',
                  ),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ثبت تمرین',
                        style: TextStyle(
                          color: Colors.amber[200],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        persianDate,
                        style: TextStyle(
                          color: Colors.amber[200]?.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Calendar icon
                Container(
                  decoration: BoxDecoration(
                    color: Colors.amber[700]?.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber[700]!.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.calendar,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    tooltip: 'انتخاب تاریخ',
                    onPressed: onDatePickerPressed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
