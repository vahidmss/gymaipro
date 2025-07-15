import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/workout_program_log.dart';
import '../theme/app_theme.dart';

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
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
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
}

class WorkoutDayDetails extends StatelessWidget {
  final DateTime selectedDate;
  final List<WorkoutProgramLog> workouts;

  const WorkoutDayDetails({
    Key? key,
    required this.selectedDate,
    required this.workouts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
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
            Icon(
              LucideIcons.calendarX,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'هیچ تمرینی در این روز ثبت نشده',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.dumbbell,
                  color: AppTheme.goldColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تمرینات ${_getPersianFormattedDate(selectedDate)}',
                    style: const TextStyle(
                      color: AppTheme.goldColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: workouts
                    .map((workout) => _buildWorkoutItem(workout))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutItem(WorkoutProgramLog workout) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.dumbbell,
                  color: AppTheme.goldColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.programName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${workout.sessions.length} جلسه',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${workout.createdAt.hour.toString().padLeft(2, '0')}:${workout.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: AppTheme.goldColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...workout.sessions
              .map((session) => _buildSessionItem(session))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSessionItem(WorkoutSessionLog session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.day,
            style: const TextStyle(
              color: AppTheme.goldColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          ...session.exercises.map((exercise) {
            if (exercise is NormalExerciseLog) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: AppTheme.goldColor),
                    ),
                    Expanded(
                      child: Text(
                        exercise.exerciseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${exercise.sets.length} ست',
                      style: const TextStyle(
                        color: AppTheme.goldColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ],
      ),
    );
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
