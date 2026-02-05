import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_meal_log.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/utils/responsive_dialog_utils.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/widgets/gold_button.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersianFoodLogDatePickerDialog extends StatefulWidget {
  const PersianFoodLogDatePickerDialog({
    required this.selectedDate,
    required this.onDateSelected,
    this.preloadedFoodLogDates,
    this.preloadedCaloriesByDate,
    super.key,
  });
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  final Map<DateTime, bool>? preloadedFoodLogDates;
  final Map<DateTime, double>? preloadedCaloriesByDate;

  @override
  State<PersianFoodLogDatePickerDialog> createState() =>
      _PersianFoodLogDatePickerDialogState();
}

class _PersianFoodLogDatePickerDialogState
    extends State<PersianFoodLogDatePickerDialog> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  Map<DateTime, bool> _foodLogDates = {};
  Map<DateTime, double> _caloriesByDate = {};
  final FoodService _foodService = FoodService();
  List<Food> _allFoods = [];

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedDate;
    _selectedDate = widget.selectedDate;

    // استفاده از داده‌های پیش‌بارگذاری شده اگر موجود باشند
    if (widget.preloadedFoodLogDates != null &&
        widget.preloadedCaloriesByDate != null) {
      _foodLogDates = widget.preloadedFoodLogDates!;
      _caloriesByDate = widget.preloadedCaloriesByDate!;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    // بارگذاری لیست غذاها
    try {
      _allFoods = await _foodService.getFoods();
    } catch (e) {
      debugPrint('Error loading foods: $e');
    }
    // بارگذاری log ها و محاسبه کالری
    await _loadFoodLogDates();
  }

  Future<void> _loadFoodLogDates() async {
    final client = Supabase.instance.client;
    final profile = await SimpleProfileService.getCurrentProfile();
    final userId = (profile?['id'] as String?) ?? client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // محاسبه محدوده تاریخ ماه جاری
      final gregorian = Gregorian.fromDateTime(_currentMonth);
      final jalali = gregorian.toJalali();
      final startJalali = Jalali(jalali.year, jalali.month, 1);
      final endJalali = Jalali(
        jalali.year,
        jalali.month,
        _getDaysInMonth(jalali.year, jalali.month),
      );
      final startDate = startJalali.toGregorian().toDateTime();
      final endDate = endJalali.toGregorian().toDateTime();

      // بررسی اینکه آیا داده‌های پیش‌بارگذاری شده برای این ماه موجود هستند
      final now = DateTime.now();
      final nowGregorian = Gregorian.fromDateTime(now);
      final nowJalali = nowGregorian.toJalali();
      final isCurrentMonth =
          jalali.year == nowJalali.year && jalali.month == nowJalali.month;

      if (isCurrentMonth &&
          widget.preloadedFoodLogDates != null &&
          widget.preloadedCaloriesByDate != null) {
        // فیلتر کردن فقط روزهای این ماه از داده‌های پیش‌بارگذاری شده
        final Map<DateTime, bool> logDates = {};
        final Map<DateTime, double> caloriesMap = {};

        widget.preloadedFoodLogDates!.forEach((date, hasLog) {
          if (date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              date.isBefore(endDate.add(const Duration(days: 1)))) {
            logDates[date] = hasLog;
            if (widget.preloadedCaloriesByDate!.containsKey(date)) {
              caloriesMap[date] = widget.preloadedCaloriesByDate![date]!;
            }
          }
        });

        SafeSetState.call(this, () {
          _foodLogDates = logDates;
          _caloriesByDate = caloriesMap;
        });
        return;
      }

      // اگر داده‌های پیش‌بارگذاری شده موجود نیستند یا ماه جاری نیست، از دیتابیس لود کن
      final startDateString = startDate.toIso8601String().substring(0, 10);
      final endDateString = endDate.toIso8601String().substring(0, 10);

      final response = await client
          .from('food_logs')
          .select('log_date, meals')
          .eq('user_id', userId)
          .gte('log_date', startDateString)
          .lte('log_date', endDateString);

      final Map<DateTime, bool> logDates = {};
      final Map<DateTime, double> caloriesMap = {};

      for (final entry in response) {
        if (entry['log_date'] != null) {
          final date = DateTime.parse(entry['log_date'] as String);
          final dateKey = DateTime(date.year, date.month, date.day);
          logDates[dateKey] = true;

          // محاسبه کالری برای این روز
          if (entry['meals'] != null) {
            try {
              final mealsJson = entry['meals'] as List<dynamic>;
              final meals = mealsJson
                  .map((m) => FoodMealLog.fromJson(m as Map<String, dynamic>))
                  .toList();

              final totals = MealLogUtils.calculateTotals(meals, _allFoods);
              caloriesMap[dateKey] = totals['calories'] ?? 0;
            } catch (e) {
              debugPrint('Error calculating calories for date: $e');
              caloriesMap[dateKey] = 0;
            }
          }
        }
      }
      SafeSetState.call(this, () {
        _foodLogDates = logDates;
        _caloriesByDate = caloriesMap;
      });
    } catch (e) {
      debugPrint('Error loading food log dates: $e');
    }
  }

  int _getDaysInMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return Jalali(year).isLeapYear() ? 30 : 29;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: ResponsiveDialogUtils.getStandardInsetPadding(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveDialogUtils.getStandardBorderRadius(context),
        ),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveDialogUtils.getStandardMaxWidth(context),
        ),
        decoration: BoxDecoration(
          color: isDark
              ? context.backgroundColor
              : context.cardColor, // رنگ solid برای عدم شفافیت
          borderRadius: BorderRadius.circular(
            ResponsiveDialogUtils.getStandardBorderRadius(context),
          ),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: 20.r,
              offset: Offset(0.w, 8.h),
              spreadRadius: 2.r,
            ),
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 12.r,
              offset: Offset(0.w, 4.h),
              spreadRadius: 1.r,
            ),
          ],
        ),
        child: Container(
          padding: ResponsiveDialogUtils.getStandardDialogPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCalendarHeader(context),
              SizedBox(height: 20.h),
              _buildCalendarGrid(context),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(
                            color: AppTheme.goldColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Text(
                        'لغو',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor.withValues(alpha: 0.7),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GoldButton(
                      text: 'انتخاب',
                      onPressed: () {
                        widget.onDateSelected(_selectedDate);
                        Navigator.of(context).pop();
                      },
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

  Widget _buildCalendarHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.08),
                  AppTheme.goldColor.withValues(alpha: 0.03),
                ],
              ),
        color: isDark
            ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                LucideIcons.chevronRight,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
              onPressed: () {
                SafeSetState.call(this, () {
                  // تبدیل به شمسی و کم کردن یک ماه از تقویم شمسی
                  final gregorian = Gregorian.fromDateTime(_currentMonth);
                  final jalali = gregorian.toJalali();
                  int newYear = jalali.year;
                  int newMonth = jalali.month - 1;
                  if (newMonth < 1) {
                    newMonth = 12;
                    newYear--;
                  }
                  final newJalali = Jalali(newYear, newMonth, 1);
                  _currentMonth = newJalali.toGregorian().toDateTime();
                });
                _loadFoodLogDates();
              },
            ),
          ),
          Column(
            children: [
              Text(
                _getPersianMonthName(_getPersianMonthNumber()),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark ? AppTheme.goldColor : context.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _convertToPersianNumbers(_getPersianYear().toString()),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textColor.withValues(alpha: 0.6),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                LucideIcons.chevronLeft,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
              onPressed: () {
                SafeSetState.call(this, () {
                  // تبدیل به شمسی و اضافه کردن یک ماه به تقویم شمسی
                  final gregorian = Gregorian.fromDateTime(_currentMonth);
                  final jalali = gregorian.toJalali();
                  int newYear = jalali.year;
                  int newMonth = jalali.month + 1;
                  if (newMonth > 12) {
                    newMonth = 1;
                    newYear++;
                  }
                  final newJalali = Jalali(newYear, newMonth, 1);
                  _currentMonth = newJalali.toGregorian().toDateTime();
                });
                _loadFoodLogDates();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    final int daysInMonth = _getDaysInMonth(jalali.year, jalali.month);
    final firstDayOfPersianMonth = Jalali(jalali.year, jalali.month);
    final firstWeekdayPersian = firstDayOfPersianMonth.weekDay;
    final emptyBoxes = firstWeekdayPersian - 1;
    final totalCells = emptyBoxes + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          _buildWeekdayHeaders(context),
          SizedBox(height: 8.h),
          ...List.generate(
            weeks,
            (weekIndex) => _buildWeekRow(
              context,
              weekIndex,
              emptyBoxes,
              daysInMonth,
              jalali.year,
              jalali.month,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    return Row(
      children: weekdays
          .map(
            (day) => Expanded(
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark
                          ? AppTheme.goldColor.withValues(alpha: 0.8)
                          : context.textColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildWeekRow(
    BuildContext context,
    int weekIndex,
    int emptyBoxes,
    int daysInMonth,
    int year,
    int month,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startCell = weekIndex * 7;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: List.generate(7, (dayIndex) {
          final cellIndex = startCell + dayIndex;
          final dayNumber = cellIndex - emptyBoxes + 1;
          if (dayNumber < 1 || dayNumber > daysInMonth) {
            return Expanded(child: Container());
          }
          final persianDate = Jalali(year, month, dayNumber);
          final gregorianDate = persianDate.toGregorian().toDateTime();
          final dateKey = DateTime(
            gregorianDate.year,
            gregorianDate.month,
            gregorianDate.day,
          );
          final hasFoodLog = _foodLogDates.containsKey(dateKey);
          final calories = _caloriesByDate[dateKey] ?? 0;
          final isSelected =
              _selectedDate.year == gregorianDate.year &&
              _selectedDate.month == gregorianDate.month &&
              _selectedDate.day == gregorianDate.day;
          final now = DateTime.now();
          final isToday =
              now.year == gregorianDate.year &&
              now.month == gregorianDate.month &&
              now.day == gregorianDate.day;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                SafeSetState.call(this, () {
                  _selectedDate = gregorianDate;
                });
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
                height: hasFoodLog ? 56.h : 44.h,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.goldColor, AppTheme.darkGold],
                        )
                      : hasFoodLog
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Colors.green.withValues(alpha: 0.15),
                                  Colors.green.withValues(alpha: 0.1),
                                ]
                              : [
                                  Colors.green.withValues(alpha: 0.12),
                                  Colors.green.withValues(alpha: 0.08),
                                ],
                        )
                      : null,
                  color: isSelected || hasFoodLog
                      ? null
                      : (isDark
                            ? AppTheme.darkGreySeparator.withValues(alpha: 0.2)
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isToday
                        ? AppTheme.goldColor.withValues(alpha: 0.6)
                        : isSelected
                        ? AppTheme.goldColor
                        : Colors.transparent,
                    width: isToday ? 2 : (isSelected ? 1.5 : 0),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.goldColor.withValues(alpha: 0.4),
                            blurRadius: 8.r,
                            offset: Offset(0.w, 3.h),
                            spreadRadius: 1.r,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _convertToPersianNumbers(dayNumber.toString()),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isSelected
                            ? AppTheme.onGoldColor
                            : hasFoodLog
                            ? (isDark ? Colors.green[300] : Colors.green[700])
                            : context.textColor,
                        fontWeight: isSelected || hasFoodLog || isToday
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14.sp,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (hasFoodLog && calories > 0) ...[
                      SizedBox(height: 2.h),
                      Text(
                        textAlign: TextAlign.center,
                        '${_convertToPersianNumbers(calories.toStringAsFixed(0))} کالری',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isSelected
                              ? AppTheme.onGoldColor.withValues(alpha: 0.9)
                              : (isDark
                                    ? Colors.green[300]
                                    : Colors.green[700]),
                          fontWeight: FontWeight.w600,
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

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

  String _convertToPersianNumbers(String text) {
    const persianNumbers = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = text;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(englishNumbers[i], persianNumbers[i]);
    }
    return result;
  }

  int _getPersianMonthNumber() {
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    return jalali.month;
  }

  int _getPersianYear() {
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    return jalali.year;
  }
}
