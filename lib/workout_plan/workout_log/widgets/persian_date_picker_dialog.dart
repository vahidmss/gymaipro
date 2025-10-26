import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    final startJalali = Jalali(jalali.year, jalali.month);
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
        final logDate = DateTime.parse(row['log_date'].toString());
        logDates[logDate] = true;
      }

      setState(() {
        _workoutLogDates = logDates;
      });
    } catch (e) {
      setState(() {
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
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C1810), Color(0xFF3D2317)],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Colors.amber[700]!.withValues(alpha: 0.3),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12.r,
              offset: Offset(0.w, 6.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCalendarHeader(),
            const SizedBox(height: 16),
            _buildCalendarGrid(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    child: Text(
                      'لغو',
                      style: TextStyle(color: Colors.amber[300]),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.amber[600]!, Colors.amber[700]!],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber[700]!.withValues(alpha: 0.4),
                          blurRadius: 6.r,
                          offset: Offset(0.w, 3.h),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onDateSelected(_selectedDate);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'انتخاب',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.amber[700]!.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: Colors.amber[100]),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                );
              });
              _loadWorkoutLogDates();
            },
          ),
        ),
        Column(
          children: [
            Text(
              _getPersianMonthName(_getPersianMonthNumber()),
              style: TextStyle(
                color: Colors.amber[100],
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            Text(
              _convertToPersianNumbers(_getPersianYear().toString()),
              style: TextStyle(color: Colors.amber[300], fontSize: 14),
            ),
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.amber[700]!.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: IconButton(
            icon: Icon(LucideIcons.chevronRight, color: Colors.amber[100]),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                );
              });
              _loadWorkoutLogDates();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
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
          _buildWeekdayHeaders(),
          ...List.generate(
            weeks,
            (weekIndex) => _buildWeekRow(
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

  Widget _buildWeekdayHeaders() {
    const weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    return Row(
      children: weekdays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: Colors.amber[100],
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildWeekRow(
    int weekIndex,
    int emptyBoxes,
    int daysInMonth,
    int year,
    int month,
  ) {
    final startCell = weekIndex * 7;
    return Row(
      children: List.generate(7, (dayIndex) {
        final cellIndex = startCell + dayIndex;
        final dayNumber = cellIndex - emptyBoxes + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return Expanded(child: Container());
        }
        final persianDate = Jalali(year, month, dayNumber);
        final gregorianDate = persianDate.toGregorian().toDateTime();
        final hasWorkoutLog = _workoutLogDates.containsKey(
          DateTime(gregorianDate.year, gregorianDate.month, gregorianDate.day),
        );
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
              setState(() {
                _selectedDate = gregorianDate;
              });
            },
            child: Container(
              margin: EdgeInsets.all(2.w),
              height: 40.h,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.amber[600]!
                    : hasWorkoutLog
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isToday ? Colors.amber[600]! : Colors.transparent,
                  width: 2.w,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      _convertToPersianNumbers(dayNumber.toString()),
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1A1A1A)
                            : hasWorkoutLog
                            ? Colors.green
                            : Colors.amber[100],
                        fontWeight: isSelected || hasWorkoutLog || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  if (hasWorkoutLog)
                    Positioned(
                      bottom: 4.h,
                      left: 0.w,
                      right: 0.w,
                      child: Center(
                        child: Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
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
