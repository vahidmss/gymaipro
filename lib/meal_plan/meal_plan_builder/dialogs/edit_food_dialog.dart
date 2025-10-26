import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/food.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EditFoodDialog extends StatefulWidget {
  const EditFoodDialog({
    required this.food,
    required this.initialAmount,
    this.initialUnit,
    super.key,
  });
  final Food food;
  final double initialAmount;
  final String? initialUnit;

  @override
  State<EditFoodDialog> createState() => _EditFoodDialogState();
}

class _EditFoodDialogState extends State<EditFoodDialog> {
  late TextEditingController _amountController;
  late String? _unit;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount > 0 ? widget.initialAmount.toString() : '',
    );
    _unit = widget.initialUnit ?? 'گرم';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nutrition = widget.food.nutrition;
    final factor = (double.tryParse(_amountController.text) ?? 0) / 100.0;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(20.w),
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C1810), Color(0xFF3D2317), Color(0xFF4A2C1A)],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.amber[700]!.withValues(alpha: 0.1),
              width: 2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20.r,
                offset: Offset(0.w, 8.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.edit, color: Colors.amber[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ویرایش غذا',
                        style: TextStyle(
                          color: Colors.amber[200],
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: Colors.amber[700]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (widget.food.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18.r),
                        child: Image.network(
                          widget.food.imageUrl,
                          width: 48.w,
                          height: 48.h,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Icon(LucideIcons.image, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.food.title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'مقدار',
                          labelStyle: TextStyle(color: Colors.amber[300]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _unit,
                      items: ['گرم', 'عدد', 'لیوان']
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v),
                    ),
                  ],
                ),
                if ((double.tryParse(_amountController.text) ?? 0) > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'کالری: ${(double.tryParse(nutrition.calories) ?? 0 * factor).toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'پروتئین: ${(double.tryParse(nutrition.protein) ?? 0 * factor).toStringAsFixed(1)}g',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.check),
                        label: const Text('تایید'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed:
                            (double.tryParse(_amountController.text) ?? 0) > 0
                            ? () {
                                Navigator.of(context).pop({
                                  'amount':
                                      double.tryParse(_amountController.text) ??
                                      0,
                                  'unit': _unit,
                                });
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[200],
                          side: BorderSide(color: Colors.amber[700]!),
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
        ),
      ),
    );
  }
}
