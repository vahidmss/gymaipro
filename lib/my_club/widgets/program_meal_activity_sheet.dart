import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/food_log.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/my_club/models/program_activity_filter.dart';
import 'package:gymaipro/my_club/services/program_meal_activity_service.dart';
import 'package:gymaipro/my_club/widgets/program_activity_calendar.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// پیش‌نمایش ثبت غذا برای همان برنامه رژیمی.
class ProgramMealActivitySheet extends StatefulWidget {
  const ProgramMealActivitySheet({
    required this.planTitle,
    required this.filter,
    required this.onOpenMealLog,
    super.key,
  });

  final String planTitle;
  final ProgramActivityFilter filter;
  final VoidCallback onOpenMealLog;

  static Future<void> show(
    BuildContext context, {
    required String planTitle,
    required ProgramActivityFilter filter,
    required VoidCallback onOpenMealLog,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProgramMealActivitySheet(
        planTitle: planTitle,
        filter: filter,
        onOpenMealLog: onOpenMealLog,
      ),
    );
  }

  @override
  State<ProgramMealActivitySheet> createState() => _ProgramMealActivitySheetState();
}

class _ProgramMealActivitySheetState extends State<ProgramMealActivitySheet> {
  final _service = ProgramMealActivityService();
  bool _loading = true;
  ProgramMealActivityData? _data;
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

  void _pickInitialSelection(ProgramMealActivityData? data) {
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
                          'پیش‌نمایش تغذیه',
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
                          widget.planTitle,
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
                            widget.onOpenMealLog();
                          },
                          icon: Icon(LucideIcons.utensils, size: 18.sp),
                          label: const Text(
                            'رفتن به ثبت تغذیه',
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

    final meals = _mealsForPlan(log);
    if (meals.isEmpty) {
      return _emptyDayMessage(context, 'غذایی از این برنامه ثبت نشده');
    }

    final dateLabel = MealLogUtils.getPersianFormattedDate(_selectedDate!);
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
              Icon(LucideIcons.calendarCheck, size: 16.sp, color: AppTheme.goldColor),
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
                '${meals.length} وعده',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.sp,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...meals.map((m) => _MealPreviewRow(meal: m)),
        ],
      ),
    );
  }

  List<_MealPreviewLine> _mealsForPlan(FoodLog log) {
    final planId = widget.filter.programId;
    final lines = <_MealPreviewLine>[];
    for (final meal in log.meals) {
      final planFoods =
          meal.foods.where((f) => f.mealPlanId == planId).toList();
      if (planFoods.isEmpty) continue;
      lines.add(
        _MealPreviewLine(
          title: meal.title,
          detail: '${planFoods.length} مورد ثبت شده',
        ),
      );
    }
    return lines;
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
}

class _MealPreviewLine {
  const _MealPreviewLine({required this.title, required this.detail});
  final String title;
  final String detail;
}

class _MealPreviewRow extends StatelessWidget {
  const _MealPreviewRow({required this.meal});
  final _MealPreviewLine meal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            MealLogUtils.getMealIcon(meal.title),
            size: 16.sp,
            color: AppTheme.goldColor.withValues(alpha: 0.85),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  meal.title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                Text(
                  meal.detail,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.sp,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
