import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_plan/meal_log/models/logged_supplement.dart';
import 'package:gymaipro/widgets/gold_button.dart';
import 'package:gymaipro/widgets/gold_textfield.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddSupplementDialog extends StatefulWidget {
  const AddSupplementDialog({super.key});

  @override
  State<AddSupplementDialog> createState() => _AddSupplementDialogState();
}

class _AddSupplementDialogState extends State<AddSupplementDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedType = 'مکمل';
  String _selectedUnit = 'عدد';

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _timeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(20.w),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C1810), Color(0xFF3D2317), Color(0xFF4A2C1A)],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.amber[700]!.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.amber[700]?.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    LucideIcons.pill,
                    color: Colors.amber[700],
                    size: 24.sp,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'افزودن مکمل',
                    style: TextStyle(
                      color: Colors.amber[200],
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.amber[700]?.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.amber[700]!.withValues(alpha: 0.1),
                      width: 1.5.w,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      color: Colors.amber[700],
                      size: 20.sp,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Supplement name
            GoldTextField(
              controller: _nameController,
              label: 'نام مکمل',
              hint: 'نام مکمل یا دارو',
            ),
            const SizedBox(height: 16),

            // Supplement type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber[700]?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Colors.amber[700]!.withValues(alpha: 0.1),
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedType,
                dropdownColor: const Color(0xFF2C1810),
                style: TextStyle(color: Colors.amber[200]),
                underline: Container(),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'مکمل', child: Text('مکمل')),
                  DropdownMenuItem(value: 'ویتامین', child: Text('ویتامین')),
                  DropdownMenuItem(value: 'دارو', child: Text('دارو')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Amount and unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GoldTextField(
                    controller: _amountController,
                    label: 'مقدار',
                    hint: 'مقدار',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber[700]?.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: Colors.amber[700]!.withValues(alpha: 0.1),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedUnit,
                      dropdownColor: const Color(0xFF2C1810),
                      style: TextStyle(color: Colors.amber[200]),
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(value: 'عدد', child: Text('عدد')),
                        DropdownMenuItem(value: 'گرم', child: Text('گرم')),
                        DropdownMenuItem(
                          value: 'میلی‌گرم',
                          child: Text('میلی‌گرم'),
                        ),
                        DropdownMenuItem(
                          value: 'میلی‌لیتر',
                          child: Text('میلی‌لیتر'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time
            GoldTextField(
              controller: _timeController,
              label: 'زمان مصرف',
              hint: 'مثل: صبح، شب، قبل از غذا',
            ),
            const SizedBox(height: 16),

            // Note
            GoldTextField(
              controller: _noteController,
              label: 'یادداشت',
              hint: 'یادداشت اضافی (اختیاری)',
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'انصراف',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GoldButton(
                    text: 'افزودن',
                    onPressed: () {
                      if (_nameController.text.isNotEmpty) {
                        final supplement = LoggedSupplement(
                          name: _nameController.text,
                          amount: double.tryParse(_amountController.text),
                          unit: _selectedUnit,
                          time: _timeController.text.isNotEmpty
                              ? _timeController.text
                              : null,
                          note: _noteController.text.isNotEmpty
                              ? _noteController.text
                              : null,
                          supplementType: _selectedType,
                        );
                        Navigator.of(context).pop(supplement);
                      }
                    },
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
