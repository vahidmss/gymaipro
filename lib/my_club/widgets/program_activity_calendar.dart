import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/my_club/models/program_activity_filter.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// تقویم شمسی مینیمال برای پیش‌نمایش روزهای ثبت‌شده.
class ProgramActivityCalendar extends StatelessWidget {
  const ProgramActivityCalendar({
    required this.focusedMonth,
    required this.loggedDayKeys,
    required this.validFrom,
    required this.validTo,
    required this.selectedDate,
    required this.onMonthShift,
    required this.onDaySelected,
    super.key,
  });

  final Jalali focusedMonth;
  final Set<int> loggedDayKeys;
  final DateTime validFrom;
  final DateTime validTo;
  final DateTime? selectedDate;
  final ValueChanged<int> onMonthShift;
  final ValueChanged<DateTime> onDaySelected;

  static const _weekLabels = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
  static const _monthNames = [
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthLength = focusedMonth.monthLength;
    final firstWeekday = Jalali(focusedMonth.year, focusedMonth.month).weekDay;
    final leading = firstWeekday - 1;
    final todayKey =
        ProgramActivityFilter.dateOnly(DateTime.now()).millisecondsSinceEpoch;
    final from = ProgramActivityFilter.dateOnly(validFrom);
    final to = ProgramActivityFilter.dateOnly(validTo);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.veryDarkBackground.withValues(alpha: 0.35)
            : AppTheme.goldColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: context.separatorColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => onMonthShift(-1),
                icon: Icon(LucideIcons.chevronRight, size: 20.sp),
                color: context.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  '${_monthNames[focusedMonth.month]} ${focusedMonth.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onMonthShift(1),
                icon: Icon(LucideIcons.chevronLeft, size: 20.sp),
                color: context.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: _weekLabels
                .map(
                  (l) => Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11.sp,
                          color: context.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 6.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: leading + monthLength,
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final day = index - leading + 1;
              final jalali = Jalali(focusedMonth.year, focusedMonth.month, day);
              final gregorian = jalali.toGregorian().toDateTime();
              final key = ProgramActivityFilter.dateOnly(gregorian).millisecondsSinceEpoch;
              final inRange = !gregorian.isBefore(from) && !gregorian.isAfter(to);
              final hasLog = loggedDayKeys.contains(key);
              final isSelected = selectedDate != null &&
                  ProgramActivityFilter.dateOnly(selectedDate!).millisecondsSinceEpoch ==
                      key;
              final isToday = key == todayKey;

              return GestureDetector(
                onTap: inRange ? () => onDaySelected(gregorian) : null,
                child: Opacity(
                  opacity: inRange ? 1 : 0.35,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.goldColor.withValues(alpha: 0.25)
                          : hasLog
                              ? AppTheme.goldColor.withValues(alpha: 0.12)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                      border: isToday
                          ? Border.all(color: AppTheme.goldColor, width: 1.2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            fontWeight: isSelected || hasLog
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: hasLog || isSelected
                                ? (isDark ? AppTheme.goldColor : AppTheme.darkGold)
                                : context.textSecondary,
                          ),
                        ),
                        if (hasLog && !isSelected)
                          Positioned(
                            bottom: 2,
                            child: Container(
                              width: 4.w,
                              height: 4.w,
                              decoration: const BoxDecoration(
                                color: AppTheme.goldColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
