import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/widgets/gold_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersianDatePickerDialog extends StatefulWidget {
  const PersianDatePickerDialog({
    required this.selectedDate,
    required this.onDateSelected,
    super.key,
  });
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;

  @override
  State<PersianDatePickerDialog> createState() =>
      _PersianDatePickerDialogState();
}

class _PersianDatePickerDialogState extends State<PersianDatePickerDialog> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  Map<DateTime, bool> _workoutLogDates = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedDate;
    _selectedDate = widget.selectedDate;
    _loadWorkoutLogDates();
  }

  Future<void> _loadWorkoutLogDates() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

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

    try {
      final response = await Supabase.instance.client
          .from('workout_daily_logs')
          .select('log_date')
          .eq('user_id', user.id)
          .gte('log_date', startDate.toIso8601String().substring(0, 10))
          .lte('log_date', endDate.toIso8601String().substring(0, 10));

      final logDates = <DateTime, bool>{};
      for (final row in response) {
        final logDateStr = row['log_date'].toString();
        final logDate = DateTime.parse(logDateStr);
        final dateKey = DateTime(logDate.year, logDate.month, logDate.day);
        logDates[dateKey] = true;
      }

      SafeSetState.call(this, () {
        _workoutLogDates = logDates;
      });
    } catch (e) {
      debugPrint('Error loading workout log dates: $e');
      SafeSetState.call(this, () {
        _workoutLogDates = {};
      });
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
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? context.backgroundColor
              : context.cardColor,
          borderRadius: BorderRadius.circular(24.r),
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
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(24.w),
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
                color: WorkoutLogColors.iconOnSurface(context),
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
                _loadWorkoutLogDates();
              },
            ),
          ),
          Column(
            children: [
              Text(
                _getPersianMonthName(_getPersianMonthNumber()),
                style: WorkoutLogTypography.sectionTitle(context).copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _convertToPersianNumbers(_getPersianYear().toString()),
                style: WorkoutLogTypography.dialogMuted(context).copyWith(
                  fontSize: 13.sp,
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
                color: WorkoutLogColors.iconOnSurface(context),
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
                _loadWorkoutLogDates();
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
                    style: WorkoutLogTypography.fieldLabel(context).copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: WorkoutLogColors.secondaryText(context),
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
          final hasWorkoutLog = _workoutLogDates.containsKey(dateKey);
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
                height: hasWorkoutLog ? 56.h : 44.h,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.goldColor, AppTheme.darkGold],
                        )
                      : hasWorkoutLog
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
                  color: isSelected || hasWorkoutLog
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
                            ? WorkoutLogColors.onGoldSurface(context)
                            : hasWorkoutLog
                            ? (isDark
                                  ? const Color(0xFFA5D6A7)
                                  : const Color(0xFF1B5E20))
                            : WorkoutLogColors.primaryText(context),
                        fontWeight: isSelected || hasWorkoutLog || isToday
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14.sp,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (hasWorkoutLog) ...[
                      SizedBox(height: 2.h),
                      Icon(
                        LucideIcons.dumbbell,
                        size: 10.sp,
                        color: isSelected
                            ? WorkoutLogColors.onGoldSurface(context)
                                .withValues(alpha: 0.9)
                            : (isDark
                                  ? const Color(0xFFA5D6A7)
                                  : const Color(0xFF1B5E20)),
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
