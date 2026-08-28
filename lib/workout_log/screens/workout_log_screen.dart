import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_snapshot.dart';
import 'package:gymaipro/features/session_analysis/presentation/widgets/session_analysis_sections.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/workout_log/services/beginner_starter_program_service.dart';
import 'package:gymaipro/workout_log/utils/workout_exit_guard.dart';
import 'package:gymaipro/workout_log/utils/workout_log_keyboard.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_widgets.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  static const _kRestPrefKey = 'workout_log_rest_seconds';

  late final WorkoutLogViewModel _viewModel;
  final BeginnerStarterProgramService _starterService =
      BeginnerStarterProgramService();
  bool _isInstallingStarter = false;
  bool _hasStarterProgram = false;
  bool _needsStarterUpgrade = false;
  bool _wasLoadingDayLog = false;
  final ValueNotifier<bool> _setupExpanded = ValueNotifier<bool>(true);
  final WorkoutSetNumpadController _numpad = WorkoutSetNumpadController();
  Timer? _restCountdownTimer;
  AudioPlayer? _restDonePlayer;

  /// ۰ = تایمر خاموش؛ پیش‌فرض ۹۰ث مثل Hevy/Strong
  int _restDurationSeconds = 90;
  final ValueNotifier<int> _restDurationTick = ValueNotifier<int>(0);
  final ValueNotifier<int> _restRemaining = ValueNotifier<int>(0);
  final ValueNotifier<bool> _restRunning = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _restSessionActive = ValueNotifier<bool>(false);
  final ValueNotifier<int> _restAttentionTick = ValueNotifier<int>(0);

  /// مدت کل همین شمارش معکوس (نوار پیشرفت) — جدا از پیش‌فرض کاربر.
  int _restSessionTotal = 90;
  bool _restGateBusy = false;

  @override
  void initState() {
    super.initState();
    _viewModel = WorkoutLogViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _numpad.addListener(_onNumpadChanged);
    _viewModel.initialize();
    unawaited(_loadRestPreference());
    _checkStarterProgram();
  }

  Future<void> _loadRestPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(_kRestPrefKey);
      if (v == null) return;
      _restDurationSeconds = v.clamp(0, 3600);
      _restDurationTick.value++;
    } catch (_) {}
  }

  Future<void> _persistRestPreference(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kRestPrefKey, seconds);
    } catch (_) {}
  }

  void _onNumpadChanged() {
    _viewModel.setSuppressAutoSave(_numpad.isOpen);
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
      await _viewModel.refreshAnalysisEligibility();
      await _viewModel.checkLogForDate(_viewModel.selectedDate);
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
            style: WorkoutLogTypography.dialogBody(
              context,
            ).copyWith(fontSize: 13.5.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'باشه، شروع می‌کنم',
                style: WorkoutLogTypography.chip(
                  context,
                  selected: true,
                ).copyWith(fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    final loading = _viewModel.isLoadingDayLog;
    final finishedLoad = _wasLoadingDayLog && !loading;
    _wasLoadingDayLog = loading;
    if (finishedLoad && _viewModel.hasAnySavedSet) {
      _setupExpanded.value = false;
    }
    WidgetSafetyUtils.safeSetState(this, () {});
  }

  @override
  void dispose() {
    _restCountdownTimer?.cancel();
    _restRemaining.dispose();
    _restRunning.dispose();
    _restSessionActive.dispose();
    _restAttentionTick.dispose();
    _setupExpanded.dispose();
    _restDurationTick.dispose();
    _numpad.removeListener(_onNumpadChanged);
    _numpad.dispose();
    unawaited(_restDonePlayer?.dispose() ?? Future<void>.value());
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _startRestTimer() {
    if (_restRunning.value) return;
    if (_restRemaining.value <= 0) return;

    _restRunning.value = true;
    _restCountdownTimer?.cancel();
    _restCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_restRemaining.value <= 1) {
        timer.cancel();
        _restRemaining.value = 0;
        _restRunning.value = false;
        _restSessionActive.value = false;
        unawaited(_notifyRestCompleted());
        return;
      }

      _restRemaining.value -= 1;
    });
  }

  void _pauseRestTimer() {
    _restCountdownTimer?.cancel();
    if (!_restRunning.value) return;
    _restRunning.value = false;
  }

  void _toggleRestPause() {
    if (_restRunning.value) {
      _pauseRestTimer();
    } else if (_restSessionActive.value && _restRemaining.value > 0) {
      _startRestTimer();
    }
  }

  void _skipRestTimer() {
    _restCountdownTimer?.cancel();
    _restRemaining.value = 0;
    _restRunning.value = false;
    _restSessionActive.value = false;
  }

  void _adjustRestBy(int delta) {
    if (!_restSessionActive.value) return;
    final next = (_restRemaining.value + delta).clamp(0, 3600);
    _restRemaining.value = next;
    if (next > _restSessionTotal) {
      _restSessionTotal = next;
    }
    if (next <= 0) {
      _skipRestTimer();
      return;
    }
    if (!_restRunning.value) {
      _startRestTimer();
    }
  }

  /// شروع/ریست تایمر با مدت پیش‌فرض (بعد از ثبت ست).
  void _startFreshRest([int? seconds]) {
    final s = (seconds ?? _restDurationSeconds).clamp(0, 3600);
    if (s <= 0) {
      _skipRestTimer();
      return;
    }
    _restCountdownTimer?.cancel();
    _restSessionTotal = s;
    _restRemaining.value = s;
    _restSessionActive.value = true;
    _restRunning.value = false;
    _startRestTimer();
  }

  Future<void> _openRestSettings() async {
    _dismissKeyboard();
    final picked = await showRestDurationPicker(
      context,
      currentSeconds: _restDurationSeconds,
    );
    if (!mounted || picked == null) return;
    _restDurationSeconds = picked;
    _restDurationTick.value++;
    unawaited(_persistRestPreference(picked));
    if (picked <= 0) {
      _skipRestTimer();
    }
  }

  Future<void> _notifyRestCompleted() async {
    try {
      if (!kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final vibrationOn = prefs.getBool('vibration_enabled') ?? true;
        if (vibrationOn && await Vibration.hasVibrator()) {
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
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final vibrationOn = prefs.getBool('vibration_enabled') ?? true;
      if (vibrationOn) {
        for (var i = 0; i < 4; i++) {
          await HapticFeedback.heavyImpact();
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
      }
    } catch (_) {}

    try {
      final player = _restDonePlayer ??= AudioPlayer();
      final prefs = await SharedPreferences.getInstance();
      final soundOn = prefs.getBool('sound_enabled') ?? true;
      if (soundOn) {
        await player.stop();
        await player.play(AssetSource('sounds/rest_timer_done.wav'));
      }
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

  void _dismissKeyboard() {
    _numpad.close();
    WorkoutLogKeyboard.dismiss(context);
  }

  Future<void> _handleBackPressed() async {
    final restActive =
        _restSessionActive.value && _restRemaining.value > 0;
    final result = WorkoutBackLayer.handle(
      numpadOpen: _numpad.isOpen,
      restActive: restActive,
      closeNumpad: () => _numpad.close(),
      dismissRest: _skipRestTimer,
    );
    if (result == WorkoutBackResult.consumed) return;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<bool> _handleSaveSet(String exerciseId, int setIndex) async {
    final statusBefore = _viewModel.setSavedStatus[exerciseId];
    final alreadySaved = statusBefore != null &&
        statusBefore.length > setIndex &&
        statusBefore[setIndex];

    // وسط استراحت ست جدید؟ مسدود نکن — فقط واکنش بده.
    if (!alreadySaved &&
        _restSessionActive.value &&
        _restRemaining.value > 0) {
      if (_restGateBusy) return false;
      _restGateBusy = true;
      _restAttentionTick.value++;
      HapticFeedback.mediumImpact();
      try {
        final choice = await showRestStillActiveSheet(
          context,
          remainingSeconds: _restRemaining.value,
        );
        if (!mounted) return false;
        if (choice != RestStillActiveChoice.skipAndSave) return false;
        _skipRestTimer();
      } finally {
        _restGateBusy = false;
      }
    }

    final hadAny = _viewModel.hasAnySavedSet;
    await _viewModel.saveSet(exerciseId, setIndex);
    if (!mounted) return false;
    final status = _viewModel.setSavedStatus[exerciseId];
    final isSaved =
        status != null && status.length > setIndex && status[setIndex];
    if (!isSaved) return false;
    HapticFeedback.lightImpact();
    if (!hadAny && _setupExpanded.value) {
      _setupExpanded.value = false;
    }
    // مثل Hevy/Strong: بعد از ثبت ست، استراحت خودکار شروع می‌شود.
    if (_restDurationSeconds > 0) {
      _startFreshRest();
    }
    return true;
  }

  Future<void> _handleUnsaveSet(String exerciseId, int setIndex) async {
    await _viewModel.unsaveSet(exerciseId, setIndex);
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

      await _viewModel.onSessionSelected(session, startFresh: true);
      return;
    }

    await _viewModel.onSessionSelected(session);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gregorian = _viewModel.selectedDate.toGregorian();
    final dateTime = gregorian.toDateTime();
    final hasSession = _viewModel.selectedSession != null;

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
        child: ListenableBuilder(
          listenable: Listenable.merge([
            _numpad,
            _restSessionActive,
            _restRemaining,
          ]),
          builder: (context, _) {
            final restActive =
                _restSessionActive.value && _restRemaining.value > 0;
            final overlayOpen = _numpad.isOpen || restActive;

            return PopScope(
              canPop: !overlayOpen,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                unawaited(_handleBackPressed());
              },
              child: Scaffold(
                // ui-health: keyboard-inset-ok — جلوگیری از resize کل لیست هنگام IME
                resizeToAvoidBottomInset: false,
                backgroundColor: context.backgroundColor,
                appBar: WorkoutLogAppBar(
                  selectedDate: dateTime,
                  onBackPressed: () => unawaited(_handleBackPressed()),
                  onLogSummaryPressed: _viewModel.selectedProgram == null
                      ? null
                      : _showLogSummary,
                  onHeatmapPressed: _viewModel.selectedProgram == null
                      ? null
                      : _showSessionHeatmap,
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
                        child: Column(
                          children: [
                      if (hasSession)
                        ListenableBuilder(
                          listenable: Listenable.merge([
                            _setupExpanded,
                            _restDurationTick,
                          ]),
                          builder: (context, _) {
                            return WorkoutSessionProgressStrip(
                              viewModel: _viewModel,
                              restDefaultSeconds: _restDurationSeconds,
                              onRestSettingsTap: _openRestSettings,
                              onSessionTap: () {
                                _setupExpanded.value = !_setupExpanded.value;
                              },
                              setupExpanded: _setupExpanded.value,
                            );
                          },
                        ),
                      if (_viewModel.selectedProgram != null)
                        WorkoutWeekDateStrip(
                          selectedDate: _viewModel.selectedDate,
                          enabled: !_viewModel.isLoadingDayLog,
                          isDateEnabled: _viewModel.isLogDateAllowed,
                          onDateSelected: (day) {
                            unawaited(_applySelectedJalali(day));
                          },
                          onOpenCalendar: _showDatePicker,
                        ),
                      Expanded(
                        child: ListenableBuilder(
                          listenable: _setupExpanded,
                          builder: (context, _) {
                            return NotificationListener<ScrollUpdateNotification>(
                              onNotification: (notification) {
                                // فقط درگ دستی کاربر — نه ensureVisible برنامه‌ای
                                if (notification.dragDetails != null &&
                                    _numpad.isOpen) {
                                  _numpad.close();
                                }
                                return false;
                              },
                              child: CustomScrollView(
                                cacheExtent: 480,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: SizedBox(height: 6.h),
                                  ),
                                  if (!hasSession || _setupExpanded.value)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          16.w,
                                          4.h,
                                          16.w,
                                          0,
                                        ),
                                        child: WorkoutTrainerSupervisionCard(
                                          programId:
                                              _viewModel.selectedProgram!.id,
                                          selectedProgram:
                                              _viewModel.selectedProgram,
                                          selectedSession:
                                              _viewModel.selectedSession,
                                          sessionsLocked:
                                              _viewModel.isLoadingDayLog,
                                          onSessionSelected: _onSessionSelected,
                                        ),
                                      ),
                                    ),
                                  if (_viewModel.isAnalysisMode &&
                                      _viewModel.dayAnalysis != null)
                                    ..._buildAnalysisSlivers(
                                      _viewModel.dayAnalysis!,
                                    )
                                  else ...[
                                    ..._buildExerciseSlivers(),
                                    SliverToBoxAdapter(
                                      child: ValueListenableBuilder<int>(
                                        valueListenable:
                                            _viewModel.sessionProgressTick,
                                        builder: (context, _, __) {
                                          if (!_viewModel
                                              .showFinishAndAnalyzeChrome) {
                                            return const SizedBox.shrink();
                                          }
                                          final enabled = _viewModel
                                                  .canFinishAndAnalyze &&
                                              !_viewModel.isFinishingAnalysis;
                                          return Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              16.w,
                                              12.h,
                                              16.w,
                                              8.h,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                GymButton(
                                                  label: ProductCopy
                                                      .finishWorkoutAndAnalyze,
                                                  fullWidth: true,
                                                  loading: _viewModel
                                                      .isFinishingAnalysis,
                                                  icon: LucideIcons.lineChart,
                                                  onPressed: enabled
                                                      ? () {
                                                          HapticFeedback
                                                              .mediumImpact();
                                                          unawaited(
                                                            _finishAndAnalyze(),
                                                          );
                                                        }
                                                      : null,
                                                ),
                                                if (!_viewModel
                                                    .canFinishAndAnalyze) ...[
                                                  SizedBox(height: 8.h),
                                                  Text(
                                                    ProductCopy
                                                        .finishWorkoutAndAnalyzeHint,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontFamily:
                                                          AppTheme.fontFamily,
                                                      fontSize: 12.sp,
                                                      height: 1.4,
                                                      color: isDark
                                                          ? Colors.white60
                                                          : AppTheme
                                                                .backgroundColor
                                                                .withValues(
                                                                  alpha: 0.65,
                                                                ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  SliverToBoxAdapter(
                                    child: SizedBox(height: 88.h),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // داک استراحت — نزدیک اکشن کاربر (بالای نام‌پد)
                      if (hasSession && !_viewModel.isAnalysisMode)
                        ListenableBuilder(
                          listenable: Listenable.merge([
                            _restRemaining,
                            _restRunning,
                            _restSessionActive,
                            _restAttentionTick,
                          ]),
                          builder: (context, _) {
                            final active = _restSessionActive.value &&
                                _restRemaining.value > 0;
                            return AnimatedSize(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.bottomCenter,
                              child: active
                                  ? WorkoutRestTimerBar(
                                      remainingSeconds: _restRemaining.value,
                                      totalSeconds: _restSessionTotal,
                                      isRunning: _restRunning.value,
                                      attentionToken: _restAttentionTick.value,
                                      onTogglePause: _toggleRestPause,
                                      onMinus15: () => _adjustRestBy(-15),
                                      onPlus15: () => _adjustRestBy(15),
                                      onSkip: _skipRestTimer,
                                    )
                                  : const SizedBox(width: double.infinity),
                            );
                          },
                        ),
                      if (!_viewModel.isAnalysisMode)
                        WorkoutSetNumpadBar(controller: _numpad),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildExerciseSlivers() {
    if (_viewModel.selectedSession == null) {
      return [
        SliverToBoxAdapter(child: EmptyStateWidgets.noSessionSelected()),
      ];
    }

    if (_viewModel.selectedSession!.exercises.isEmpty) {
      return [
        SliverToBoxAdapter(child: EmptyStateWidgets.noExercisesInSession()),
      ];
    }

    final exercises = _viewModel.selectedSession!.exercises;
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final exercise = exercises[index];
              final key = _exerciseUiKey(exercise);
              return RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _viewModel.exerciseListenable(key),
                  builder: (context, _, __) {
                    return ExerciseCard(
                      exercise: exercise,
                      orderIndex: index + 1,
                      exerciseDetails: _viewModel.exerciseDetails,
                      exerciseControllers: _viewModel.exerciseControllers,
                      exerciseFocusNodes: _viewModel.exerciseFocusNodes,
                      setSavedStatus: _viewModel.setSavedStatus,
                      collapsedExercises: _viewModel.collapsedExercises,
                      exerciseCoachFeedback:
                          _viewModel.exerciseCoachFeedback,
                      previousSetsByExerciseId:
                          _viewModel.previousSetsByExerciseId,
                      onToggleCollapse: _toggleExerciseCollapse,
                      onNavigateToTutorial: _navigateToExerciseTutorial,
                      onSaveSet: _handleSaveSet,
                      onUnsaveSet: _handleUnsaveSet,
                      onDismissKeyboard: _dismissKeyboard,
                      numpad: _numpad,
                    );
                  },
                ),
              );
            },
            childCount: exercises.length,
            addRepaintBoundaries: false,
          ),
        ),
      ),
    ];
  }

  String _exerciseUiKey(WorkoutExercise exercise) {
    if (exercise is NormalExercise) {
      return exercise.exerciseId.toString();
    }
    if (exercise is SupersetExercise) {
      return exercise.id;
    }
    return exercise.hashCode.toString();
  }

  List<Widget> _buildAnalysisSlivers(SessionAnalysisSnapshot snapshot) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 0),
          child: SessionAnalysisBody(
            snapshot: snapshot,
            compact: true,
            onResumeEditing: () {
              HapticFeedback.selectionClick();
              _viewModel.resumeSessionEditing();
            },
            onNarrativeReady: _viewModel.rememberAnalysisNarrative,
          ),
        ),
      ),
    ];
  }

  Future<void> _finishAndAnalyze() async {
    _dismissKeyboard();
    _numpad.close();
    final snapshot = await _viewModel.finishAndBuildAnalysis();
    if (!mounted || snapshot == null) return;
    // Stay on the same day — analysis replaces the logging list.
    setState(() {
      _setupExpanded.value = false;
    });
  }

  Future<void> _showDatePicker() async {
    if (_viewModel.isLoadingDayLog) return;
    _dismissKeyboard();
    final gregorian = _viewModel.selectedDate.toGregorian();
    final dateTime = gregorian.toDateTime();
    final bounds = _viewModel.logDateBounds;

    final picked = await WidgetSafetyUtils.safeShowDialog<DateTime>(
      context: context,
      builder: (context) => PersianDatePickerDialog(
        selectedDate: dateTime,
        minDate: bounds?.from,
        maxDate: bounds?.to,
      ),
    );

    if (picked == null || !mounted) return;
    await _applyCalendarDate(picked);
  }

  Future<void> _applyCalendarDate(DateTime date) async {
    final pickedDay = DateTime(date.year, date.month, date.day);
    final jalali = Gregorian.fromDateTime(pickedDay).toJalali();
    await _applySelectedJalali(jalali);
  }

  Future<void> _applySelectedJalali(Jalali jalali) async {
    final current = _viewModel.selectedDate;
    if (jalali.year == current.year &&
        jalali.month == current.month &&
        jalali.day == current.day) {
      return;
    }

    if (!_viewModel.isLogDateAllowed(jalali)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فقط از روز شروع برنامه تا امروز می‌توانی ثبت کنی',
            style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 13.sp),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_viewModel.hasUncommittedSetEdits()) {
      final confirmed = await WidgetSafetyUtils.safeShowDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: WorkoutLogColors.sectionBackground(context),
          title: Text(
            'تغییر تاریخ',
            style: WorkoutLogTypography.dialogTitle(context),
          ),
          content: Text(
            'ست‌هایی را نوشته‌ای که هنوز ثبت نشده‌اند. با عوض کردن تاریخ پاک می‌شوند.',
            style: WorkoutLogTypography.dialogBody(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('بمان'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'ادامه',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: WorkoutLogColors.warningText(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    _dismissKeyboard();
    final ok = await _viewModel.changeSelectedDate(jalali);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فقط از روز شروع برنامه تا امروز می‌توانی ثبت کنی',
            style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 13.sp),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showLogSummary() async {
    _dismissKeyboard();
    final gregorian = _viewModel.selectedDate.toGregorian();
    final dateTime = gregorian.toDateTime();
    await WorkoutLogSummarySheet.show(
      context,
      viewModel: _viewModel,
      dateTime: dateTime,
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
}
