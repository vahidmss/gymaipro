import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/meal_log_utils.dart';
import '../dialogs/persian_food_log_date_picker_dialog.dart';

class MealLogAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DateTime selectedDate;
  final VoidCallback? onSave;
  final Function(DateTime) onDateSelected;
  final VoidCallback? onSync;

  const MealLogAppBar({
    super.key,
    required this.selectedDate,
    required this.onSave,
    required this.onDateSelected,
    this.onSync,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  onPressed: () => Navigator.of(context).pop(),
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
                      'ثبت تغذیه',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      MealLogUtils.getPersianFormattedDate(selectedDate),
                      style: TextStyle(
                        color: Colors.amber[200]?.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Save button
              // حذف کامل دکمه سیو
              // Sync button
              // حذف کامل دکمه سینک
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
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => PersianFoodLogDatePickerDialog(
                        selectedDate: selectedDate,
                        onDateSelected: onDateSelected,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
