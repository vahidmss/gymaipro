import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  late TextEditingController _controller;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit ?? 'گرم';
    _controller = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _parse(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(20.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: isDark ? context.backgroundColor : context.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ویرایش مقدار',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark ? AppTheme.goldColor : context.textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'واحد',
                        labelStyle: TextStyle(
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.7)
                              : context.textColor.withValues(alpha: 0.7),
                          fontFamily: AppTheme.fontFamily,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.darkCardColor
                            : context.cardColor.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppTheme.darkGreySeparator
                                : AppTheme.lightDividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppTheme.darkGreySeparator
                                : AppTheme.lightDividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppTheme.goldColor,
                            width: 1.5.w,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'گرم', child: Text('گرم')),
                        DropdownMenuItem(value: 'عدد', child: Text('عدد')),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedUnit = v ?? 'گرم'),
                      dropdownColor: isDark
                          ? AppTheme.darkCardColor
                          : context.cardColor,
                      style: TextStyle(
                        color: isDark ? AppTheme.goldColor : context.textColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'مقدار',
                        labelStyle: TextStyle(
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.7)
                              : context.textColor.withValues(alpha: 0.7),
                          fontFamily: AppTheme.fontFamily,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.scale,
                          color: AppTheme.goldColor,
                          size: 18.sp,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.darkCardColor
                            : context.cardColor.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppTheme.darkGreySeparator
                                : AppTheme.lightDividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppTheme.darkGreySeparator
                                : AppTheme.lightDividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppTheme.goldColor,
                            width: 1.5.w,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                      ),
                      style: TextStyle(
                        color: isDark ? AppTheme.goldColor : context.textColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.goldColor),
                        foregroundColor: AppTheme.goldColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text(
                        'انصراف',
                        style: TextStyle(fontFamily: AppTheme.fontFamily),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () {
                        if (!_controller.isSafe) return;
                        final newAmount = _parse(_controller.safeText);
                        if (newAmount > 0) {
                          Navigator.of(
                            context,
                          ).pop({'amount': newAmount, 'unit': _selectedUnit});
                        }
                      },
                      child: const Text(
                        'تأیید',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
