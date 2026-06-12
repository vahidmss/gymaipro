import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Bottom sheet سبک با کیبورد عددی مینیمال — بدون کیبورد سیستم و بدون لگ.
class AmountKeypadSheet extends StatefulWidget {
  const AmountKeypadSheet({required this.foodItem, super.key});

  final FoodLogItem foodItem;

  @override
  State<AmountKeypadSheet> createState() => _AmountKeypadSheetState();
}

class _AmountKeypadSheetState extends State<AmountKeypadSheet> {
  late String _value;
  late String _unit;
  final FocusNode _focusNode = FocusNode();
  bool get _hasPlanned => widget.foodItem.plannedAmount != null;

  @override
  void initState() {
    super.initState();
    _value = widget.foodItem.amount.truncateToDouble() == widget.foodItem.amount
        ? widget.foodItem.amount.toInt().toString()
        : widget.foodItem.amount.toString();
    _unit = widget.foodItem.unit;
    // جلوگیری از باز شدن کیبورد سیستم — فوکوس را روی یک گره غیرمتنی ببر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  double? get _parsed {
    final v = _value.trim().replaceAll(',', '.');
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_value.isNotEmpty) _value = _value.substring(0, _value.length - 1);
        return;
      }
      if (key == '.') {
        if (!_value.contains('.')) _value += '.';
        return;
      }
      if (_value == '0' && key != '.') _value = key;
      else _value += key;
    });
  }

  void _onConfirm() {
    final amount = _parsed;
    if (amount != null && amount > 0) {
      Navigator.of(context).pop(<String, dynamic>{
        'amount': amount,
        'unit': _hasPlanned ? widget.foodItem.unit : _unit,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.goldColor : context.textColor;
    final surface = isDark ? AppTheme.darkCardColor : context.cardColor;
    final borderColor = isDark
        ? AppTheme.darkGreySeparator
        : AppTheme.lightDividerColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Focus(
        focusNode: _focusNode,
        child: Container(
          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: isDark ? context.backgroundColor : context.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            border: Border(
              top: BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.25)),
              left: BorderSide(color: borderColor.withValues(alpha: 0.4)),
              right: BorderSide(color: borderColor.withValues(alpha: 0.4)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hasPlanned ? 'ثبت مقدار مصرفی' : 'مقدار',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_hasPlanned) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'برنامه: ${widget.foodItem.plannedAmount!.toStringAsFixed(0)} ${widget.foodItem.unit}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 10.sp,
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                // نمایش مقدار
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _value.isEmpty ? '0' : _value,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: textColor,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Text(
                        _unit,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: textColor.withValues(alpha: 0.8),
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_hasPlanned) ...[
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _unitChip('گرم'),
                      SizedBox(width: 10.w),
                      _unitChip('عدد'),
                    ],
                  ),
                ],
                SizedBox(height: 10.h),
                RepaintBoundary(
                  child: _Keypad(
                    onKey: _onKey,
                    onConfirm: _onConfirm,
                    canConfirm: _parsed != null && _parsed! > 0,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _unitChip(String unit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _unit == unit;
    return GestureDetector(
      onTap: () => setState(() => _unit = unit),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.goldColor.withValues(alpha: isDark ? 0.25 : 0.2)
              : (isDark ? AppTheme.darkCardColor : context.cardColor),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? AppTheme.goldColor : (isDark ? AppTheme.darkGreySeparator : AppTheme.lightDividerColor),
          ),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: selected ? AppTheme.goldColor : context.textColor.withValues(alpha: 0.8),
            fontSize: 13.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onKey,
    required this.onConfirm,
    required this.canConfirm,
    required this.isDark,
  });

  final void Function(String) onKey;
  final VoidCallback onConfirm;
  final bool canConfirm;
  final bool isDark;

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._rows.map((row) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: row.map((key) => Expanded(child: _key(context, key))).toList(),
              ),
            )),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: Material(
            color: canConfirm
                ? AppTheme.goldColor
                : AppTheme.goldColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              onTap: canConfirm ? onConfirm : null,
              borderRadius: BorderRadius.circular(12.r),
              child: Center(
                child: Text(
                  'تأیید',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: canConfirm ? Colors.black : Colors.black54,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _key(BuildContext context, String key) {
    final isBack = key == '⌫';
    final textColor = isDark ? AppTheme.goldColor : context.textColor;
    final surface = isDark ? AppTheme.darkCardColor : context.cardColor;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: () => onKey(key),
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            height: 48.h,
            alignment: Alignment.center,
            child: isBack
                ? Icon(Icons.backspace_outlined, size: 22.sp, color: textColor.withValues(alpha: 0.8))
                : Text(
                    key,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: textColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
