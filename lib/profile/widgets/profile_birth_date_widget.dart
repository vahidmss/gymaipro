import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// ویجت انتخاب تاریخ تولد شمسی
class ProfileBirthDateWidget {
  /// نمایش دیالوگ انتخاب تاریخ تولد
  static Future<void> showPersianBirthDatePicker(
    BuildContext context,
    DateTime? currentBirthDate,
    void Function(String) onDateSelected,
  ) async {
    DateTime? birthDate = currentBirthDate;

    int? selectedYear;
    int? selectedMonth;
    int? selectedDay;

    // تبدیل تاریخ میلادی به شمسی اگر وجود دارد
    if (birthDate != null) {
      final jalali = Jalali.fromDateTime(birthDate);
      selectedYear = jalali.year;
      selectedMonth = jalali.month;
      selectedDay = jalali.day;
    }

    // لیست سال‌ها
    final now = Jalali.now();
    final years = <int>[];
    for (int year = now.year - 100; year <= now.year; year++) {
      years.add(year);
    }
    years.sort((a, b) => b.compareTo(a));

    // لیست روزها
    final days = <int>[];

    void updateDays() {
      days.clear();
      if (selectedYear != null && selectedMonth != null) {
        final daysInMonth = _getDaysInMonth(selectedYear!, selectedMonth!);
        for (int day = 1; day <= daysInMonth; day++) {
          days.add(day);
        }
        if (selectedDay != null && selectedDay! > daysInMonth) {
          selectedDay = null;
        }
      }
    }

    updateDays();

    final monthNames = [
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

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
              side: BorderSide(
                color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
                width: 1.5,
              ),
            ),
            insetPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 24.h,
            ),
            child: Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width * 0.9,
                maxWidth: 500.w,
              ),
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'انتخاب تاریخ تولد',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  // سال در یک خط جداگانه برای نمایش کامل
                  _buildDateDropdown<int>(
                    context,
                    'سال',
                    selectedYear,
                    years,
                    (value) {
                      setDialogState(() {
                        selectedYear = value;
                        selectedDay = null;
                        updateDays();
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  // ماه و روز در یک خط
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedMonth != null
                                  ? AppTheme.goldColor.withValues(alpha: 0.5)
                                  : context.separatorColor,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            color: context.veryDarkBackground,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedMonth,
                              isExpanded: true,
                              dropdownColor: context.cardColor,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: context.textColor,
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              icon: Icon(
                                LucideIcons.chevronDown,
                                color: selectedMonth != null
                                    ? AppTheme.goldColor
                                    : context.textSecondary,
                                size: 24.sp,
                              ),
                              hint: Text(
                                'ماه',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: context.textSecondary,
                                  fontSize: 17.sp,
                                ),
                              ),
                              items: List.generate(12, (i) => i + 1).map((
                                int month,
                              ) {
                                return DropdownMenuItem<int>(
                                  value: month,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.h,
                                    ),
                                    child: Text(
                                      monthNames[month],
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        color: context.textColor,
                                        fontSize: 17.sp,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedMonth = value;
                                  selectedDay = null;
                                  updateDays();
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildDateDropdown<int>(
                          context,
                          'روز',
                          selectedDay,
                          days,
                          (value) {
                            setDialogState(() {
                              selectedDay = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                        ),
                        child: Text(
                          'انصراف',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: context.textSecondary,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      ElevatedButton(
                        onPressed:
                            (selectedYear != null &&
                                selectedMonth != null &&
                                selectedDay != null)
                            ? () {
                                final jalali = Jalali(
                                  selectedYear!,
                                  selectedMonth!,
                                  selectedDay!,
                                );
                                final gregorian = jalali.toGregorian();
                                final dateTime = gregorian.toDateTime();
                                onDateSelected(
                                  dateTime.toIso8601String().split('T')[0],
                                );
                                Navigator.of(context).pop();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldColor,
                          foregroundColor: AppTheme.onGoldColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32.w,
                            vertical: 14.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'تأیید',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildDateDropdown<T>(
    BuildContext context,
    String label,
    T? value,
    List<T> items,
    void Function(T?) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: value != null
              ? AppTheme.goldColor.withValues(alpha: 0.5)
              : context.separatorColor,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: context.veryDarkBackground,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: context.cardColor,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
            fontSize: 17.sp,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(
            LucideIcons.chevronDown,
            color: value != null ? AppTheme.goldColor : context.textSecondary,
            size: 24.sp,
          ),
          hint: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 17.sp,
            ),
          ),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  item.toString(),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 17.sp,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  static int _getDaysInMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return Jalali(year).isLeapYear() ? 30 : 29;
  }

  /// ساخت فیلد تاریخ تولد
  static Widget buildBirthDateField(
    BuildContext context,
    Map<String, dynamic> profileData,
    VoidCallback onTap,
  ) {
    String displayValue = 'تاریخ تولد انتخاب نشده';
    DateTime? birthDate;

    if (profileData['birth_date'] != null) {
      try {
        final dateStr = profileData['birth_date'].toString();
        if (dateStr.isNotEmpty && dateStr != 'null') {
          birthDate = DateTime.parse(dateStr);
          final jalali = Jalali.fromDateTime(birthDate);
          final monthNames = [
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
          displayValue =
              '${jalali.day} ${monthNames[jalali.month]} ${jalali.year}';
        }
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(LucideIcons.calendar, color: AppTheme.goldColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تاریخ تولد',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayValue,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: birthDate != null
                            ? context.textColor
                            : context.textSecondary,
                        fontSize: 16.sp,
                        fontWeight: birthDate != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.edit3, color: AppTheme.goldColor, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}

