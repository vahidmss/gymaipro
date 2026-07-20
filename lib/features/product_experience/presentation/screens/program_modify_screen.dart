import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/product_experience/application/workout_program_modify_service.dart';
import 'package:gymaipro/features/product_experience/domain/program_modify_options.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_speech_card.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Selective «اصلاح برنامه» wizard — chips, not free-text.
class ProgramModifyScreen extends StatefulWidget {
  const ProgramModifyScreen({
    this.initialRequest,
    this.sessionDay,
    this.catalogExerciseId,
    this.service,
    super.key,
  });

  final String? initialRequest;
  final String? sessionDay;
  final int? catalogExerciseId;
  final WorkoutProgramModifyService? service;

  @override
  State<ProgramModifyScreen> createState() => _ProgramModifyScreenState();
}

class _ProgramModifyScreenState extends State<ProgramModifyScreen> {
  late final WorkoutProgramModifyService _service;
  final ScrollController _scrollController = ScrollController();

  ProgramModifyContext? _context;
  bool _loadingContext = true;
  String? _contextError;

  ProgramModifyGoal? _goal;
  String? _sessionDay;
  int? _exerciseId;
  String? _reasonId;

  ProgramModifyProposal? _proposal;
  bool _proposing = false;
  bool _applying = false;
  String? _error;
  bool _editingSelection = true;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? WorkoutProgramModifyService();
    _sessionDay = widget.sessionDay;
    _exerciseId = widget.catalogExerciseId;
    _goal = _inferGoalFromPrompt(widget.initialRequest);
    unawaited(_loadContext());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  ProgramModifyGoal? _inferGoalFromPrompt(String? prompt) {
    final text = prompt?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.contains('جایگزین') || text.contains('نمی‌توانم')) {
      return ProgramModifyGoal.replaceExercise;
    }
    if (text.contains('حذف')) return ProgramModifyGoal.removeExercise;
    if (text.contains('سبک') || text.contains('خسته')) {
      return ProgramModifyGoal.tiredAdapt;
    }
    if (text.contains('سنگین')) return ProgramModifyGoal.harderSession;
    if (text.contains('کوتاه')) return ProgramModifyGoal.shorterSession;
    if (text.contains('خانه') || text.contains('خانگی')) {
      return ProgramModifyGoal.homeVersion;
    }
    if (text.contains('آسیب')) return ProgramModifyGoal.injuryAdapt;
    return ProgramModifyGoal.replaceExercise;
  }

  Future<void> _loadContext() async {
    setState(() {
      _loadingContext = true;
      _contextError = null;
    });
    try {
      final loaded = await _service.loadContext(sessionDay: widget.sessionDay);
      if (!mounted) return;
      if (loaded == null) {
        setState(() {
          _loadingContext = false;
          _contextError = 'برنامه فعالی برای اصلاح پیدا نشد.';
        });
        return;
      }
      final day = (_sessionDay != null &&
              loaded.sessions.any((s) => s.day == _sessionDay))
          ? _sessionDay
          : loaded.selectedDay;
      final session = loaded.sessionFor(day);
      final exerciseStillValid = session?.exercises
              .any((e) => e.catalogExerciseId == _exerciseId) ??
          false;
      setState(() {
        _context = loaded;
        _sessionDay = day;
        if (!exerciseStillValid) _exerciseId = null;
        _loadingContext = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingContext = false;
        _contextError = error.toString();
      });
    }
  }

  bool get _canPropose {
    final goal = _goal;
    if (goal == null || _proposing) return false;
    if (goal.needsExercise && (_exerciseId == null || _exerciseId! <= 0)) {
      return false;
    }
    if (goal.needsReason && (_reasonId == null || _reasonId!.isEmpty)) {
      return false;
    }
    return true;
  }

  Future<void> _propose() async {
    final goal = _goal;
    final ctx = _context;
    if (goal == null || ctx == null || !_canPropose) return;

    final session = ctx.sessionFor(_sessionDay);
    final exercise = session?.exercises
        .where((e) => e.catalogExerciseId == _exerciseId)
        .firstOrNull;
    final reasons = ProgramModifyOptions.reasonsFor(goal);
    final reason = reasons.where((r) => r.id == _reasonId).firstOrNull;

    setState(() {
      _proposing = true;
      _error = null;
      _proposal = null;
    });

    try {
      final proposal = await _service.proposeFromSelection(
        goal: goal,
        programId: ctx.programId,
        sessionDay: _sessionDay,
        catalogExerciseId: _exerciseId,
        exerciseName: exercise?.name,
        reasonId: reason?.id,
        reasonLabel: reason?.label,
      );
      if (!mounted) return;
      setState(() {
        _proposal = proposal;
        _proposing = false;
        _editingSelection = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        unawaited(
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          ),
        );
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _proposing = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _apply() async {
    final proposal = _proposal;
    if (proposal == null || !proposal.canApply) return;
    setState(() => _applying = true);
    try {
      final error = await _service.apply(proposal);
      if (!mounted) return;
      if (error != null) {
        setState(() {
          _applying = false;
          _error = error;
        });
        return;
      }
      unawaited(HapticFeedback.mediumImpact());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تغییر روی برنامه ذخیره شد.',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!mounted) return;
      await Navigator.of(context).maybePop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _error = error.toString();
      });
    }
  }

  void _selectGoal(ProgramModifyGoal goal) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _goal = goal;
      _proposal = null;
      _error = null;
      _editingSelection = true;
      if (!goal.needsExercise) _exerciseId = null;
      if (!goal.needsReason) {
        _reasonId = null;
      } else {
        final reasons = ProgramModifyOptions.reasonsFor(goal);
        if (_reasonId == null || !reasons.any((r) => r.id == _reasonId)) {
          _reasonId = reasons.isEmpty ? null : reasons.first.id;
        }
      }
    });
  }

  void _selectDay(String day) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _sessionDay = day;
      _proposal = null;
      _editingSelection = true;
      final session = _context?.sessionFor(day);
      final stillValid = session?.exercises
              .any((e) => e.catalogExerciseId == _exerciseId) ??
          false;
      if (!stillValid) _exerciseId = null;
    });
  }

  void _selectExercise(int id) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _exerciseId = id;
      _proposal = null;
      _editingSelection = true;
    });
  }

  void _selectReason(String id) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _reasonId = id;
      _proposal = null;
      _editingSelection = true;
    });
  }

  String _selectionSummary(ProgramModifyContext ctx) {
    final parts = <String>[];
    if (_goal != null) parts.add(_goal!.label);
    if (_sessionDay != null && _sessionDay!.isNotEmpty) {
      parts.add(_sessionDay!);
    }
    final session = ctx.sessionFor(_sessionDay);
    final exercise = session?.exercises
        .where((e) => e.catalogExerciseId == _exerciseId)
        .firstOrNull;
    if (exercise != null) parts.add(exercise.name);
    if (_reasonId != null && _goal != null) {
      final reason = ProgramModifyOptions.reasonsFor(_goal!)
          .where((r) => r.id == _reasonId)
          .firstOrNull;
      if (reason != null) parts.add(reason.label);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return GymPageScaffold(
      title: ProductCopy.modifyProgramTitle,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingContext) {
      return const GymPagePadding(
        child: Column(
          children: <Widget>[
            GymSkeleton(variant: GymSkeletonVariant.card),
            SizedBox(height: GymSpacing.lg),
            GymSkeleton(variant: GymSkeletonVariant.card),
          ],
        ),
      );
    }

    if (_contextError != null || _context == null) {
      return GymPagePadding(
        child: GymEmptyState(
          title: 'برنامه برای اصلاح نیست',
          message: _contextError ?? 'اول یک برنامه فعال انتخاب کن.',
          actionLabel: ProductCopy.retry,
          onAction: () => unawaited(_loadContext()),
        ),
      );
    }

    final ctx = _context!;
    final goal = _goal;
    final session = ctx.sessionFor(_sessionDay);
    final reasons = goal == null
        ? const <ProgramModifyReasonOption>[]
        : ProgramModifyOptions.reasonsFor(goal);
    final showWizard = _editingSelection || _proposal == null;
    var step = 1;

    return GymPagePadding(
      child: ListView(
        controller: _scrollController,
        children: <Widget>[
          Text(
            ctx.programName,
            style: context.gymTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          GymSpacing.gapXs,
          Text(
            ProductCopy.modifyProgramHint,
            style: context.gymTextStyle(
              fontSize: 13,
              color: context.gymTextPrimary.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          GymSpacing.gapLg,

          if (_proposal != null) ...<Widget>[
            _CoachReplyCard(
              proposal: _proposal!,
              onSuggestedGoal: _selectGoal,
            ),
            if (_proposal!.canApply) ...<Widget>[
              GymSpacing.gapLg,
              GymButton(
                label: 'تأیید و ذخیره روی برنامه',
                fullWidth: true,
                loading: _applying,
                onPressed: _applying ? null : () => unawaited(_apply()),
              ),
              GymSpacing.gapSm,
              Text(
                'تا وقتی تأیید نکنی، برنامه فعلی عوض نمی‌شود.',
                style: context.gymTextStyle(
                  fontSize: 12,
                  color: context.gymTextPrimary.withValues(alpha: 0.65),
                ),
              ),
            ],
            GymSpacing.gapLg,
            GymCard(
              variant: GymCardVariant.metric,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'انتخاب تو',
                          style: context.gymTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.gymPrimary,
                          ),
                        ),
                        GymSpacing.gapXs,
                        Text(
                          _selectionSummary(ctx),
                          style: context.gymTextStyle(
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _editingSelection = true);
                    },
                    child: Text(
                      showWizard ? 'باز است' : 'تغییر',
                      style: context.gymTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.gymPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GymSpacing.gapMd,
          ],

          if (showWizard) ...<Widget>[
            _StepCard(
              step: step++,
              title: 'چه می‌خواهی؟',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SelectChipWrap(
                    children: ProgramModifyOptions.goals.map((item) {
                      return _SelectChip(
                        label: item.label,
                        selected: _goal == item,
                        onTap: () => _selectGoal(item),
                      );
                    }).toList(),
                  ),
                  if (goal != null) ...<Widget>[
                    GymSpacing.gapSm,
                    Text(
                      goal.hint,
                      style: context.gymTextStyle(
                        fontSize: 12,
                        color: context.gymTextPrimary.withValues(alpha: 0.68),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (ctx.sessions.length > 1) ...<Widget>[
              GymSpacing.gapMd,
              _StepCard(
                step: step++,
                title: 'کدام روز؟',
                child: _SelectChipWrap(
                  children: ctx.sessions.map((item) {
                    return _SelectChip(
                      label: item.day,
                      selected: _sessionDay == item.day,
                      onTap: () => _selectDay(item.day),
                    );
                  }).toList(),
                ),
              ),
            ],

            if (goal != null && goal.needsExercise) ...<Widget>[
              GymSpacing.gapMd,
              _StepCard(
                step: step++,
                title: 'کدام حرکت؟',
                child: session == null || session.exercises.isEmpty
                    ? Text(
                        'برای این روز حرکتی پیدا نشد.',
                        style: context.gymTextStyle(
                          fontSize: 13,
                          color: AppTheme.errorColor,
                        ),
                      )
                    : _SelectChipWrap(
                        children: session.exercises.map((item) {
                          final label = item.meta == null
                              ? item.name
                              : '${item.name} · ${item.meta}';
                          return _SelectChip(
                            label: label,
                            selected: _exerciseId == item.catalogExerciseId,
                            onTap: () =>
                                _selectExercise(item.catalogExerciseId),
                          );
                        }).toList(),
                      ),
              ),
            ],

            if (goal != null &&
                goal.needsReason &&
                reasons.isNotEmpty) ...<Widget>[
              GymSpacing.gapMd,
              _StepCard(
                step: step++,
                title: 'چرا؟',
                child: _SelectChipWrap(
                  children: reasons.map((item) {
                    return _SelectChip(
                      label: item.label,
                      selected: _reasonId == item.id,
                      onTap: () => _selectReason(item.id),
                    );
                  }).toList(),
                ),
              ),
            ],

            GymSpacing.gapXl,
            GymButton(
              label: _proposing ? 'در حال بررسی…' : 'ببین مربی چه می‌گوید',
              fullWidth: true,
              loading: _proposing,
              onPressed: _canPropose ? () => unawaited(_propose()) : null,
            ),
            if (!_canPropose && goal != null && !_proposing) ...<Widget>[
              GymSpacing.gapSm,
              Text(
                goal.needsExercise && _exerciseId == null
                    ? 'حرکت را هم انتخاب کن.'
                    : goal.needsReason && _reasonId == null
                        ? 'دلیل را هم انتخاب کن.'
                        : 'گزینه‌ها را کامل کن.',
                style: context.gymTextStyle(
                  fontSize: 12,
                  color: context.gymTextPrimary.withValues(alpha: 0.65),
                ),
              ),
            ],
          ],

          if (_error != null) ...<Widget>[
            GymSpacing.gapMd,
            Text(
              _error!,
              style: context.gymTextStyle(
                fontSize: 12,
                color: AppTheme.errorColor,
              ),
            ),
          ],

          const SizedBox(height: GymSpacing.massive),
        ],
      ),
    );
  }
}

/// One clear coach reply: request → decision → changes → tip.
class _CoachReplyCard extends StatelessWidget {
  const _CoachReplyCard({
    required this.proposal,
    required this.onSuggestedGoal,
  });

  final ProgramModifyProposal proposal;
  final ValueChanged<ProgramModifyGoal> onSuggestedGoal;

  @override
  Widget build(BuildContext context) {
    return CoachSpeechCard(
      title: proposal.canApply ? 'پاسخ مربی' : 'نظر مربی',
      variant:
          proposal.canApply ? GymCardVariant.action : GymCardVariant.warning,
      avatarSize: 40,
      padding: const EdgeInsets.all(GymSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (proposal.coachHeard != null &&
              proposal.coachHeard!.trim().isNotEmpty) ...<Widget>[
            Text(
              'درخواست تو',
              style: context.gymTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.gymPrimary,
              ),
            ),
            GymSpacing.gapXs,
            Text(
              proposal.coachHeard!,
              style: context.gymTextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.gymTextPrimary.withValues(alpha: 0.8),
              ),
            ),
            GymSpacing.gapMd,
            Divider(color: context.gymBorderSubtle, height: 1),
            GymSpacing.gapMd,
          ],
          Text(
            'تصمیم مربی',
            style: context.gymTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.gymPrimary,
            ),
          ),
          GymSpacing.gapXs,
          Text(
            proposal.title,
            style: context.gymTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          GymSpacing.gapSm,
          Text(
            proposal.message,
            style: context.gymTextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (proposal.changeLines.isNotEmpty) ...<Widget>[
            GymSpacing.gapMd,
            Text(
              'خلاصه تغییر',
              style: context.gymTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: context.gymPrimary,
              ),
            ),
            GymSpacing.gapSm,
            for (final line in proposal.changeLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '•  ',
                      style: context.gymTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: context.gymTextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (proposal.aiAdvice != null &&
              proposal.aiAdvice!.trim().isNotEmpty) ...<Widget>[
            GymSpacing.gapMd,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(GymSpacing.md),
              decoration: BoxDecoration(
                color: context.gymElevated,
                borderRadius: GymRadius.radiusLg,
                border: Border.all(color: context.gymBorderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'نکته مربی',
                    style: context.gymTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.gymPrimary,
                    ),
                  ),
                  GymSpacing.gapXs,
                  Text(
                    proposal.aiAdvice!,
                    style: context.gymTextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: context.gymTextPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (proposal.coachTips.isNotEmpty) ...<Widget>[
            GymSpacing.gapMd,
            Text(
              proposal.coachTips.first,
              style: context.gymTextStyle(
                fontSize: 12,
                height: 1.4,
                color: context.gymTextPrimary.withValues(alpha: 0.75),
              ),
            ),
          ],
          if (proposal.suggestedGoals.isNotEmpty) ...<Widget>[
            GymSpacing.gapMd,
            Text(
              'به‌جای این می‌توانی:',
              style: context.gymTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            GymSpacing.gapSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: proposal.suggestedGoals.map((goal) {
                return _SelectChip(
                  label: goal.label,
                  selected: false,
                  onTap: () => onSuggestedGoal(goal),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.child,
  });

  final int step;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: GymCardVariant.metric,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.gymPrimary.withValues(alpha: 0.18),
                  borderRadius: GymRadius.radiusMd,
                  border: Border.all(color: context.gymPrimary),
                ),
                child: Text(
                  '$step',
                  style: context.gymTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.gymPrimary,
                  ),
                ),
              ),
              GymSpacing.gapSm,
              Expanded(
                child: Text(
                  title,
                  style: context.gymTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          GymSpacing.gapMd,
          child,
        ],
      ),
    );
  }
}

class _SelectChipWrap extends StatelessWidget {
  const _SelectChipWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.gymPrimary;
    final bg = selected
        ? primary.withValues(alpha: context.gymIsDark ? 0.22 : 0.2)
        : context.gymElevated;
    final border = selected
        ? primary
        : context.gymTextPrimary.withValues(alpha: 0.18);
    final text = selected ? primary : context.gymTextPrimary;

    return Material(
      color: bg,
      borderRadius: GymRadius.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: GymRadius.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GymSpacing.lg,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: GymRadius.pill,
            border: Border.all(color: border, width: selected ? 1.5 : 1),
          ),
          child: Text(
            label,
            style: context.gymTextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: text,
            ),
          ),
        ),
      ),
    );
  }
}
