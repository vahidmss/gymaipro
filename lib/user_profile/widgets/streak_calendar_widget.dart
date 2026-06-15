import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Widget برای نمایش زنجیره فعالیت (Streak Calendar)
class StreakCalendarWidget extends StatelessWidget {
  const StreakCalendarWidget({
    required this.streakDates,
    required this.currentStreak,
    required this.longestStreak,
    super.key,
  });

  final List<DateTime> streakDates;
  final int currentStreak;
  final int longestStreak;

  static const List<String> _persianMonthNames = [
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.flame,
                size: 18.sp,
                color: const Color(0xFFFF5722),
              ),
              SizedBox(width: 8.w),
              Text(
                'زنجیره فعالیت',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildChainVisualization(context),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.trophy,
                size: 14.sp,
                color: const Color(0xFFE91E63),
              ),
              SizedBox(width: 6.w),
              Text(
                'رکورد زنجیره: ',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  color: context.textSecondary,
                ),
              ),
              Text(
                '$longestStreak روز متوالی',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE91E63),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChainVisualization(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streakSet = <int>{};
    for (final d in streakDates) {
      streakSet.add(DateTime(d.year, d.month, d.day).millisecondsSinceEpoch);
    }

    final monthsToShow = _getStreakMonths();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.06),
                  AppTheme.goldColor.withValues(alpha: 0.02),
                ],
              ),
        color: isDark
            ? AppTheme.darkGreySeparator.withValues(alpha: 0.25)
            : null,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in monthsToShow) ...[
            if (monthsToShow.indexOf(entry) > 0) SizedBox(height: 16.h),
            _buildSingleMonthCalendar(
              context,
              year: entry.$1,
              month: entry.$2,
              streakSet: streakSet,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  List<(int year, int month)> _getStreakMonths() {
    if (streakDates.isEmpty) {
      final now = DateTime.now();
      final j = Jalali.fromDateTime(now);
      return [(j.year, j.month)];
    }
    final set = <(int, int)>{};
    for (final d in streakDates) {
      final j = Jalali.fromDateTime(d);
      set.add((j.year, j.month));
    }
    final list = set.toList()
      ..sort((a, b) {
        if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
        return a.$2.compareTo(b.$2);
      });
    return list;
  }

  int _getJalaliDaysInMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return Jalali(year).isLeapYear() ? 30 : 29;
  }

  Widget _buildSingleMonthCalendar(
    BuildContext context, {
    required int year,
    required int month,
    required Set<int> streakSet,
    required bool isDark,
  }) {
    final daysInMonth = _getJalaliDaysInMonth(year, month);
    final firstDay = Jalali(year, month);
    final firstWeekday = firstDay.weekDay;
    final emptyBoxes = firstWeekday - 1;
    final totalCells = emptyBoxes + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _persianMonthNames[month],
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark ? AppTheme.goldColor : context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '$year',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor.withValues(alpha: 0.6),
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 12.h),
        _buildStreakWeekdayHeaders(context, isDark),
        SizedBox(height: 6.h),
        ...List.generate(
          weeks,
          (weekIndex) => _buildStreakWeekRow(
            context,
            weekIndex,
            emptyBoxes,
            daysInMonth,
            year,
            month,
            streakSet,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakWeekdayHeaders(BuildContext context, bool isDark) {
    const weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    return Row(
      children: weekdays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isDark
                        ? AppTheme.goldColor.withValues(alpha: 0.7)
                        : context.textColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStreakWeekRow(
    BuildContext context,
    int weekIndex,
    int emptyBoxes,
    int daysInMonth,
    int year,
    int month,
    Set<int> streakSet,
    bool isDark,
  ) {
    final startCell = weekIndex * 7;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: List.generate(7, (dayIndex) {
          final cellIndex = startCell + dayIndex;
          final dayNumber = cellIndex - emptyBoxes + 1;
          if (dayNumber < 1 || dayNumber > daysInMonth) {
            return Expanded(child: SizedBox(height: 40.h));
          }
          final persianDate = Jalali(year, month, dayNumber);
          final gregorianDate = persianDate.toGregorian().toDateTime();
          final dateKey = DateTime(
            gregorianDate.year,
            gregorianDate.month,
            gregorianDate.day,
          );
          final isStreak = streakSet.contains(dateKey.millisecondsSinceEpoch);
          final now = DateTime.now();
          final isTodayAndStreak =
              isStreak &&
              now.year == gregorianDate.year &&
              now.month == gregorianDate.month &&
              now.day == gregorianDate.day;
          bool connectLeft = false;
          bool connectRight = false;
          if (isStreak) {
            if (dayIndex > 0 && dayNumber > 1) {
              final leftPersian = Jalali(year, month, dayNumber - 1);
              final leftGreg = leftPersian.toGregorian().toDateTime();
              final leftKey = DateTime(
                leftGreg.year,
                leftGreg.month,
                leftGreg.day,
              );
              connectLeft = streakSet.contains(leftKey.millisecondsSinceEpoch);
            }
            if (dayIndex < 6 && dayNumber < daysInMonth) {
              final rightPersian = Jalali(year, month, dayNumber + 1);
              final rightGreg = rightPersian.toGregorian().toDateTime();
              final rightKey = DateTime(
                rightGreg.year,
                rightGreg.month,
                rightGreg.day,
              );
              connectRight =
                  streakSet.contains(rightKey.millisecondsSinceEpoch);
            }
          }

          return Expanded(
            child: _buildStreakDayCell(
              context,
              dayNumber: dayNumber,
              isStreak: isStreak,
              isTodayAndStreak: isTodayAndStreak,
              connectLeft: connectLeft,
              connectRight: connectRight,
              isDark: isDark,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStreakDayCell(
    BuildContext context, {
    required int dayNumber,
    required bool isStreak,
    required bool isTodayAndStreak,
    required bool connectLeft,
    required bool connectRight,
    required bool isDark,
  }) {
    final radius = 10.r;
    final borderRadius = BorderRadius.horizontal(
      left: Radius.circular(isStreak && !connectLeft ? radius : 4.r),
      right: Radius.circular(isStreak && !connectRight ? radius : 4.r),
    );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isStreak ? 0.5.w : 1.5.w,
        vertical: 1.5.h,
      ),
      height: 40.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isStreak
            ? null
            : (isDark
                  ? AppTheme.darkGreySeparator.withValues(alpha: 0.2)
                  : Colors.transparent),
        gradient: isStreak
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF5722).withValues(alpha: 0.9),
                  const Color(0xFFFF5722).withValues(alpha: 0.75),
                ],
              )
            : null,
        borderRadius: borderRadius,
        border: Border.all(
          color: isTodayAndStreak
              ? AppTheme.goldColor.withValues(alpha: 0.7)
              : Colors.transparent,
          width: isTodayAndStreak ? 1.5 : 0,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isStreak) ...[
              Icon(
                LucideIcons.flame,
                size: 12.sp,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              SizedBox(height: 2.h),
            ] else
              SizedBox(height: 2.h),
            Text(
              '$dayNumber',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                fontWeight: isStreak ? FontWeight.bold : FontWeight.w500,
                color: isStreak ? Colors.white : context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
