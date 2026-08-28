import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_chip.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach_chat/navigation/coach_chat_navigation.dart';
import 'package:gymaipro/features/live_workout/presentation/adapters/live_workout_exercise_adapter.dart';
import 'package:gymaipro/features/live_workout/presentation/cards/live_workout_cards.dart';
import 'package:gymaipro/features/live_workout/presentation/widgets/live_workout_session_progress.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';
import 'package:gymaipro/features/live_workout/view_models/live_workout_view_model.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/navigation/form_guidance_navigation.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_navigation.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/features/product_experience/presentation/active_program_selector_bar.dart';
import 'package:gymaipro/features/product_experience/presentation/workout_session_day_picker.dart';
import 'package:gymaipro/features/product_experience/presentation/workout_session_selection_helper.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/session_analysis/presentation/widgets/session_analysis_sections.dart';
import 'package:gymaipro/workout_log/utils/workout_exit_guard.dart';
import 'package:gymaipro/workout_log/utils/workout_log_keyboard.dart';
import 'package:gymaipro/workout_log/widgets/exercise_card.dart';
import 'package:gymaipro/workout_log/widgets/workout_rest_timer_bar.dart';
import 'package:gymaipro/workout_log/widgets/workout_set_numpad.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveWorkoutScreen extends StatefulWidget {
  const LiveWorkoutScreen({this.viewModel, this.autoLoad = true, super.key});

  final LiveWorkoutViewModel? viewModel;
  final bool autoLoad;

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  static const _kRestPrefKey = 'workout_log_rest_seconds';

  late final LiveWorkoutViewModel _viewModel;
  late final bool _ownsViewModel;
  final WorkoutSetNumpadController _numpad = WorkoutSetNumpadController();

  /// ۰ = تایمر خاموش؛ هم‌کلید با ثبت تمرین داشبورد
  int _restDurationSeconds = 90;
  final ValueNotifier<int> _restDurationTick = ValueNotifier<int>(0);
  int _restAttentionTick = 0;
  bool _restGateBusy = false;
  bool _dayIdentityGateRan = false;
  bool _didAutoOpenAnalysis = false;
  bool _manualAnalysisInFlight = false;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? LiveWorkoutViewModel();
    _numpad.addListener(_onNumpadChanged);
    _viewModel.addListener(_onViewModelChanged);
    if (widget.autoLoad) {
      unawaited(_viewModel.load());
    }
    unawaited(_loadRestPreference());
  }

  void _onViewModelChanged() {
    final state = _viewModel.state;
    if (!_dayIdentityGateRan &&
        !state.isLoading &&
        !state.hasError &&
        (state.isLoaded || state.isAwaitingSession)) {
      _dayIdentityGateRan = true;
      unawaited(_ensureDayIdentityAllowsActiveProgram());
    }

    // Auto-finish stores analysis on the same screen — no route push.
    if (!_manualAnalysisInFlight &&
        !_didAutoOpenAnalysis &&
        _viewModel.justCompletedForAnalysis &&
        _viewModel.isAnalysisMode) {
      _didAutoOpenAnalysis = true;
      _viewModel.consumeJustCompletedForAnalysis();
    }
  }

  /// Blocks live logging on top of another program's meaningful day passport.
  Future<void> _ensureDayIdentityAllowsActiveProgram() async {
    final sessionContext = _viewModel.state.sessionContext;
    final programId = _viewModel.state.activeProgram?.id ??
        sessionContext?.programId;
    if (sessionContext == null || programId == null || programId.isEmpty) {
      return;
    }
    final loggedProgram = sessionContext.loggedProgramId?.trim() ?? '';
    if (!sessionContext.hasSavedLog ||
        loggedProgram.isEmpty ||
        loggedProgram == programId) {
      return;
    }

    final evaluation = await _viewModel.evaluateProgramChangeTo(programId);
    if (!mounted) return;

    final confirmed = await WorkoutSessionSelectionHelper.confirmAndApply(
      context: context,
      evaluation: evaluation,
      newSessionDay: sessionContext.selectedSessionDay ?? 'جلسه جدید',
      sessionGateway: _viewModel.sessionGateway,
    );
    if (!mounted) return;
    if (!confirmed) {
      Navigator.of(context).pop();
      return;
    }
    _dayIdentityGateRan = false;
    await _viewModel.refresh();
  }

  Future<void> _loadRestPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(_kRestPrefKey);
      if (v == null || !mounted) return;
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
      _viewModel.skipRest();
    }
  }

  void _onNumpadChanged() {
    _viewModel.setSuppressAutoSave(_numpad.isOpen);
  }

  Future<void> _onProgramChanged(ActiveProgramOption option) async {
    final currentId = _viewModel.state.activeProgram?.id ??
        _viewModel.state.sessionContext?.programId;
    if (currentId == option.id) return;

    final evaluation = await _viewModel.evaluateProgramChangeTo(option.id);
    if (!mounted) return;

    final confirmed = await WorkoutSessionSelectionHelper.confirmAndApply(
      context: context,
      evaluation: evaluation,
      newSessionDay: 'برنامه جدید',
      sessionGateway: _viewModel.sessionGateway,
    );
    if (!confirmed || !mounted) return;

    await ActiveProgramCatalogService().activateProgram(option.id);
    await _viewModel.refresh();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _numpad.removeListener(_onNumpadChanged);
    _numpad.dispose();
    _restDurationTick.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _dismissKeyboard() {
    _numpad.close();
    WorkoutLogKeyboard.dismiss(context);
    _viewModel.flushPendingSetSaves();
  }

  Future<void> _handleBackPressed() async {
    final restActive = _viewModel.restSessionActive.value &&
        _viewModel.restRemaining.value > 0;
    final result = WorkoutBackLayer.handle(
      numpadOpen: _numpad.isOpen,
      restActive: restActive,
      closeNumpad: () {
        _numpad.close();
        WorkoutLogKeyboard.dismiss(context);
      },
      dismissRest: _viewModel.skipRest,
    );
    if (result == WorkoutBackResult.consumed) return;
    if (!mounted) return;
    _viewModel.flushPendingSetSaves();
    Navigator.of(context).pop();
  }

  void _toggleExerciseCollapse(String exerciseKey) {
    _dismissKeyboard();
    _viewModel.toggleExerciseCollapse(exerciseKey);
  }

  void _navigateToExerciseTutorial(int exerciseId) {
    _dismissKeyboard();
    final exercise = _viewModel.exerciseDetails[exerciseId];
    if (exercise == null || !mounted) return;
    unawaited(
      Navigator.pushNamed(
        context,
        '/exercise-detail',
        arguments: <String, Object>{'exercise': exercise},
      ),
    );
  }

  Future<bool> _handleSaveSet(String exerciseKey, int setIndex) async {
    final statusBefore = _viewModel.setSavedStatus[exerciseKey];
    final alreadySaved = statusBefore != null &&
        statusBefore.length > setIndex &&
        statusBefore[setIndex];

    if (!alreadySaved &&
        _viewModel.restSessionActive.value &&
        _viewModel.restRemaining.value > 0) {
      if (_restGateBusy) return false;
      _restGateBusy = true;
      setState(() => _restAttentionTick++);
      HapticFeedback.mediumImpact();
      try {
        final choice = await showRestStillActiveSheet(
          context,
          remainingSeconds: _viewModel.restRemaining.value,
        );
        if (!mounted) return false;
        if (choice != RestStillActiveChoice.skipAndSave) return false;
        _viewModel.skipRest();
      } finally {
        _restGateBusy = false;
      }
    }

    _viewModel.saveSet(exerciseKey, setIndex);
    if (!mounted) return false;
    final status = _viewModel.setSavedStatus[exerciseKey];
    final isSaved =
        status != null && status.length > setIndex && status[setIndex];
    if (!isSaved) return false;
    HapticFeedback.lightImpact();
    if (_restDurationSeconds > 0) {
      _viewModel.startRest(seconds: _restDurationSeconds);
    }
    return true;
  }

  void _handleUnsaveSet(String exerciseKey, int setIndex) {
    _viewModel.unsaveSet(exerciseKey, setIndex);
  }

  Future<void> _openQuickAction(String actionId) async {
    final sessionDay = _viewModel.state.sessionContext?.selectedSessionDay;
    if (ProgramModifyNavigation.isModifyAction(actionId)) {
      final applied = await ProgramModifyNavigation.open(
        context,
        quickActionId: actionId,
        sessionDay: sessionDay,
        initialRequest: switch (actionId) {
          'replace_exercise' || 'replace' =>
            'یک حرکت این جلسه را نمی‌توانم بزنم؛ جایگزین مناسب بده و روی برنامه اعمال کن',
          _ =>
            'برنامه‌ام را اصلاح کن: اگر لازم است حرکت عوض شود، ست کم/زیاد شود، یا جلسه سبک‌تر/سنگین‌تر شود.',
        },
      );
      if ((applied ?? false) && mounted) {
        await _viewModel.load();
      }
      return;
    }

    if (FormGuidanceNavigation.isFormAction(actionId)) {
      final current = _viewModel.state.currentExercise;
      await FormGuidanceNavigation.open(
        context,
        sessionDay: sessionDay,
        catalogExerciseId: current?.exerciseId,
      );
      return;
    }

    final prompt = switch (actionId) {
      'recovery' =>
        'با توجه به ریکاوری من، برای اجرای همین جلسه چه شدت و رویکردی مناسب‌تر است؟',
      'ask_coach' => 'درباره همین جلسه تمرینی یک سوال دارم.',
      _ => ProductExperienceFormatter.promptForQuickAction(actionId),
    };
    await CoachChatNavigation.open(
      context,
      quickActionId: actionId,
      initialPrompt: prompt,
      sessionDay: sessionDay,
    );
  }

  Future<void> _showCoachHelpSheet() async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  ProductCopy.coachHelp,
                  style: context.gymTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.h),
                ..._LiveWorkoutQuickActions.actionIds.map((id) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${ProductCopy.quickActionEmoji(id)} '
                      '${ProductCopy.defaultQuickChipLabel(id, id)}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      unawaited(_openQuickAction(id));
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;

        return PopScope(
          // وسط جلسه: بک اول لایه (نام‌پد/تایمر) را می‌بندد، بعد صفحه.
          canPop: !state.isLoaded,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            unawaited(_handleBackPressed());
          },
          child: GymPageScaffold(
            title: ProductCopy.workoutSession,
            // Safari/iOS: system back is unreliable; always show in-app back.
            // Mid-session PopScope(canPop:false) would hide Flutter's auto leading.
            onBack: () => unawaited(_handleBackPressed()),
            centerContent: true,
            padding: EdgeInsets.zero,
            resizeToAvoidBottomInset: false,
            actions: state.isLoaded
                ? <Widget>[
                    IconButton(
                      tooltip: ProductCopy.coachHelp,
                      onPressed: () => unawaited(_showCoachHelpSheet()),
                      icon: Icon(GymIcons.coach, color: context.gymPrimary),
                    ),
                  ]
                : null,
            body: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(LiveWorkoutState state) {
    switch (state.status) {
      case LiveWorkoutStatus.loading:
        return const _LiveWorkoutSkeleton();
      case LiveWorkoutStatus.awaitingSession:
        return GymPagePadding(
          child: Column(
            children: <Widget>[
              ActiveProgramSelectorBar(
                program: state.activeProgram,
                onProgramChanged: _onProgramChanged,
              ),
              GymSpacing.gapLg,
              if (state.sessionContext != null)
                WorkoutSessionDayPicker(
                  sessions: state.sessionContext!.sessions,
                  selectedSessionDay: state.sessionContext!.selectedSessionDay,
                  onSessionDaySelected: _handleSessionDaySelected,
                ),
              GymSpacing.gapLg,
              const GymEmptyState(
                title: 'یک روز از برنامه را انتخاب کن',
                message:
                    'برای شروع ثبت ست‌ها، ابتدا روز برنامه را انتخاب کن. '
                    'اگر امروز ستی ثبت کرده باشی، با تغییر روز آن داده‌ها پاک می‌شود.',
                icon: GymIcons.calendar,
              ),
            ],
          ),
        );
      case LiveWorkoutStatus.empty:
        return GymPagePadding(
          child: Column(
            children: <Widget>[
              ActiveProgramSelectorBar(
                program: state.activeProgram,
                onProgramChanged: _onProgramChanged,
              ),
              GymSpacing.gapLg,
              const GymEmptyState(
                title: 'برنامه هوش مصنوعی فعال نیست',
                message:
                    'این مسیر فقط برای برنامه‌های مربی هوشمند است. '
                    'برنامه شروع باشگاه و برنامه مربی انسانی اینجا اجرا نمی‌شوند.',
                icon: GymIcons.calendar,
              ),
            ],
          ),
        );
      case LiveWorkoutStatus.error:
        return GymPagePadding(
          child: GymErrorState(
            title: 'خطا در بارگذاری تمرین',
            message: state.errorMessage ?? ProductCopy.coachLoadFailed,
            onRetry: () => unawaited(_viewModel.refresh()),
          ),
        );
      case LiveWorkoutStatus.sessionCompleted:
        final summary = state.completionSummary;
        if (summary == null) {
          return const GymPagePadding(
            child: GymEmptyState(
              title: 'تمرین ثبت شد',
              message: 'جلسه امروز ذخیره شد.',
              icon: GymIcons.success,
            ),
          );
        }
        return GymPagePadding(
          child: LiveWorkoutCompletionCard(summary: summary),
        );
      case LiveWorkoutStatus.loaded:
        final session = state.session!;
        if (session.exercises.isEmpty) {
          return const GymPagePadding(
            child: GymEmptyState(
              title: 'جلسه تمرین نامعتبر است',
              message: 'حرکتی برای ثبت پیدا نشد.',
              icon: GymIcons.workout,
            ),
          );
        }

        final tip = state.coachTips
            .map(ProductExperienceFormatter.humanizeReason)
            .firstWhere((item) => item.trim().isNotEmpty, orElse: () => '');

        // TapRegion باید کل ستون (شامل نام‌پد) را بپوشاند؛
        // وگرنه هر لمس روی پد «بیرون» حساب می‌شود و پد می‌پرد/بسته می‌شود.
        return TapRegion(
          onTapOutside: (_) => _dismissKeyboard(),
          child: Column(
            children: <Widget>[
              Expanded(
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (notification) {
                    if (notification.dragDetails != null && _numpad.isOpen) {
                      _numpad.close();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(height: 8.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: _LiveExecutionHeader(
                            programTitle: state.activeProgram?.title,
                            sessionDay:
                                state.sessionContext?.selectedSessionDay,
                            focus: session.focus,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: ListenableBuilder(
                            listenable: Listenable.merge([
                              _viewModel.sessionProgressTick,
                              _restDurationTick,
                            ]),
                            builder: (context, _) {
                              return LiveWorkoutSessionProgress(
                                session: session,
                                savedSets: _viewModel.savedSetsCount,
                                totalSets: _viewModel.totalSetsCount,
                                restDefaultSeconds: _restDurationSeconds,
                                onRestSettingsTap: () {
                                  unawaited(_openRestSettings());
                                },
                              );
                            },
                          ),
                        ),
                        if (_viewModel.isAnalysisMode &&
                            _viewModel.sessionAnalysis != null)
                          Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                            child: SessionAnalysisBody(
                              snapshot: _viewModel.sessionAnalysis!,
                              compact: true,
                              onResumeEditing: () {
                                HapticFeedback.selectionClick();
                                _viewModel.resumeSessionEditing();
                              },
                              onNarrativeReady:
                                  _viewModel.rememberAnalysisNarrative,
                            ),
                          )
                        else ...<Widget>[
                          if (state.completionSummary != null)
                            Padding(
                              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                              child: LiveWorkoutCompletionCard(
                                summary: state.completionSummary!,
                                onOpenAnalysis: () {
                                  HapticFeedback.selectionClick();
                                  unawaited(_ensureInlineAnalysis());
                                },
                              ),
                            ),
                          if (tip.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                              child: _LiveCoachTipLine(tip: tip),
                            ),
                          ...List.generate(_viewModel.displayExercises.length, (
                            index,
                          ) {
                            final exercise = _viewModel.displayExercises[index];
                            final exerciseKey = _exerciseKey(exercise);
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: RepaintBoundary(
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _viewModel
                                      .exerciseListenable(exerciseKey),
                                  builder: (context, _, __) {
                                    return ExerciseCard(
                                      exercise: exercise,
                                      exerciseDetails:
                                          _viewModel.exerciseDetails,
                                      exerciseControllers:
                                          _viewModel.exerciseControllers,
                                      exerciseFocusNodes:
                                          _viewModel.exerciseFocusNodes,
                                      setSavedStatus: _viewModel.setSavedStatus,
                                      collapsedExercises:
                                          _viewModel.collapsedExercises,
                                      exerciseCoachFeedback:
                                          _viewModel.exerciseCoachFeedback,
                                      previousSetsByExerciseId:
                                          _viewModel.previousSetsByExerciseId,
                                      compact: true,
                                      onToggleCollapse: _toggleExerciseCollapse,
                                      onNavigateToTutorial:
                                          _navigateToExerciseTutorial,
                                      onSaveSet: _handleSaveSet,
                                      onUnsaveSet: _handleUnsaveSet,
                                      onDismissKeyboard: _dismissKeyboard,
                                      numpad: _numpad,
                                    );
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (!_viewModel.isAnalysisMode)
                ListenableBuilder(
                  listenable: Listenable.merge([
                    _viewModel.restRemaining,
                    _viewModel.restTotal,
                    _viewModel.restRunning,
                    _viewModel.restSessionActive,
                    _viewModel.sessionProgressTick,
                  ]),
                  builder: (context, _) {
                    final showFinish = _viewModel.canFinishAndAnalyze;
                    final active = _viewModel.restSessionActive.value &&
                        _viewModel.restRemaining.value > 0;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (showFinish)
                          Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                            child: GymButton(
                              label: ProductCopy.finishWorkoutAndAnalyze,
                              fullWidth: true,
                              loading: _viewModel.isCompleting,
                              icon: GymIcons.progress,
                              onPressed: _viewModel.isCompleting
                                  ? null
                                  : () {
                                      HapticFeedback.mediumImpact();
                                      unawaited(_finishAndAnalyze());
                                    },
                            ),
                          ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.bottomCenter,
                          child: active
                              ? WorkoutRestTimerBar(
                                  remainingSeconds:
                                      _viewModel.restRemaining.value,
                                  totalSeconds: _viewModel.restTotal.value,
                                  isRunning: _viewModel.restRunning.value,
                                  attentionToken: _restAttentionTick,
                                  onTogglePause: _viewModel.toggleRestPause,
                                  onMinus15: () => _viewModel.adjustRestBy(-15),
                                  onPlus15: () => _viewModel.adjustRestBy(15),
                                  onSkip: _viewModel.skipRest,
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    );
                  },
                ),
              if (!_viewModel.isAnalysisMode)
                WorkoutSetNumpadBar(controller: _numpad),
            ],
          ),
        );
    }
  }

  String _exerciseKey(NormalExercise exercise) {
    return LiveWorkoutExerciseAdapter.controllerKey(exercise);
  }

  Future<void> _handleSessionDaySelected(String sessionDay) async {
    unawaited(HapticFeedback.selectionClick());
    final current = _viewModel.state.sessionContext?.selectedSessionDay;
    if (current == sessionDay) return;

    _dismissKeyboard();
    final evaluation = await _viewModel.evaluateSessionChange(sessionDay);
    if (!mounted) return;

    final confirmed = await WorkoutSessionSelectionHelper.confirmAndApply(
      context: context,
      evaluation: evaluation,
      newSessionDay: sessionDay,
      sessionGateway: _viewModel.sessionGateway,
    );
    if (!confirmed || !mounted) return;

    await _viewModel.selectSession(sessionDay);
  }

  Future<void> _finishAndAnalyze() async {
    _dismissKeyboard();
    _numpad.close();
    _manualAnalysisInFlight = true;
    _didAutoOpenAnalysis = true;
    try {
      await _viewModel.finishWorkout(openAnalysis: true);
    } finally {
      _manualAnalysisInFlight = false;
    }
  }

  Future<void> _ensureInlineAnalysis() async {
    if (_viewModel.isAnalysisMode) return;
    final snapshot = await _viewModel.buildAnalysisSnapshot(
      debrief: _viewModel.state.completionSummary?.debrief,
      synced: _viewModel.state.completionSummary?.synced ?? true,
    );
    if (!mounted || snapshot == null) return;
    _viewModel.showAnalysis(snapshot);
  }
}

/// Read-only context — program/day changes belong on Workout Today.
class _LiveExecutionHeader extends StatelessWidget {
  const _LiveExecutionHeader({
    required this.programTitle,
    required this.sessionDay,
    required this.focus,
  });

  final String? programTitle;
  final String? sessionDay;
  final String focus;

  @override
  Widget build(BuildContext context) {
    final dayLabel = (sessionDay != null && sessionDay!.isNotEmpty)
        ? sessionDay!
        : focus;
    final program = (programTitle != null && programTitle!.trim().isNotEmpty)
        ? programTitle!.trim()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            GymChip(
              label: ProductCopy.liveSessionInProgress,
              variant: GymChipVariant.filled,
            ),
            GymSpacing.gapSm,
            Expanded(
              child: Text(
                dayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.gymTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (program != null) ...[
          SizedBox(height: 6.h),
          Text(
            program,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.gymTextStyle(
              fontSize: 12,
              color: context.gymTextSecondary,
            ),
          ),
        ],
        SizedBox(height: 8.h),
        Text(
          ProductCopy.liveSessionModeHint,
          style: context.gymTextStyle(
            fontSize: 12,
            color: context.gymTextSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _LiveCoachTipLine extends StatelessWidget {
  const _LiveCoachTipLine({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: GymCardVariant.compact,
      padding: const EdgeInsets.symmetric(
        horizontal: GymSpacing.md,
        vertical: GymSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(GymIcons.success, size: 16, color: context.gymPrimary),
          GymSpacing.gapSm,
          Expanded(
            child: Text(
              tip,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.gymTextStyle(
                fontSize: 12,
                color: context.gymTextSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveWorkoutQuickActions {
  const _LiveWorkoutQuickActions._();

  static const List<String> actionIds = <String>[
    'form',
    'modify_workout',
    'recovery',
    'ask_coach',
  ];
}

class _LiveWorkoutSkeleton extends StatelessWidget {
  const _LiveWorkoutSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GymPagePadding(
      child: Column(
        children: <Widget>[
          GymSkeleton(variant: GymSkeletonVariant.hero),
          SizedBox(height: GymSpacing.lg),
          GymSkeleton(variant: GymSkeletonVariant.card),
          SizedBox(height: GymSpacing.lg),
          GymSkeleton(variant: GymSkeletonVariant.card),
          SizedBox(height: GymSpacing.lg),
          GymSkeleton(variant: GymSkeletonVariant.timeline),
        ],
      ),
    );
  }
}
