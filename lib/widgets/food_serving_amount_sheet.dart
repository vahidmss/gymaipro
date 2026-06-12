import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      _amountStr = initialAmount % 1 == 0
          ? initialAmount.toInt().toString()
          : initialAmount.toString();
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

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountStr.isNotEmpty) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        }
        return;
      }
      if (key == '.') {
        if (!_amountStr.contains('.')) _amountStr += '.';
        return;
      }
      if (_amountStr == '0' && key != '.') {
        _amountStr = key;
      } else {
        _amountStr += key;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.52;
    final parsed = _parsed;
    final hasAmount = parsed != null && parsed > 0;
    final textColor = isDark ? AppTheme.goldColor : context.textColor;
    final borderColor =
        isDark ? AppTheme.darkGreySeparator : AppTheme.lightDividerColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: isDark ? context.backgroundColor : context.cardColor,
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
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.food.title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: textColor, size: 18.sp),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 32.w,
                        minHeight: 32.h,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  height: 38.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _servingUnits.units.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      final unit = _servingUnits.units[index];
                      return _unitChip(
                        context,
                        isDark,
                        unit: unit,
                      );
                    },
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkCardColor
                        : context.cardColor.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _amountStr.isEmpty ? '0' : _amountStr,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: textColor,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          _selectedUnitDisplay,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: textColor.withValues(alpha: 0.75),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 28.h,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: hasAmount
                          ? Text(
                              _scaledPreviewLine(parsed),
                              key: ValueKey('$_amountStr|$_selectedUnitLabel'),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: AppTheme.goldColor.withValues(
                                  alpha: isDark ? 0.95 : 0.85,
                                ),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Text(
                              'مبنای محاسبه: ${widget.food.nutritionBasisLabel}',
                              key: const ValueKey('basis'),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: context.textSecondary,
                                fontSize: 10.sp,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: Focus(
                    focusNode: _focusNode,
                    child: _buildInlineKeypad(context, isDark),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: ElevatedButton(
                    onPressed: hasAmount ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      disabledBackgroundColor:
                          AppTheme.goldColor.withValues(alpha: 0.35),
                      foregroundColor: AppTheme.veryDarkBackground,
                      disabledForegroundColor: Colors.black54,
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

  String _scaledPreviewLine(double amount) {
    final calories = FoodAmountUtils.scaledCalories(
      widget.food,
      amount,
      _selectedUnitLabel,
    ).round();
    final grams = FoodAmountUtils.gramsFromAmount(
      widget.food,
      amount,
      _selectedUnitLabel,
    );
    final gramsLabel = grams > 0 ? '  ·  ≈ ${grams.round()} گرم' : '';
    return '≈ $calories کالری$gramsLabel';
  }

  Widget _unitChip(
    BuildContext context,
    bool isDark, {
    required FoodServingUnit unit,
  }) {
    final selected = _selectedUnitLabel == unit.label;
    return GestureDetector(
      onTap: () => setState(() => _selectedUnitLabel = unit.label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.16)
              : (isDark ? AppTheme.darkCardColor : context.cardColor),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: selected
                ? AppTheme.goldColor
                : (isDark
                    ? AppTheme.darkGreySeparator
                    : AppTheme.lightDividerColor),
          ),
        ),
        child: Text(
          unit.displayLabel,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: selected
                ? AppTheme.goldColor
                : context.textColor.withValues(alpha: 0.8),
            fontSize: 11.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

  Widget _buildInlineKeypad(BuildContext context, bool isDark) {
    final textColor = isDark ? AppTheme.goldColor : context.textColor;
    final surface = isDark ? AppTheme.darkCardColor : context.cardColor;

    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < _keypadRows.length; rowIndex++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex < _keypadRows.length - 1 ? 4.h : 0,
              ),
              child: Row(
                children: _keypadRows[rowIndex].map((key) {
                  final isBack = key == '⌫';
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      child: Material(
                        color: surface,
                        borderRadius: BorderRadius.circular(8.r),
                        child: InkWell(
                          onTap: () => _onKey(key),
                          borderRadius: BorderRadius.circular(8.r),
                          child: Center(
                            child: isBack
                                ? Icon(
                                    Icons.backspace_outlined,
                                    size: 18.sp,
                                    color: textColor.withValues(alpha: 0.8),
                                  )
                                : Text(
                                    key,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      color: textColor,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
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
