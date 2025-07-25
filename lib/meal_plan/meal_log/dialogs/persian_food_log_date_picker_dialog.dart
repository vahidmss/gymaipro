import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/gold_button.dart';

class PersianFoodLogDatePickerDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const PersianFoodLogDatePickerDialog({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<PersianFoodLogDatePickerDialog> createState() =>
      _PersianFoodLogDatePickerDialogState();
}

class _PersianFoodLogDatePickerDialogState
    extends State<PersianFoodLogDatePickerDialog> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  Map<DateTime, bool> _foodLogDates = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedDate;
    _selectedDate = widget.selectedDate;
    _loadFoodLogDates();
  }

  Future<void> _loadFoodLogDates() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    // فقط یک رکورد برای کاربر وجود دارد
    final response = await client
        .from('food_logs')
        .select('logs')
        .eq('user_id', user.id)
        .maybeSingle();

    final Map<DateTime, bool> logDates = {};
    if (response != null && response['logs'] != null) {
      final List logs = response['logs'];
      for (final entry in logs) {
        if (entry['log_date'] != null) {
          final date = DateTime.parse(entry['log_date']);
          logDates[DateTime(date.year, date.month, date.day)] = true;
        }
      }
    }
    setState(() {
      _foodLogDates = logDates;
    });
  }

  int _getDaysInMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return Jalali(year).isLeapYear() ? 30 : 29;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
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
                    child: const Text('لغو',
                        style: TextStyle(color: Colors.white70)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
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
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.goldColor),
          onPressed: () {
            setState(() {
              _currentMonth =
                  DateTime(_currentMonth.year, _currentMonth.month - 1);
            });
            _loadFoodLogDates();
          },
        ),
        Column(
          children: [
            Text(
              _getPersianMonthName(_getPersianMonthNumber()),
              style: const TextStyle(
                color: AppTheme.goldColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _convertToPersianNumbers(_getPersianYear().toString()),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(LucideIcons.chevronRight, color: AppTheme.goldColor),
          onPressed: () {
            setState(() {
              _currentMonth =
                  DateTime(_currentMonth.year, _currentMonth.month + 1);
            });
            _loadFoodLogDates();
          },
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    int daysInMonth = _getDaysInMonth(jalali.year, jalali.month);
    final firstDayOfPersianMonth = Jalali(jalali.year, jalali.month, 1);
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
                weekIndex, emptyBoxes, daysInMonth, jalali.year, jalali.month),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    return Row(
      children: weekdays
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: AppTheme.goldColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildWeekRow(
      int weekIndex, int emptyBoxes, int daysInMonth, int year, int month) {
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
        final hasFoodLog = _foodLogDates.containsKey(DateTime(
            gregorianDate.year, gregorianDate.month, gregorianDate.day));
        final isSelected = _selectedDate.year == gregorianDate.year &&
            _selectedDate.month == gregorianDate.month &&
            _selectedDate.day == gregorianDate.day;
        final now = DateTime.now();
        final isToday = now.year == gregorianDate.year &&
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
              margin: const EdgeInsets.all(2),
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.goldColor
                    : hasFoodLog
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isToday ? AppTheme.goldColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      _convertToPersianNumbers(dayNumber.toString()),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : hasFoodLog
                                ? Colors.green
                                : Colors.white,
                        fontWeight: isSelected || hasFoodLog || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (hasFoodLog)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
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
      'اسفند'
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
