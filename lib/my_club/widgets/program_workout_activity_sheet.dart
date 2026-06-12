import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/my_club/models/program_activity_filter.dart';
import 'package:gymaipro/my_club/services/program_workout_activity_service.dart';
import 'package:gymaipro/my_club/widgets/program_activity_calendar.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// پیش‌نمایش مینیمال اجرای برنامه تمرینی: تقویم + جزئیات همان برنامه.
class ProgramWorkoutActivitySheet extends StatefulWidget {
  const ProgramWorkoutActivitySheet({
    required this.programTitle,
    required this.filter,
    required this.onOpenWorkoutLog,
    super.key,
  });

  final String programTitle;
  final ProgramActivityFilter filter;
  final VoidCallback onOpenWorkoutLog;

  static Future<void> show(
    BuildContext context, {
    required String programTitle,
    required ProgramActivityFilter filter,
    required VoidCallback onOpenWorkoutLog,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProgramWorkoutActivitySheet(
        programTitle: programTitle,
        filter: filter,
        onOpenWorkoutLog: onOpenWorkoutLog,
      ),
    );
  }

  @override
  State<ProgramWorkoutActivitySheet> createState() =>
      _ProgramWorkoutActivitySheetState();
}

class _ProgramWorkoutActivitySheetState extends State<ProgramWorkoutActivitySheet> {
  final _service = ProgramWorkoutActivityService();
  bool _loading = true;
  ProgramWorkoutActivityData? _data;
  late Jalali _focusedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final anchor = widget.filter.validTo.isBefore(DateTime.now())
        ? widget.filter.validTo
        : DateTime.now();
    _focusedMonth = Jalali.fromDateTime(anchor);
    _focusedMonth = Jalali(_focusedMonth.year, _focusedMonth.month);
    _selectedDate = ProgramActivityFilter.dateOnly(anchor);
    _load();
  }

  Future<void> _load() async {
    final data = await _service.load(widget.filter);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      _pickInitialSelection(data);
    });
  }

  void _pickInitialSelection(ProgramWorkoutActivityData? data) {
    if (data == null || data.logsByDay.isEmpty) return;
    final today = ProgramActivityFilter.dateOnly(DateTime.now());
    if (widget.filter.containsDate(today) && data.logForDate(today) != null) {
      _selectedDate = today;
      return;
    }
    final latest = data.logsByDay.values
        .map((l) => ProgramActivityFilter.dateOnly(l.logDate))
        .reduce((a, b) => a.isAfter(b) ? a : b);
    _selectedDate = latest;
    _focusedMonth = Jalali.fromDateTime(latest);
    _focusedMonth = Jalali(_focusedMonth.year, _focusedMonth.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      var y = _focusedMonth.year;
      var m = _focusedMonth.month + delta;
      if (m > 12) {
        m = 1;
        y++;
      } else if (m < 1) {
        m = 12;
        y--;
      }
      _focusedMonth = Jalali(y, m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardColor : AppTheme.darkTextColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'پیش‌نمایش اجرا',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? AppTheme.goldColor : context.textColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.programTitle,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      LucideIcons.x,
                      color: context.textSecondary,
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 48.h),
                child: const CircularProgressIndicator(color: AppTheme.goldColor),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_data != null && _data!.loggedDayCount > 0)
                        Text(
                          '${_data!.loggedDayCount} روز با این برنامه',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            color: AppTheme.goldColor,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          'هنوز ثبتی برای این برنامه نیست',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            color: context.textSecondary,
                          ),
                        ),
                      SizedBox(height: 12.h),
                      ProgramActivityCalendar(
                        focusedMonth: _focusedMonth,
                        loggedDayKeys: _data?.logsByDay.keys.toSet() ?? {},
                        validFrom: widget.filter.validFrom,
                        validTo: widget.filter.validTo,
                        selectedDate: _selectedDate,
                        onMonthShift: _shiftMonth,
                        onDaySelected: (d) => setState(() => _selectedDate = d),
                      ),
                      SizedBox(height: 16.h),
                      _buildDayDetail(context),
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onOpenWorkoutLog();
                          },
                          icon: Icon(LucideIcons.dumbbell, size: 18.sp),
                          label: const Text(
                            'رفتن به ثبت تمرین',
                            style: TextStyle(fontFamily: AppTheme.fontFamily),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldColor,
                            foregroundColor: AppTheme.onGoldColor,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetail(BuildContext context) {
    if (_selectedDate == null) {
      return _emptyDayMessage(context, 'یک روز را از تقویم انتخاب کنید');
    }
    if (!widget.filter.containsDate(_selectedDate!)) {
      return _emptyDayMessage(
        context,
        'این روز خارج از بازه اعتبار این برنامه است',
      );
    }

    final log = _data?.logForDate(_selectedDate!);
    if (log == null) {
      return _emptyDayMessage(
        context,
        'در این روز ثبت مربوط به این برنامه نیست',
      );
    }

    final dateLabel = MealLogUtils.getPersianFormattedDate(_selectedDate!);
    final lines = _buildExerciseLines(log);
    if (lines.isEmpty) {
      return _emptyDayMessage(context, 'داده‌ای برای این روز ثبت نشده');
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: context.separatorColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.calendarCheck,
                size: 16.sp,
                color: AppTheme.goldColor,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
              ),
              Text(
                '${lines.length} تمرین',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.sp,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...lines.map(
            (line) => _ExercisePreviewRow(
              line: line,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyDayMessage(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13.sp,
          color: context.textSecondary,
        ),
      ),
    );
  }

  List<_ExercisePreviewLine> _buildExerciseLines(WorkoutDailyLog log) {
    final lines = <_ExercisePreviewLine>[];
    for (final session in log.sessions) {
      for (final exercise in session.exercises) {
        if (exercise is NormalExerciseLog) {
          final summary = _summarizeSets(exercise.sets, exercise.style);
          if (summary.isEmpty) continue;
          lines.add(
            _ExercisePreviewLine(
              name: exercise.exerciseName.isNotEmpty
                  ? exercise.exerciseName
                  : (exercise.tag.isNotEmpty ? exercise.tag : 'تمرین'),
              setsSummary: summary,
            ),
          );
        } else if (exercise is SupersetExerciseLog) {
          for (final item in exercise.exercises) {
            final summary = _summarizeSets(item.sets, exercise.style);
            if (summary.isEmpty) continue;
            lines.add(
              _ExercisePreviewLine(
                name: item.exerciseName.isNotEmpty
                    ? item.exerciseName
                    : 'سوپرست',
                setsSummary: summary,
              ),
            );
          }
        }
      }
    }
    return lines;
  }

  String _summarizeSets(List<ExerciseSetLog> sets, String style) {
    final parts = <String>[];
    for (final set in sets) {
      if (!_setHasValue(set)) continue;
      if (style == 'sets_time' || style == 'time') {
        if (set.seconds != null && set.seconds! > 0) {
          parts.add('${set.seconds}ث');
        }
      } else if (set.weight != null &&
          set.weight! > 0 &&
          set.reps != null &&
          set.reps! > 0) {
        final w = set.weight! % 1 == 0
            ? set.weight!.toInt().toString()
            : set.weight.toString();
        parts.add('$w×${set.reps}');
      } else if (set.reps != null && set.reps! > 0) {
        parts.add('${set.reps}');
      } else if (set.seconds != null && set.seconds! > 0) {
        parts.add('${set.seconds}ث');
      }
    }
    return parts.join('  ');
  }

  bool _setHasValue(ExerciseSetLog set) {
    return (set.reps != null && set.reps! > 0) ||
        (set.seconds != null && set.seconds! > 0) ||
        (set.weight != null && set.weight! > 0);
  }
}

class _ExercisePreviewLine {
  const _ExercisePreviewLine({required this.name, required this.setsSummary});
  final String name;
  final String setsSummary;
}

class _ExercisePreviewRow extends StatelessWidget {
  const _ExercisePreviewRow({required this.line, required this.isDark});
  final _ExercisePreviewLine line;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            margin: EdgeInsets.only(top: 6.h, left: 8.w),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  line.name,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                if (line.setsSummary.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    line.setsSummary,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: context.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
