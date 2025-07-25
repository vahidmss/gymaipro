import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/food_log_item.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_textfield.dart';

class EditFoodDialog extends StatefulWidget {
  final FoodLogItem foodItem;
  final String mealTitle;

  const EditFoodDialog({
    super.key,
    required this.foodItem,
    required this.mealTitle,
  });

  @override
  State<EditFoodDialog> createState() => _EditFoodDialogState();
}

class _EditFoodDialogState extends State<EditFoodDialog> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.foodItem.amount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber[700]!.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[700]?.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    LucideIcons.edit,
                    color: Colors.amber[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'ویرایش مقدار مصرفی',
                    style: TextStyle(
                      color: Colors.amber[200],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount input
            GoldTextField(
              controller: _amountController,
              label: 'مقدار (گرم)',
              hint: 'مقدار مصرفی',
              keyboardType: TextInputType.number,
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
                const SizedBox(width: 10),
                Expanded(
                  child: GoldButton(
                    text: 'تأیید',
                    onPressed: () {
                      final newAmount = double.tryParse(_amountController.text);
                      if (newAmount != null && newAmount > 0) {
                        Navigator.of(context).pop(newAmount);
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
