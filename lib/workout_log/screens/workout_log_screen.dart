import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/workout_log/services/beginner_starter_program_service.dart';
import 'package:gymaipro/workout_log/utils/workout_log_keyboard.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:gymaipro/workout_log/widgets/session_muscle_heatmap_sheet.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_widgets.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:gymaipro/workout_log/widgets/workout_preview_dialog.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:vibration/vibration.dart';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  late final WorkoutLogViewModel _viewModel;
  final BeginnerStarterProgramService _starterService =
      BeginnerStarterProgramService();
  bool _isInstallingStarter = false;
  bool _hasStarterProgram = false;
  bool _needsStarterUpgrade = false;
  Timer? _restCountdownTimer;
  AudioPlayer? _restDonePlayer;
  int _restDurationSeconds = 60;
  int _remainingRestSeconds = 0;
  bool _isRestRunning = false;
  bool _restSessionActive = false;

  @override
  void initState() {
    super.initState();
    _viewModel = WorkoutLogViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.initialize();
    _checkStarterProgram();
  }

  Future<void> _checkStarterProgram() async {
    final has = await _starterService.hasStarterProgram();
    final needsUpgrade = await _starterService.needsStarterUpgrade();
    if (!mounted) return;
    setState(() {
      _hasStarterProgram = has;
      _needsStarterUpgrade = needsUpgrade;
    });
    if (needsUpgrade) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'برنامهٔ شروع باشگاه به‌روز شده — یک‌بار «به‌روزرسانی برنامه» را بزنید.',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: AppTheme.goldColor.withValues(alpha: 0.95),
        ),
      );
    }
  }

  Future<void> _onStarterProgramTap() async {
    if (_isInstallingStarter) return;
    setState(() => _isInstallingStarter = true);
    try {
      final result = await _starterService.installAndActivate();
      await _viewModel.loadActiveProgram();
      if (mounted) {
        setState(() {
          _hasStarterProgram = true;
          _needsStarterUpgrade = false;
          _isInstallingStarter = false;
        });
        await _showAiTrainerEnrollmentDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInstallingStarter = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showAiTrainerEnrollmentDialog(
    StarterProgramActivationResult result,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await WidgetSafetyUtils.safeShowDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCardColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(LucideIcons.bot, color: AppTheme.goldColor, size: 22.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'تحت نظارت ${AppConfig.gymAiDisplayName}',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppTheme.darkTextColor
                        : AppTheme.lightTextColor,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            BeginnerStarterProgramService.enrollmentDialogMessage(
              trainerName: result.trainerDisplayName,
              isNewAiStudent: result.isNewAiStudent,
              upgradedFromVersion: result.upgradedFromVersion,
              rebuiltProgram: result.rebuiltProgram,
            ),
            style: WorkoutLogTypography.dialogBody(context).copyWith(
              fontSize: 13.5.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'باشه، شروع می‌کنم',
              style: WorkoutLogTypography.chip(context, selected: true).copyWith(
                fontSize: 14.sp,
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onViewModelChanged() {
    if (mounted) {
      WidgetSafetyUtils.safeSetState(this, () {});
    }
  }

  @override
  void dispose() {
    _restCountdownTimer?.cancel();
    unawaited(_restDonePlayer?.dispose() ?? Future<void>.value());
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _startRestTimer() {
    if (_isRestRunning) return;

    if (_remainingRestSeconds <= 0) {
      _remainingRestSeconds = _restDurationSeconds;
    }

    WidgetSafetyUtils.safeSetState(this, () => _isRestRunning = true);
    _restCountdownTimer?.cancel();
    _restCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingRestSeconds <= 1) {
        timer.cancel();
        WidgetSafetyUtils.safeSetState(this, () {
          _remainingRestSeconds = 0;
          _isRestRunning = false;
          _restSessionActive = false;
        });
        unawaited(_notifyRestCompleted());
        return;
      }

      WidgetSafetyUtils.safeSetState(this, () {
        _remainingRestSeconds -= 1;
      });
    });
  }

  void _pauseRestTimer() {
    _restCountdownTimer?.cancel();
    if (!_isRestRunning) return;
    WidgetSafetyUtils.safeSetState(this, () => _isRestRunning = false);
  }

  Future<void> _notifyRestCompleted() async {
    try {
      if (await Vibration.hasVibrator()) {
        if (await Vibration.hasCustomVibrationsSupport()) {
          await Vibration.vibrate(duration: 480);
          await Future<void>.delayed(const Duration(milliseconds: 140));
          await Vibration.vibrate(duration: 320);
        } else {
          await Vibration.vibrate();
          await Future<void>.delayed(const Duration(milliseconds: 160));
          await Vibration.vibrate();
        }
      }
    } catch (_) {}

    try {
      for (var i = 0; i < 4; i++) {
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    } catch (_) {}

    try {
      final player = _restDonePlayer ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource('sounds/rest_timer_done.wav'));
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'استراحت تموم شد، بزن بریم ست بعدی!',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  String _formatRestLabel(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _dismissKeyboard() {
    WorkoutLogKeyboard.dismiss(context);
  }

  void _onRestFabPressed() {
    _dismissKeyboard();
    if (_isRestRunning) {
      _pauseRestTimer();
      return;
    }
    if (_restSessionActive && _remainingRestSeconds > 0) {
      _startRestTimer();
      return;
    }
    WorkoutLogKeyboard.runAfterKeyboardDismissed(context, () {
      unawaited(_openRestTimerSheet());
    });
  }

  void _startFreshRest(int seconds) {
    _restCountdownTimer?.cancel();
    final s = seconds.clamp(5, 3600);
    WidgetSafetyUtils.safeSetState(this, () {
      _restDurationSeconds = s;
      _remainingRestSeconds = s;
      _restSessionActive = true;
      _isRestRunning = false;
    });
    _startRestTimer();
  }

  void _applyPlusFifteenFromSheet() {
    _restCountdownTimer?.cancel();
    WidgetSafetyUtils.safeSetState(this, () {
      _remainingRestSeconds += 15;
      if (_remainingRestSeconds > _restDurationSeconds) {
        _restDurationSeconds = _remainingRestSeconds;
      }
      if (_remainingRestSeconds > 0) {
        _restSessionActive = true;
      }
      _isRestRunning = false;
    });
    if (_remainingRestSeconds > 0) {
      _startRestTimer();
    }
  }

  Future<void> _openRestTimerSheet() async {
    _dismissKeyboard();
    final rootContext = context;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final cardColor = Theme.of(sheetContext).cardColor;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20.w,
            0,
            20.w,
            16.h + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.12,
                        ),
                        blurRadius: 16.r,
                        offset: Offset(0, 6.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRestDurationCircle(
                        sheetContext: sheetContext,
                        seconds: 60,
                      ),
                      _buildRestDurationCircle(
                        sheetContext: sheetContext,
                        seconds: 90,
                      ),
                      _buildRestDurationCircle(
                        sheetContext: sheetContext,
                        seconds: 120,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Material(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(999.r),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      if (!rootContext.mounted) return;
                      _dismissKeyboard();
                      _applyPlusFifteenFromSheet();
                    },
                    borderRadius: BorderRadius.circular(999.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 22.w,
                        vertical: 10.h,
                      ),
                      child: Text(
                        '+15 ثانیه',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                          color: AppTheme.goldColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestDurationCircle({
    required BuildContext sheetContext,
    required int seconds,
  }) {
    final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(sheetContext).pop();
          if (!context.mounted) return;
          _dismissKeyboard();
          _startFreshRest(seconds);
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.85),
              width: 2.w,
            ),
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.14 : 0.1),
          ),
          alignment: Alignment.center,
          child: Text(
            '$seconds',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w900,
              fontSize: 16.sp,
              color: Theme.of(sheetContext).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestFloatingButton() {
    final showTime = _restSessionActive && _remainingRestSeconds > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showTime)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
            child: Text(
              _formatRestLabel(_remainingRestSeconds),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w900,
                fontSize: 14.sp,
                color: AppTheme.goldColor,
              ),
            ),
          ),
        Material(
          elevation: 6,
          shadowColor: Colors.black45,
          shape: const CircleBorder(),
          color: _isRestRunning ? AppTheme.successColor : AppTheme.goldColor,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _onRestFabPressed,
            onLongPress: () {
              _dismissKeyboard();
              WorkoutLogKeyboard.runAfterKeyboardDismissed(context, () {
                unawaited(_openRestTimerSheet());
              });
            },
            child: SizedBox(
              width: 56.w,
              height: 56.w,
              child: Icon(
                _isRestRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 30.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToExerciseTutorial(int exerciseId) {
    _dismissKeyboard();
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
    _dismissKeyboard();
    _viewModel.toggleExerciseCollapse(exerciseId);
  }

  Future<void> _onSessionSelected(WorkoutSession? session) async {
    _dismissKeyboard();
    if (_viewModel.isLoadingDayLog) return;

    if (session == null) {
      await _viewModel.onSessionSelected(null);
      return;
    }

    final prompt = _viewModel.evaluateSessionChange(session);
    if (prompt.requiresConfirmation) {
      final gregorian = _viewModel.selectedDate.toGregorian();
      final dateTime = gregorian.toDateTime();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => SessionChangeDialog(
          dateTime: dateTime,
          loggedSessionDay: prompt.loggedSessionDayForDialog,
          newSessionDay: session.day,
          hasUnsavedData: prompt.hasUnsavedData,
        ),
      );

      if (confirmed != true) {
        return;
      }

      final dayToDelete = prompt.sessionDayToDelete;
      if (dayToDelete != null && dayToDelete.isNotEmpty) {
        await _viewModel.deleteSessionLog(dayToDelete);
      }

      await _viewModel.onSessionSelected(
        session,
        startFresh: true,
      );
      return;
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
        child: DecoratedBox(
          decoration: const BoxDecoration(),
          child: Scaffold(
            resizeToAvoidBottomInset: true,
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
                ? EmptyStateWidgets.noActiveProgram(
                    context,
                    onStarterProgramTap: _onStarterProgramTap,
                    isInstallingStarter: _isInstallingStarter,
                    hasStarterProgram: _hasStarterProgram,
                    needsStarterUpgrade: _needsStarterUpgrade,
                  )
                : TapRegion(
                    onTapOutside: (_) => _dismissKeyboard(),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(bottom: 88.h),
                      child: Column(
                        children: [
                          SizedBox(height: 8.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: WorkoutTrainerSupervisionCard(
                              programId: _viewModel.selectedProgram!.id,
                              selectedProgram: _viewModel.selectedProgram,
                              selectedSession: _viewModel.selectedSession,
                              viewModel: _viewModel,
                              onSessionHeatmapTap: _showSessionHeatmap,
                              sessionsLocked: _viewModel.isLoadingDayLog,
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
            floatingActionButton: _buildRestFloatingButton(),
            floatingActionButtonAnimator:
                FloatingActionButtonAnimator.noAnimation,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    _dismissKeyboard();
    final gregorian = _viewModel.selectedDate.toGregorian();
    final dateTime = gregorian.toDateTime();

    final picked = await WidgetSafetyUtils.safeShowDialog<DateTime>(
      context: context,
      builder: (context) => PersianDatePickerDialog(
        selectedDate: dateTime,
        onDateSelected: (date) => Navigator.pop(context, date),
      ),
    );

    if (picked == null || !mounted) return;
    await _applyCalendarDate(picked);
  }

  Future<void> _applyCalendarDate(DateTime date) async {
    final pickedDay = DateTime(date.year, date.month, date.day);
    final jalali = Gregorian.fromDateTime(pickedDay).toJalali();
    final current = _viewModel.selectedDate;
    if (jalali.year == current.year &&
        jalali.month == current.month &&
        jalali.day == current.day) {
      return;
    }

    _dismissKeyboard();
    await _viewModel.changeSelectedDate(jalali);
  }

  Future<void> _showPreview() async {
    _dismissKeyboard();
    final gregorian = _viewModel.selectedDate.toGregorian();
    final dateTime = gregorian.toDateTime();

    await WidgetSafetyUtils.safeShowDialog<void>(
      context: context,
      builder: (context) =>
          WorkoutPreviewDialog(viewModel: _viewModel, dateTime: dateTime),
    );
  }

  Future<void> _showSessionHeatmap() async {
    _dismissKeyboard();
    if (_viewModel.selectedSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'اول یک جلسه انتخاب کن',
            style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 13.sp),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    await SessionMuscleHeatmapSheet.show(context, viewModel: _viewModel);
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
            child: RepaintBoundary(
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
              onDismissKeyboard: _dismissKeyboard,
            ),
            ),
          );
        }),
      ],
    );
  }
}
