import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// نوار هفته شمسی به سبک Hevy/Strong — ناوبری اصلی تاریخ.
///
/// سوایپ راست = هفتهٔ قبل | سوایپ چپ = هفتهٔ بعد
class WorkoutWeekDateStrip extends StatefulWidget {
  const WorkoutWeekDateStrip({
    required this.selectedDate,
    required this.onDateSelected,
    this.onOpenCalendar,
    this.enabled = true,
    super.key,
  });

  final Jalali selectedDate;
  final ValueChanged<Jalali> onDateSelected;
  final VoidCallback? onOpenCalendar;
  final bool enabled;

  @override
  State<WorkoutWeekDateStrip> createState() => _WorkoutWeekDateStripState();
}

class _WorkoutWeekDateStripState extends State<WorkoutWeekDateStrip> {
  late Jalali _visibleSaturday;
  Set<String> _loggedKeys = {};
  double _dragDx = 0;

  /// برای انیمیشن جهت اسلاید: ۱ = به آینده، −۱ = به گذشته
  int _slideDir = 0;

  @override
  void initState() {
    super.initState();
    _visibleSaturday = _saturdayOf(widget.selectedDate);
    unawaited(_loadLoggedForWeek(_visibleSaturday));
  }

  @override
  void didUpdateWidget(covariant WorkoutWeekDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameDay(oldWidget.selectedDate, widget.selectedDate)) {
      final target = _saturdayOf(widget.selectedDate);
      if (!_sameDay(target, _visibleSaturday)) {
        final goingFuture =
            _dayIndex(target) > _dayIndex(_visibleSaturday);
        setState(() {
          _slideDir = goingFuture ? 1 : -1;
          _visibleSaturday = target;
        });
        unawaited(_loadLoggedForWeek(target));
      }
    }
  }

  /// shamsi: weekDay ۱ = شنبه … ۷ = جمعه
  static Jalali _saturdayOf(Jalali d) => d.addDays(-(d.weekDay - 1));

  static bool _sameDay(Jalali a, Jalali b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int _dayIndex(Jalali j) {
    final g = j.toGregorian();
    return DateTime.utc(g.year, g.month, g.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  static String _key(Jalali j) {
    final g = j.toGregorian();
    final m = g.month.toString().padLeft(2, '0');
    final d = g.day.toString().padLeft(2, '0');
    return '${g.year}-$m-$d';
  }

  void _shiftWeek(int weeks) {
    if (!widget.enabled || weeks == 0) return;
    final next = _visibleSaturday.addDays(weeks * 7);
    setState(() {
      _slideDir = weeks;
      _visibleSaturday = next;
    });
    HapticFeedback.selectionClick();
    unawaited(_loadLoggedForWeek(next));
  }

  Future<void> _loadLoggedForWeek(Jalali saturday) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final end = saturday.addDays(6);
    final startG = saturday.toGregorian();
    final endG = end.toGregorian();
    final startStr =
        '${startG.year}-${startG.month.toString().padLeft(2, '0')}-${startG.day.toString().padLeft(2, '0')}';
    final endStr =
        '${endG.year}-${endG.month.toString().padLeft(2, '0')}-${endG.day.toString().padLeft(2, '0')}';
    try {
      final response = await Supabase.instance.client
          .from('workout_daily_logs')
          .select('log_date')
          .eq('user_id', user.id)
          .gte('log_date', startStr)
          .lte('log_date', endStr);
      final keys = <String>{};
      for (final row in response as List) {
        final raw = row['log_date'].toString();
        if (raw.length >= 10) {
          keys.add(raw.substring(0, 10));
        } else {
          final parsed = DateTime.tryParse(raw);
          if (parsed == null) continue;
          keys.add(
            '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}',
          );
        }
      }
      if (!mounted || !_sameDay(saturday, _visibleSaturday)) return;
      setState(() => _loggedKeys = keys);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedDate;
    final friday = _visibleSaturday.addDays(6);
    final selectedInView =
        _dayIndex(selected) >= _dayIndex(_visibleSaturday) &&
        _dayIndex(selected) <= _dayIndex(friday);
    final isToday = _sameDay(selected, Jalali.now());
    final title = _selectedDayTitle(selected);

    return Material(
      color: WorkoutLogColors.sectionBackground(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 2.h),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.enabled ? widget.onOpenCalendar : null,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ثبت برای',
                            style: WorkoutLogTypography.caption(
                              context,
                              color: WorkoutLogColors.mutedText(context),
                              fontWeight: FontWeight.w700,
                            ).copyWith(fontSize: 10.sp),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: WorkoutLogTypography.sectionTitle(
                                    context,
                                  ).copyWith(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (isToday) ...[
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldColor.withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'امروز',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.goldColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (!selectedInView) ...[
                            SizedBox(height: 2.h),
                            Text(
                              'یک روز از این هفته را بزن تا تاریخ ثبت عوض شود',
                              style: WorkoutLogTypography.caption(
                                context,
                                color: WorkoutLogColors.mutedText(context),
                              ).copyWith(fontSize: 10.sp),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.onOpenCalendar != null)
                  IconButton(
                    tooltip: 'تقویم',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        BoxConstraints.tightFor(width: 34.w, height: 34.w),
                    onPressed: widget.enabled ? widget.onOpenCalendar : null,
                    icon: Icon(
                      LucideIcons.calendarDays,
                      size: 17.sp,
                      color: widget.enabled
                          ? WorkoutLogColors.secondaryText(context)
                          : WorkoutLogColors.mutedText(context),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: const Row(
              children: [
                _WeekdayLabel('ش'),
                _WeekdayLabel('ی'),
                _WeekdayLabel('د'),
                _WeekdayLabel('س'),
                _WeekdayLabel('چ'),
                _WeekdayLabel('پ'),
                _WeekdayLabel('ج'),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => _dragDx = 0,
            onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
            onHorizontalDragEnd: (d) {
              if (!widget.enabled) return;
              final v = d.primaryVelocity ?? 0;
              // فلش‌ها درست‌اند؛ در RTL علامت dx برعکس حس می‌شود → معکوس سوایپ
              if (v < -280 || _dragDx < -48) {
                _shiftWeek(-1);
              } else if (v > 280 || _dragDx > 48) {
                _shiftWeek(1);
              }
              _dragDx = 0;
            },
            child: SizedBox(
              height: 52.h,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final begin = Offset(_slideDir >= 0 ? 0.18 : -0.18, 0);
                  return ClipRect(
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: begin,
                        end: Offset.zero,
                      ).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                  );
                },
                child: Padding(
                  key: ValueKey<String>(_key(_visibleSaturday)),
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Row(
                    children: List.generate(7, (i) {
                      final day = _visibleSaturday.addDays(i);
                      final isSelected = _sameDay(day, selected);
                      final isTodayCell = _sameDay(day, Jalali.now());
                      final hasLog = _loggedKeys.contains(_key(day));
                      return Expanded(
                        child: _DayCell(
                          day: day,
                          isSelected: isSelected,
                          isToday: isTodayCell,
                          hasLog: hasLog,
                          enabled: widget.enabled,
                          onTap: () {
                            if (!widget.enabled) return;
                            HapticFeedback.selectionClick();
                            widget.onDateSelected(day);
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Divider(
            height: 1,
            thickness: 1,
            color: WorkoutLogColors.inputBorder(context),
          ),
        ],
      ),
    );
  }

  /// تاریخ کامل روزی که ست‌ها برایش ثبت می‌شوند.
  static String _selectedDayTitle(Jalali d) {
    final weekDay = MealLogUtils.getPersianWeekDay(d.weekDay);
    final month = MealLogUtils.getPersianMonthName(d.month);
    final dayFa = MealLogUtils.convertToPersianNumbers('${d.day}');
    final yearFa = MealLogUtils.convertToPersianNumbers('${d.year}');
    return '$weekDay $dayFa $month $yearFa';
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: WorkoutLogTypography.caption(
            context,
            color: WorkoutLogColors.mutedText(context),
            fontWeight: FontWeight.w700,
          ).copyWith(fontSize: 10.sp),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasLog,
    required this.enabled,
    required this.onTap,
  });

  final Jalali day;
  final bool isSelected;
  final bool isToday;
  final bool hasLog;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayFa = MealLogUtils.convertToPersianNumbers('${day.day}');
    final bg = isSelected ? AppTheme.goldColor : Colors.transparent;
    final fg = isSelected
        ? Colors.black
        : WorkoutLogColors.primaryText(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10.r),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: isToday && !isSelected
                  ? Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.55),
                    )
                  : null,
            ),
            child: SizedBox(
              height: 44.h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayFa,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: enabled
                          ? fg
                          : WorkoutLogColors.mutedText(context),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Container(
                    width: 5.w,
                    height: 5.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasLog
                          ? (isSelected
                              ? Colors.black.withValues(alpha: 0.75)
                              : WorkoutLogColors.successSolid(context))
                          : Colors.transparent,
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
