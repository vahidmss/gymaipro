import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shamsi_date/shamsi_date.dart';

// کارت wrapper برای مراحل تکمیل پروفایل
class ProfileCardWrapper extends StatelessWidget {
  const ProfileCardWrapper({
    required this.child,
    this.padding,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 10.h,
          bottom: 4.h + keyboardHeight,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360.w),
          child: RepaintBoundary(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Container(
                padding: padding ?? EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightCardColor,
                    AppTheme.lightGradientStart.withValues(alpha: 0.2),
                    AppTheme.lightCardColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.5),
                  width: 2.5.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.35),
                    blurRadius: 32.r,
                    offset: Offset(0.w, 12.h),
                    spreadRadius: 3.r,
                  ),
                  BoxShadow(
                    color: AppTheme.lightTextColor.withValues(alpha: 0.08),
                    blurRadius: 20.r,
                    offset: Offset(0.w, 6.h),
                    spreadRadius: 1.r,
                  ),
                ],
              ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// گزینه انتخاب جنسیت
class GenderOption extends StatelessWidget {
  const GenderOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.lightGradientStart.withValues(alpha: 0.4),
                          AppTheme.lightCardColor,
                          AppTheme.lightGradientStart.withValues(alpha: 0.3),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : null,
                color: isSelected ? null : AppTheme.lightCardColor,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.goldColor.withValues(alpha: 0.6)
                      : AppTheme.lightDividerColor,
                  width: isSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.25),
                          blurRadius: 12.r,
                          spreadRadius: 1.r,
                          offset: Offset(0.w, 4.h),
                        ),
                        BoxShadow(
                          color: AppTheme.lightTextColor.withValues(alpha: 0.05),
                          blurRadius: 8.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppTheme.lightTextColor.withValues(alpha: 0.06),
                          blurRadius: 6.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.goldColor.withValues(alpha: 0.15),
                                AppTheme.goldColor.withValues(alpha: 0.25),
                              ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : AppTheme.lightDividerColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14.r),
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.goldColor.withValues(alpha: 0.3),
                            )
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 32.sp,
                      color: isSelected
                          ? AppTheme.goldColor
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: ResponsiveValue(
                          context,
                          defaultValue: 18.sp,
                          conditionalValues: [
                            Condition.smallerThan(name: MOBILE, value: 16.sp),
                            Condition.largerThan(name: TABLET, value: 20.sp),
                          ],
                        ).value,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? AppTheme.goldColor
                            : AppTheme.lightTextColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                  if (isSelected)
                    AnimatedScale(
                      scale: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldColor,
                              AppTheme.darkGold,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldColor.withValues(alpha: 0.4),
                              blurRadius: 8.r,
                              spreadRadius: 1.r,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: AppTheme.darkTextColor,
                          size: 18.sp,
                        ),
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
}

// Dropdown برای تاریخ
class DateDropdown<T> extends StatelessWidget {
  const DateDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        border: Border.all(
          color: value != null
              ? AppTheme.goldColor.withValues(alpha: 0.5)
              : AppTheme.lightDividerColor,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: AppTheme.lightCardColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.lightCardColor,
          style: TextStyle(
            color: AppTheme.lightTextColor,
            fontSize: 14.sp,
            fontFamily: AppTheme.fontFamily,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: value != null
                ? AppTheme.goldColor
                : AppTheme.lightTextSecondary,
            size: 20.sp,
          ),
          hint: Text(
            label,
            style: TextStyle(
              color: AppTheme.lightTextSecondary,
              fontSize: 14.sp,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                style: TextStyle(
                  color: AppTheme.lightTextColor,
                  fontSize: 14.sp,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Dropdown برای ماه‌های شمسی
class MonthDropdown extends StatelessWidget {
  const MonthDropdown({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int? value;
  final void Function(int?) onChanged;

  String _getPersianMonthName(int month) {
    const months = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        border: Border.all(
          color: value != null
              ? AppTheme.goldColor.withValues(alpha: 0.5)
              : AppTheme.lightDividerColor,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: AppTheme.lightCardColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.lightCardColor,
          style: TextStyle(
            color: AppTheme.lightTextColor,
            fontSize: 14.sp,
            fontFamily: AppTheme.fontFamily,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: value != null
                ? AppTheme.goldColor
                : AppTheme.lightTextSecondary,
            size: 20.sp,
          ),
          hint: Text(
            'ماه',
            style: TextStyle(
              color: AppTheme.lightTextSecondary,
              fontSize: 14.sp,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          items: List.generate(12, (i) => i + 1).map((int month) {
            return DropdownMenuItem<int>(
              value: month,
              child: Text(
                _getPersianMonthName(month),
                style: TextStyle(
                  color: AppTheme.lightTextColor,
                  fontSize: 14.sp,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── انتخاب تاریخ تولد به سبک چرخ (مثل اپ‌های درجه‌یک) ───

const List<String> _persianMonthNames = [
  '',
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

int _daysInJalaliMonth(int year, int month) {
  if (month <= 6) return 31;
  if (month <= 11) return 30;
  return Jalali(year).isLeapYear() ? 30 : 29;
}

const double _kWheelItemExtent = 48;
const int _kWheelVisibleCount = 5;

/// فیلد قابل لمس برای انتخاب تاریخ تولد — با یک لمس، bottom sheet چرخ‌دار باز می‌شود.
class BirthDateTapField extends StatelessWidget {
  const BirthDateTapField({
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay,
    required this.onDateSelected,
    super.key,
  });

  final int? selectedYear;
  final int? selectedMonth;
  final int? selectedDay;
  final void Function(int year, int month, int day) onDateSelected;

  static String _formatDate(int? y, int? m, int? d) {
    if (y == null || m == null || d == null) return '';
    return '$d ${_persianMonthNames[m]} $y';
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedYear != null && selectedMonth != null && selectedDay != null;
    final label = hasValue
        ? _formatDate(selectedYear, selectedMonth, selectedDay)
        : 'انتخاب تاریخ تولد';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openBirthDateSheet(context),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasValue
                  ? AppTheme.goldColor.withValues(alpha: 0.5)
                  : AppTheme.lightDividerColor,
            ),
            borderRadius: BorderRadius.circular(12.r),
            color: AppTheme.lightCardColor,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 22.sp,
                color: hasValue ? AppTheme.goldColor : AppTheme.lightTextSecondary,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: hasValue
                        ? AppTheme.lightTextColor
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 24.sp,
                color: hasValue ? AppTheme.goldColor : AppTheme.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBirthDateSheet(BuildContext context) {
    final now = Jalali.now();
    final initialYear = selectedYear ?? now.year - 25;
    final initialMonth = selectedMonth ?? 1;
    final initialDay = selectedDay ?? 1;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BirthDateWheelSheet(
        initialYear: initialYear,
        initialMonth: initialMonth,
        initialDay: initialDay,
        onConfirm: (y, m, d) {
          Navigator.of(ctx).pop();
          onDateSelected(y, m, d);
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }
}

class _BirthDateWheelSheet extends StatefulWidget {
  const _BirthDateWheelSheet({
    required this.initialYear,
    required this.initialMonth,
    required this.initialDay,
    required this.onConfirm,
    required this.onCancel,
  });

  final int initialYear;
  final int initialMonth;
  final int initialDay;
  final void Function(int year, int month, int day) onConfirm;
  final VoidCallback onCancel;

  @override
  State<_BirthDateWheelSheet> createState() => _BirthDateWheelSheetState();
}

class _BirthDateWheelSheetState extends State<_BirthDateWheelSheet> {
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  late List<int> _years;
  static const List<int> _months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  late List<int> _days;

  int get _selectedYear {
    final i = _yearController.hasClients ? _yearController.selectedItem : 0;
    return _years[i.clamp(0, _years.length - 1)];
  }

  int get _selectedMonth {
    final i = _monthController.hasClients ? _monthController.selectedItem : 0;
    return _months[i.clamp(0, _months.length - 1)];
  }

  int get _selectedDay {
    final i = _dayController.hasClients ? _dayController.selectedItem : 0;
    return _days[i.clamp(0, _days.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    final now = Jalali.now();
    _years = List.generate(101, (i) => now.year - 100 + i);
    _years.sort((a, b) => b.compareTo(a));

    final yearIndex = _years.indexOf(widget.initialYear);
    final monthIndex = _months.indexOf(widget.initialMonth);
    _yearController = FixedExtentScrollController(
      initialItem: yearIndex >= 0 ? yearIndex : 0,
    );
    _monthController = FixedExtentScrollController(
      initialItem: monthIndex >= 0 ? monthIndex : 0,
    );

    _days = _buildDays(widget.initialYear, widget.initialMonth);
    final dayIndex = widget.initialDay.clamp(1, _days.length) - 1;
    _dayController = FixedExtentScrollController(initialItem: dayIndex);
  }

  List<int> _buildDays(int year, int month) {
    final n = _daysInJalaliMonth(year, month);
    return List.generate(n, (i) => i + 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _onYearOrMonthChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final year = _selectedYear;
      final month = _selectedMonth;
      final newDays = _buildDays(year, month);
      final oldDayIndex = _dayController.hasClients ? _dayController.selectedItem : 0;
      final newDayIndex = (oldDayIndex + 1).clamp(1, newDays.length) - 1;
      setState(() => _days = newDays);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dayController.hasClients && _dayController.positions.isNotEmpty) {
          _dayController.jumpToItem(newDayIndex.clamp(0, _days.length - 1));
        }
      });
    });
  }

  static const double _itemExtent = _kWheelItemExtent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1E) : AppTheme.lightCardColor;
    final textColor = isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor;
    final secondaryColor = isDark ? Colors.white54 : AppTheme.lightTextSecondary;
    const gold = AppTheme.goldColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.veryDarkBackground.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: Text(
                      'انصراف',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: secondaryColor,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  Text(
                    'تاریخ تولد',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onConfirm(_selectedYear, _selectedMonth, _selectedDay);
                    },
                    child: Text(
                      'تأیید',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: gold,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _WheelColumn<int>(
                      controller: _yearController,
                      items: _years,
                      itemExtent: _itemExtent,
                      label: 'سال',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      gold: gold,
                      formatItem: (v) => v.toString(),
                      onSelected: (_) => _onYearOrMonthChanged(),
                    ),
                  ),
                  Expanded(
                    child: _WheelColumn<int>(
                      controller: _monthController,
                      items: _months,
                      itemExtent: _itemExtent,
                      label: 'ماه',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      gold: gold,
                      formatItem: (m) => _persianMonthNames[m],
                      onSelected: (_) => _onYearOrMonthChanged(),
                    ),
                  ),
                  Expanded(
                    child: _WheelColumn<int>(
                      controller: _dayController,
                      items: _days,
                      itemExtent: _itemExtent,
                      label: 'روز',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      gold: gold,
                      formatItem: (d) => d.toString(),
                      onSelected: (_) {},
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

class _WheelColumn<T> extends StatelessWidget {
  const _WheelColumn({
    required this.controller,
    required this.items,
    required this.itemExtent,
    required this.label,
    required this.textColor,
    required this.secondaryColor,
    required this.gold,
    required this.formatItem,
    this.onSelected,
  });

  final FixedExtentScrollController controller;
  final List<T> items;
  final double itemExtent;
  final String label;
  final Color textColor;
  final Color secondaryColor;
  final Color gold;
  final String Function(T) formatItem;
  final void Function(T)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.sp,
            color: secondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: _kWheelItemExtent * _kWheelVisibleCount,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: itemExtent,
                diameterRatio: 1.4,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: onSelected != null
                    ? (i) {
                        if (i >= 0 && i < items.length) onSelected!(items[i]);
                      }
                    : null,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: items.length,
                  builder: (context, index) {
                    final value = items[index];
                    final str = formatItem(value);
                    return Center(
                      child: Text(
                        str,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
              IgnorePointer(
                child: Container(
                  height: _kWheelItemExtent,
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border(
                      top: BorderSide(color: gold.withValues(alpha: 0.35), width: 1.5),
                      bottom: BorderSide(color: gold.withValues(alpha: 0.35), width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// گزینه انتخاب سطح فعالیت
class ActivityOption extends StatelessWidget {
  const ActivityOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String value;
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.lightGradientStart.withValues(alpha: 0.4),
                          AppTheme.lightCardColor,
                          AppTheme.lightGradientStart.withValues(alpha: 0.3),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : null,
                color: isSelected ? null : AppTheme.lightCardColor,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.goldColor.withValues(alpha: 0.6)
                      : AppTheme.lightDividerColor,
                  width: isSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.25),
                          blurRadius: 12.r,
                          spreadRadius: 1.r,
                          offset: Offset(0.w, 4.h),
                        ),
                        BoxShadow(
                          color: AppTheme.lightTextColor.withValues(alpha: 0.05),
                          blurRadius: 8.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppTheme.lightTextColor.withValues(alpha: 0.06),
                          blurRadius: 6.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.goldColor.withValues(alpha: 0.15),
                                AppTheme.goldColor.withValues(alpha: 0.25),
                              ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : AppTheme.lightDividerColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.goldColor.withValues(alpha: 0.3),
                            )
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 28.sp,
                      color: isSelected
                          ? AppTheme.goldColor
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: ResponsiveValue(
                              context,
                              defaultValue: 18.sp,
                              conditionalValues: [
                                Condition.smallerThan(name: MOBILE, value: 16.sp),
                                Condition.largerThan(name: TABLET, value: 20.sp),
                              ],
                            ).value,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? AppTheme.goldColor
                                : AppTheme.lightTextColor,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: ResponsiveValue(
                              context,
                              defaultValue: 13.sp,
                              conditionalValues: [
                                Condition.smallerThan(name: MOBILE, value: 11.sp),
                                Condition.largerThan(name: TABLET, value: 15.sp),
                              ],
                            ).value,
                            color: AppTheme.lightTextSecondary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    AnimatedScale(
                      scale: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldColor,
                              AppTheme.darkGold,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldColor.withValues(alpha: 0.4),
                              blurRadius: 8.r,
                              spreadRadius: 1.r,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: AppTheme.darkTextColor,
                          size: 18.sp,
                        ),
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
}

