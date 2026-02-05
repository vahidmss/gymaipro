import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_widgets.dart';
import 'package:gymaipro/workout_log/widgets/workout_preview_dialog.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:gymaipro/theme/app_theme.dart';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  late final WorkoutLogViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = WorkoutLogViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.initialize();
  }

  void _onViewModelChanged() {
    if (mounted) {
      WidgetSafetyUtils.safeSetState(this, () {});
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _navigateToExerciseTutorial(int exerciseId) {
    final exercise = _viewModel.exerciseDetails[exerciseId];
    if (exercise != null) {
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          '/exercise-detail',
          arguments: {'exercise': exercise},
        );
      }
    }
  }

  void _toggleExerciseCollapse(String exerciseId) {
    _viewModel.toggleExerciseCollapse(exerciseId);
  }

  Future<void> _onSessionSelected(WorkoutSession? session) async {
    if (session == null) {
      await _viewModel.onSessionSelected(null);
      return;
    }

    // چک کردن اینکه آیا کاربر داده‌هایی در فرم فعلی وارد کرده یا نه
    final hasUnsavedData = _viewModel.hasUnsavedData();
    final hasLoggedSession =
        _viewModel.loggedSessionDay != null &&
        _viewModel.loggedSessionDay != session.day;

    // چک کردن اینکه آیا session فعلی با session جدید متفاوت است یا نه
    final isDifferentSession =
        _viewModel.selectedSession?.day != null &&
        _viewModel.selectedSession!.day != session.day;

    // اگر داده‌ای وارد شده یا session دیگری ثبت شده باشد، دیالوگ نشان بده
    if (hasUnsavedData || hasLoggedSession) {
      final gregorian = _viewModel.selectedDate.toGregorian();
      final dateTime = gregorian.toDateTime();

      String? loggedDay;
      if (hasLoggedSession) {
        // اگر session دیگری در دیتابیس ثبت شده
        loggedDay = _viewModel.loggedSessionDay;
      } else if (hasUnsavedData && isDifferentSession) {
        // اگر داده‌هایی وارد شده و session فعلی با session جدید متفاوت است
        loggedDay = _viewModel.selectedSession!.day;
      }

      // بستن کیبورد قبل از نمایش دیالوگ
      FocusScope.of(context).unfocus();
      _viewModel.unfocusAllFields();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => SessionChangeDialog(
          dateTime: dateTime,
          loggedSessionDay: loggedDay ?? '',
          newSessionDay: session.day,
          hasUnsavedData: hasUnsavedData,
        ),
      );

      if (confirmed != true) {
        // اگر کاربر لغو کرد، مطمئن شو که کیبورد بسته است
        FocusScope.of(context).unfocus();
        _viewModel.unfocusAllFields();
        return;
      }

      // حذف session log قبلی اگر وجود داشته باشد
      if (loggedDay != null && loggedDay.isNotEmpty) {
        await _viewModel.deleteSessionLog(loggedDay);
      }
    }

    await _viewModel.onSessionSelected(session);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gregorian = _viewModel.selectedDate.toGregorian();
    final dateTime = gregorian.toDateTime();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: context.backgroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: isDark
                ? context.backgroundColor
                : Colors.transparent,
            elevation: 0,
          ),
        ),
        child: Container(
          decoration: isDark
              ? null
              : BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.lightGradientStart.withValues(alpha: 0.15),
                      AppTheme.lightCardColor,
                      AppTheme.lightGradientEnd.withValues(alpha: 0.1),
                    ],
                  ),
                ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: WorkoutLogAppBar(
              selectedDate: dateTime,
              onBackPressed: () => NavigationService.safePop(context),
              onDatePickerPressed: _showDatePicker,
              onPreviewPressed: _showPreview,
            ),
            body: _viewModel.isLoadingTodayLog
                ? const WorkoutLogLoadingWidget()
                : _viewModel.selectedProgram == null
                ? EmptyStateWidgets.noActiveProgram(context)
                : SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      children: [
                        SizedBox(height: 8.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: WorkoutTrainerSupervisionCard(
                            programId: _viewModel.selectedProgram!.id,
                            selectedProgram: _viewModel.selectedProgram,
                            selectedSession: _viewModel.selectedSession,
                            onSessionSelected: _onSessionSelected,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        const MyProgramsButton(),
                        SizedBox(height: 24.h),
                        WorkoutDateSeparatorWidget(selectedDate: dateTime),
                        SizedBox(height: 24.h),
                        _buildExercisesList(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final gregorian = _viewModel.selectedDate.toGregorian();
    final dateTime = gregorian.toDateTime();

    await WidgetSafetyUtils.safeShowDialog<void>(
      context: context,
      builder: (context) => PersianDatePickerDialog(
        selectedDate: dateTime,
        onDateSelected: (date) async {
          final gregorian = Gregorian.fromDateTime(date);
          final jalali = gregorian.toJalali();
          _viewModel.updateSelectedDate(jalali);
          await _viewModel.checkLogForDate(jalali);
        },
      ),
    );
  }

  Future<void> _showPreview() async {
    final gregorian = _viewModel.selectedDate.toGregorian();
    final dateTime = gregorian.toDateTime();

    // بستن کیبورد قبل از نمایش دیالوگ
    FocusScope.of(context).unfocus();
    _viewModel.unfocusAllFields();

    await WidgetSafetyUtils.safeShowDialog<void>(
      context: context,
      builder: (context) => WorkoutPreviewDialog(viewModel: _viewModel, dateTime: dateTime),
    );
  }

  Widget _buildExercisesList() {
    if (_viewModel.selectedProgram == null) {
      return const SizedBox.shrink();
    }

    if (_viewModel.selectedSession == null) {
      return EmptyStateWidgets.noSessionSelected();
    }

    if (_viewModel.selectedSession!.exercises.isEmpty) {
      return EmptyStateWidgets.noExercisesInSession();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_viewModel.selectedSession!.notes != null &&
            _viewModel.selectedSession!.notes!.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: ExerciseListHeader(
              sessionNotes: _viewModel.selectedSession!.notes!,
            ),
          ),
        ...List.generate(_viewModel.selectedSession!.exercises.length, (index) {
          final exercise = _viewModel.selectedSession!.exercises[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: ExerciseCard(
              exercise: exercise,
              exerciseDetails: _viewModel.exerciseDetails,
              exerciseControllers: _viewModel.exerciseControllers,
              exerciseFocusNodes: _viewModel.exerciseFocusNodes,
              setSavedStatus: _viewModel.setSavedStatus,
              collapsedExercises: _viewModel.collapsedExercises,
              onToggleCollapse: _toggleExerciseCollapse,
              onNavigateToTutorial: _navigateToExerciseTutorial,
              onSaveSet: _viewModel.saveSet,
            ),
          );
        }),
      ],
    );
  }
}
