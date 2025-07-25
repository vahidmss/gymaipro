import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/workout_program_log.dart';
import '../theme/app_theme.dart';
import '../screens/workout_log_details_screen.dart';

class WorkoutCalendar extends StatefulWidget {
  final Map<DateTime, List<WorkoutProgramLog>> workoutCalendar;
  final Function(DateTime) onDateSelected;

  const WorkoutCalendar({
    Key? key,
    required this.workoutCalendar,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends State<WorkoutCalendar> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendarHeader(),
        const SizedBox(height: 16),
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon:
                const Icon(LucideIcons.chevronRight, color: AppTheme.goldColor),
            onPressed: () {
              setState(() {
                _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
            },
          ),
          Column(
            children: [
              Text(
                _getPersianMonthName(_currentMonth.month),
                style: const TextStyle(
                  color: AppTheme.goldColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                _currentMonth.year.toString(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          IconButton(
            icon:
                const Icon(LucideIcons.chevronLeft, color: AppTheme.goldColor),
            onPressed: () {
              setState(() {
                _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = firstWeekday - 1 + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildWeekdayHeaders(),
          ...List.generate(
              weeks,
              (weekIndex) =>
                  _buildWeekRow(weekIndex, firstWeekday, daysInMonth)),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
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
      ),
    );
  }

  Widget _buildWeekRow(int weekIndex, int firstWeekday, int daysInMonth) {
    return Row(
      children: List.generate(7, (dayIndex) {
        final cellIndex = weekIndex * 7 + dayIndex;
        final dayNumber = cellIndex - (firstWeekday - 1) + 1;

        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return Expanded(child: Container());
        }

        final date =
            DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
        final hasWorkout = widget.workoutCalendar.containsKey(date);
        final isSelected = _selectedDate.year == date.year &&
            _selectedDate.month == date.month &&
            _selectedDate.day == date.day;
        final isToday = DateTime.now().year == date.year &&
            DateTime.now().month == date.month &&
            DateTime.now().day == date.day;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              if (hasWorkout) {
                _showWorkoutSummaryBottomSheet(context, date);
              }
              widget.onDateSelected(date);
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.goldColor
                    : hasWorkout
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
                      dayNumber.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : hasWorkout
                                ? Colors.green
                                : Colors.white,
                        fontWeight: isSelected || hasWorkout || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (hasWorkout)
                    Positioned(
                      bottom: 6,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.goldColor,
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

  void _showWorkoutSummaryBottomSheet(BuildContext context, DateTime date) {
    final workouts = widget.workoutCalendar[date] ?? [];
    if (workouts.isEmpty) return;
    final workout = workouts.first;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(LucideIcons.dumbbell,
                  color: AppTheme.goldColor, size: 36),
              const SizedBox(height: 12),
              Text(
                'تمرین ثبت شده در ${_getPersianFormattedDate(date)}',
                style: const TextStyle(
                  color: AppTheme.goldColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'برنامه: ${workout.programName}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                'جلسه: ${workout.sessions.isNotEmpty ? workout.sessions.first.day : "-"}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'مجموع ست‌ها: ${workout.sessions.fold<int>(0, (sum, s) => sum + s.exercises.fold<int>(0, (sum2, e) => e is NormalExerciseLog ? sum2 + e.sets.length : sum2))}',
                style: const TextStyle(color: AppTheme.goldColor, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'زمان ثبت: ${workout.createdAt.hour.toString().padLeft(2, '0')}:${workout.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(LucideIcons.info, size: 18),
                label: const Text('جزئیات بیشتر'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkoutLogDetailsScreen(log: workout),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
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

  String _getPersianFormattedDate(DateTime date) {
    final gregorian = Gregorian.fromDateTime(date);
    final jalali = gregorian.toJalali();
    final weekDay = _getPersianWeekDay(date.weekday);
    return '$weekDay ${jalali.day}/${jalali.month}/${jalali.year}';
  }

  String _getPersianWeekDay(int weekday) {
    const weekdays = [
      '',
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنج‌شنبه',
      'جمعه',
      'شنبه',
      'یکشنبه'
    ];
    return weekdays[weekday];
  }
}
