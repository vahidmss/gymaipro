import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Bottom sheet سبک با کیبورد عددی مینیمال — بدون کیبورد سیستم.
class AmountKeypadSheet extends StatefulWidget {
  const AmountKeypadSheet({required this.foodItem, super.key});

  final FoodLogItem foodItem;

  @override
  State<AmountKeypadSheet> createState() => _AmountKeypadSheetState();
}

class _AmountKeypadSheetState extends State<AmountKeypadSheet> {
  late String _value;
  late String _unit;
  bool _replaceNextInput = false;
  final FocusNode _focusNode = FocusNode();

  bool get _hasPlanned => widget.foodItem.plannedAmount != null;

  @override
  void initState() {
    super.initState();
    _value = widget.foodItem.amount.truncateToDouble() == widget.foodItem.amount
        ? widget.foodItem.amount.toInt().toString()
        : widget.foodItem.amount.toString();
    _unit = widget.foodItem.unit;
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

  void _armAmountReplace() {
    setState(() => _replaceNextInput = true);
  }

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_value.isNotEmpty) _value = _value.substring(0, _value.length - 1);
        _replaceNextInput = false;
        return;
      }
      if (key == '.') {
        if (_replaceNextInput) {
          _value = '0.';
          _replaceNextInput = false;
          return;
        }
        if (_value.isEmpty) {
          _value = '0.';
          return;
        }
        if (!_value.contains('.')) _value += '.';
        return;
      }
      if (_replaceNextInput) {
        _value = key;
        _replaceNextInput = false;
        return;
      }
      if (_value == '0') {
        _value = key;
      } else {
        _value += key;
      }
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Focus(
        focusNode: _focusNode,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MealLogColors.sectionBackground(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12.w,
              8.h,
              12.w,
              16.h + MediaQuery.of(context).padding.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 10.h),
                    decoration: BoxDecoration(
                      color: MealLogColors.inputBorder(context),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  Text(
                    _hasPlanned ? 'ثبت مقدار مصرفی' : 'مقدار',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: MealLogColors.secondaryText(context),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_hasPlanned) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'برنامه: ${widget.foodItem.plannedAmount!.toStringAsFixed(0)} ${widget.foodItem.unit}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: MealLogColors.mutedText(context),
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                  SizedBox(height: 14.h),
                  GestureDetector(
                    onTap: _armAmountReplace,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 160),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: _replaceNextInput
                                ? MealLogColors.accent(context)
                                : MealLogColors.primaryText(context),
                            fontSize: 36.sp,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                          child: Text(
                            _value.isEmpty ? '0' : _value,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _unit,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: MealLogColors.mutedText(context),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: EdgeInsets.only(top: 6.h),
                          width: _replaceNextInput ? 28.w : 0,
                          height: 2.h,
                          decoration: BoxDecoration(
                            color: MealLogColors.accent(context),
                            borderRadius: BorderRadius.circular(1.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_hasPlanned) ...[
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _unitChip('گرم'),
                        SizedBox(width: 8.w),
                        _unitChip('عدد'),
                      ],
                    ),
                  ],
                  SizedBox(height: 12.h),
                  RepaintBoundary(
                    child: _Keypad(
                      onKey: _onKey,
                      onConfirm: _onConfirm,
                      canConfirm: _parsed != null && _parsed! > 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _unitChip(String unit) {
    final selected = _unit == unit;
    return GestureDetector(
      onTap: () => setState(() => _unit = unit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected
              ? MealLogColors.chipFill(context, selected: true)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: MealLogColors.chipBorder(context, selected: selected),
          ),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: selected
                ? MealLogColors.accent(context)
                : MealLogColors.secondaryText(context),
            fontSize: 12.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
  });

  final void Function(String) onKey;
  final VoidCallback onConfirm;
  final bool canConfirm;

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
        ..._rows.map(
          (row) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              children: row
                  .map((key) => Expanded(child: _key(context, key)))
                  .toList(),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        SizedBox(
          width: double.infinity,
          height: 44.h,
          child: ElevatedButton(
            onPressed: canConfirm ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: MealLogColors.accent(context),
              disabledBackgroundColor: MealLogColors.accent(context)
                  .withValues(alpha: 0.35),
              foregroundColor: MealLogColors.onGoldSurface(context),
              disabledForegroundColor: MealLogColors.onGoldSurface(context)
                  .withValues(alpha: 0.45),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'تأیید',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _key(BuildContext context, String key) {
    final isBack = key == '⌫';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onKey(key),
          borderRadius: BorderRadius.circular(10.r),
          child: SizedBox(
            height: 44.h,
            child: Center(
              child: isBack
                  ? Icon(
                      Icons.backspace_outlined,
                      size: 17.sp,
                      color: MealLogColors.secondaryText(context)
                          .withValues(alpha: 0.7),
                    )
                  : Text(
                      key,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: MealLogColors.primaryText(context),
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
