import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/food_serving_units.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/food_amount_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bottom sheet for entering food amount with API serving units + numeric keypad.
class FoodServingAmountSheet extends StatefulWidget {
  const FoodServingAmountSheet({
    required this.food,
    this.mealTitle = '',
    this.initialAmount,
    this.initialUnit,
    this.confirmLabel = 'افزودن',
    super.key,
  });

  final Food food;
  final String mealTitle;
  final double? initialAmount;
  final String? initialUnit;
  final String confirmLabel;

  @override
  State<FoodServingAmountSheet> createState() => _FoodServingAmountSheetState();
}

class _FoodServingAmountSheetState extends State<FoodServingAmountSheet> {
  late final FoodServingUnits _servingUnits;
  late String _selectedUnitLabel;
  String _amountStr = '';
  bool _replaceNextInput = false;
  final FocusNode _focusNode = FocusNode();

  FoodServingUnits _resolveServingUnits() {
    final fromMeta = widget.food.meta.servingUnits;
    if (fromMeta.units.isNotEmpty) return fromMeta;
    return FoodServingUnits.fallback(
      defaultUnitKey: widget.food.meta.defaultServingUnit,
      servingSizeGrams: widget.food.meta.servingSizeGrams,
    );
  }

  FoodServingUnit? get _activeUnit => _servingUnits.resolve(_selectedUnitLabel);

  String get _selectedUnitDisplay =>
      _activeUnit?.displayLabel ?? _selectedUnitLabel;

  double? get _parsed {
    final v = _amountStr.trim().replaceAll(',', '.');
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  @override
  void initState() {
    super.initState();
    _servingUnits = _resolveServingUnits();
    final initialUnit = widget.initialUnit;
    if (initialUnit != null &&
        initialUnit.isNotEmpty &&
        _servingUnits.resolve(initialUnit) != null) {
      _selectedUnitLabel = _servingUnits.resolve(initialUnit)!.label;
    } else {
      _selectedUnitLabel = _servingUnits.defaultUnit.label;
    }
    final initialAmount = widget.initialAmount;
    if (initialAmount != null && initialAmount > 0) {
      _amountStr = _formatAmountValue(initialAmount);
    } else {
      _amountStr = _defaultAmountForUnit(_activeUnit);
      _replaceNextInput = true;
    }
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

  String _formatAmountValue(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }

  /// مقدار منطقی پیش‌فرض برای هر واحد (اسکوپ/عدد → ۱، گرم → ۱۰۰).
  String _defaultAmountForUnit(FoodServingUnit? unit) {
    if (unit == null) return '1';
    final key = unit.key.toLowerCase();
    if (key == 'gram' || unit.label.trim() == 'گرم') return '100';
    if (key == 'ml' || unit.label.contains('میلی')) return '200';
    return '1';
  }

  void _selectUnit(FoodServingUnit unit) {
    if (_selectedUnitLabel == unit.label) return;
    setState(() {
      _selectedUnitLabel = unit.label;
      _amountStr = _defaultAmountForUnit(unit);
      _replaceNextInput = true;
    });
  }

  void _armAmountReplace() {
    setState(() => _replaceNextInput = true);
  }

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountStr.isNotEmpty) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        }
        _replaceNextInput = false;
        return;
      }
      if (key == '.') {
        if (_replaceNextInput) {
          _amountStr = '0.';
          _replaceNextInput = false;
          return;
        }
        if (_amountStr.isEmpty) {
          _amountStr = '0.';
          return;
        }
        if (!_amountStr.contains('.')) _amountStr += '.';
        return;
      }
      if (_replaceNextInput) {
        _amountStr = key;
        _replaceNextInput = false;
        return;
      }
      if (_amountStr == '0') {
        _amountStr = key;
      } else {
        _amountStr += key;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.52;
    final parsed = _parsed;
    final hasAmount = parsed != null && parsed > 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: MealLogColors.sectionBackground(context),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 8.h),
            child: Column(
              children: [
                Container(
                  width: 36.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 8.h),
                  decoration: BoxDecoration(
                    color: MealLogColors.inputBorder(context),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.food.displayTitle,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: MealLogColors.secondaryText(context),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        color: MealLogColors.hintText(context),
                        size: 16.sp,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 32.w,
                        minHeight: 32.h,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 34.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _servingUnits.units.length,
                    separatorBuilder: (_, __) => SizedBox(width: 6.w),
                    itemBuilder: (context, index) {
                      final unit = _servingUnits.units[index];
                      return _unitChip(context, unit: unit);
                    },
                  ),
                ),
                SizedBox(height: 14.h),
                GestureDetector(
                  onTap: _armAmountReplace,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                          letterSpacing: -0.5,
                        ),
                        child: Text(
                          _amountStr.isEmpty ? '0' : _amountStr,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _selectedUnitDisplay,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: MealLogColors.mutedText(context),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
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
                if (hasAmount)
                  Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Text(
                      _caloriePreview(parsed),
                      key: ValueKey('$_amountStr|$_selectedUnitLabel'),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: MealLogColors.mutedText(context),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  SizedBox(height: 10.h),
                Expanded(
                  child: Focus(
                    focusNode: _focusNode,
                    child: _buildInlineKeypad(context),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: ElevatedButton(
                    onPressed: hasAmount ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MealLogColors.accent(context),
                      disabledBackgroundColor: MealLogColors.accent(context)
                          .withValues(alpha: 0.35),
                      foregroundColor: MealLogColors.onGoldSurface(context),
                      disabledForegroundColor:
                          MealLogColors.onGoldSurface(context).withValues(
                            alpha: 0.45,
                          ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      widget.confirmLabel,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirm() {
    final parsed = _parsed;
    if (parsed == null || parsed <= 0) return;
    final result = <String, dynamic>{
      'food': widget.food,
      'amount': parsed,
      'unit': _selectedUnitLabel,
    };
    if (widget.mealTitle.isNotEmpty) {
      result['mealTitle'] = widget.mealTitle;
    }
    Navigator.of(context).pop(result);
  }

  String _caloriePreview(double amount) {
    final calories = FoodAmountUtils.scaledCalories(
      widget.food,
      amount,
      _selectedUnitLabel,
    ).round();
    return '$calories کالری';
  }

  Widget _unitChip(
    BuildContext context, {
    required FoodServingUnit unit,
  }) {
    final selected = _selectedUnitLabel == unit.label;
    return GestureDetector(
      onTap: () => _selectUnit(unit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected
              ? MealLogColors.chipFill(context, selected: true)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected
                ? MealLogColors.chipBorder(context, selected: true)
                : MealLogColors.inputBorder(context),
          ),
        ),
        child: Text(
          unit.displayLabel,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? MealLogColors.accent(context)
                : MealLogColors.secondaryText(context),
          ),
        ),
      ),
    );
  }

  static const List<List<String>> _keypadRows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  Widget _buildInlineKeypad(BuildContext context) {
    final textColor = MealLogColors.secondaryText(context);

    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < _keypadRows.length; rowIndex++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex < _keypadRows.length - 1 ? 3.h : 0,
              ),
              child: Row(
                children: _keypadRows[rowIndex].map((key) {
                  final isBack = key == '⌫';
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onKey(key),
                          borderRadius: BorderRadius.circular(10.r),
                          child: Center(
                            child: isBack
                                ? Icon(
                                    Icons.backspace_outlined,
                                    size: 17.sp,
                                    color: textColor.withValues(alpha: 0.7),
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
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}
