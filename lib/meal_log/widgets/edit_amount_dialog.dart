import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/utils/responsive_dialog_utils.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditAmountDialog extends StatefulWidget {
  const EditAmountDialog({required this.foodItem, super.key});

  final FoodLogItem foodItem;

  @override
  State<EditAmountDialog> createState() => _EditAmountDialogState();
}

class _EditAmountDialogState extends State<EditAmountDialog> {
  late TextEditingController _controller;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.foodItem.unit;
    _controller = TextEditingController(
      text: widget.foodItem.amount.toStringAsFixed(0),
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
        insetPadding: ResponsiveDialogUtils.getStandardInsetPadding(context),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveDialogUtils.getStandardMaxWidth(context),
          ),
          padding: ResponsiveDialogUtils.getStandardDialogPadding(context),
          decoration: BoxDecoration(
            color: isDark ? context.backgroundColor : context.cardColor,
            borderRadius: BorderRadius.circular(
              ResponsiveDialogUtils.getStandardBorderRadius(context),
            ),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.foodItem.plannedAmount != null
                    ? 'ثبت مقدار مصرفی'
                    : 'ویرایش مقدار',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark ? AppTheme.goldColor : context.textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (widget.foodItem.plannedAmount != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkCardColor
                        : context.cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkGreySeparator
                          : AppTheme.lightDividerColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مقدار تعیین شده توسط مربی: ${widget.foodItem.plannedAmount!.toStringAsFixed(0)} ${widget.foodItem.unit}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'لطفاً مقدار مصرفی خود را وارد کنید. می‌توانید بیشتر یا کمتر از مقدار برنامه هم وارد کنید.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.8)
                              : context.textColor.withValues(alpha: 0.8),
                          fontSize: 11.sp,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              Row(
                children: [
                  if (widget.foodItem.plannedAmount == null) ...[
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
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
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
                          Navigator.of(context).pop({
                            'amount': newAmount,
                            'unit': widget.foodItem.plannedAmount != null
                                ? widget.foodItem.unit
                                : _selectedUnit,
                          });
                        }
                      },
                      child: const Text(
                        'تأیید',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
