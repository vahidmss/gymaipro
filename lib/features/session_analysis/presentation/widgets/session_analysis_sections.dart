import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_chip.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/live_workout/presentation/live_workout_theme.dart';
import 'package:gymaipro/features/product_experience/domain/coach_observation.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_navigation.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/session_analysis/application/session_analysis_narrative_service.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_snapshot.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/models/previous_exercise_performance.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Embeddable analysis body (same-day view — not a separate “fake report” page).
class SessionAnalysisBody extends StatefulWidget {
  const SessionAnalysisBody({
    required this.snapshot,
    this.onResumeEditing,
    this.onNarrativeReady,
    this.narrativeService,
    this.compact = false,
    super.key,
  });

  final SessionAnalysisSnapshot snapshot;
  final VoidCallback? onResumeEditing;
  final ValueChanged<String>? onNarrativeReady;
  final SessionAnalysisNarrativeService? narrativeService;
  final bool compact;

  @override
  State<SessionAnalysisBody> createState() => _SessionAnalysisBodyState();
}

class _SessionAnalysisBodyState extends State<SessionAnalysisBody> {
  late final SessionAnalysisNarrativeService _narrativeService;
  String? _narrative;
  bool _loadingNarrative = true;

  @override
  void initState() {
    super.initState();
    _narrativeService =
        widget.narrativeService ?? SessionAnalysisNarrativeService();
    final stored = widget.snapshot.coachNarrative?.trim();
    if (stored != null && stored.isNotEmpty) {
      _narrative = stored;
      _loadingNarrative = false;
    } else {
      _loadNarrative();
    }
  }

  @override
  void didUpdateWidget(covariant SessionAnalysisBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.coachNarrative != widget.snapshot.coachNarrative ||
        oldWidget.snapshot.debrief.headline !=
            widget.snapshot.debrief.headline ||
        oldWidget.snapshot.completedSets != widget.snapshot.completedSets) {
      final stored = widget.snapshot.coachNarrative?.trim();
      if (stored != null && stored.isNotEmpty) {
        _loadingNarrative = false;
        _narrative = stored;
      } else {
        _loadingNarrative = true;
        _narrative = null;
        _loadNarrative();
      }
    }
  }

  Future<void> _loadNarrative() async {
    final text = await _narrativeService.narrate(widget.snapshot);
    if (!mounted) return;
    setState(() {
      _narrative = text;
      _loadingNarrative = false;
    });
    final ready = text?.trim();
    if (ready != null && ready.isNotEmpty) {
      widget.onNarrativeReady?.call(ready);
    }
  }

  Future<void> _onModifyPressed() async {
    if (!widget.snapshot.canModifyProgram) {
      await _showModifyLockedSheet();
      return;
    }
    await ProgramModifyNavigation.open(
      context,
      sessionDay: widget.snapshot.sessionDay,
      initialRequest: widget.snapshot.debrief.nextFocus,
    );
  }

  Future<void> _showModifyLockedSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  ProductCopy.modifyProgramLockedTitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.backgroundColor,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  ProductCopy.modifyProgramLockedBody,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    height: 1.55,
                    color: isDark
                        ? Colors.white70
                        : AppTheme.backgroundColor.withValues(alpha: 0.75),
                  ),
                ),
                SizedBox(height: 18.h),
                GymButton(
                  label: 'متوجه شدم',
                  fullWidth: true,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.onResumeEditing != null) ...<Widget>[
          GymButton(
            label: ProductCopy.resumeSessionEditing,
            fullWidth: true,
            variant: GymButtonVariant.secondary,
            icon: LucideIcons.pencil,
            onPressed: widget.onResumeEditing,
          ),
          GymSpacing.gapMd,
        ],
        SessionAnalysisHeroStats(snapshot: snapshot),
        SessionAnalysisLoggedWorkSection(snapshot: snapshot),
        GymSpacing.gapMd,
        SessionAnalysisCoachNarrativeCard(
          loading: _loadingNarrative,
          narrative: _narrative,
          fallbackHeadline: snapshot.debrief.headline,
          fallbackBullets: snapshot.debrief.bullets,
          nextFocus: snapshot.debrief.nextFocus,
          completedExercises: snapshot.completedExercises,
          plannedExercises: snapshot.plannedExercises,
        ),
        if (snapshot.comparisons.isNotEmpty) ...<Widget>[
          GymSpacing.gapMd,
          SessionAnalysisComparisonsSection(comparisons: snapshot.comparisons),
        ],
        if (snapshot.suggestions.isNotEmpty) ...<Widget>[
          GymSpacing.gapMd,
          SessionAnalysisSuggestionsSection(
            suggestions: snapshot.suggestions,
          ),
        ],
        if (snapshot.observations.isNotEmpty) ...<Widget>[
          GymSpacing.gapMd,
          SessionAnalysisObservationsSection(
            observations: snapshot.observations,
          ),
        ],
        GymSpacing.gapMd,
        GymCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(ProductCopy.modifyProgramTitle, style: context.lwTitle),
              GymSpacing.gapSm,
              Text(
                snapshot.canModifyProgram
                    ? ProductCopy.modifyProgramHint
                    : ProductCopy.modifyProgramLockedHint,
                style: context.lwCaption,
              ),
              GymSpacing.gapMd,
              GymButton(
                label: snapshot.canModifyProgram
                    ? ProductCopy.modifyProgramTitle
                    : ProductCopy.modifyProgramLockedCta,
                fullWidth: true,
                icon: snapshot.canModifyProgram
                    ? LucideIcons.pencil
                    : LucideIcons.lock,
                variant: snapshot.canModifyProgram
                    ? GymButtonVariant.primary
                    : GymButtonVariant.secondary,
                onPressed: _onModifyPressed,
              ),
            ],
          ),
        ),
        SizedBox(height: widget.compact ? 24.h : 40.h),
      ],
    );
  }
}

class SessionAnalysisHeroStats extends StatelessWidget {
  const SessionAnalysisHeroStats({required this.snapshot, super.key});

  final SessionAnalysisSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final calories = snapshot.estimatedCaloriesKcal;
    final title = snapshot.sessionDay?.trim().isNotEmpty == true
        ? snapshot.sessionDay!.trim()
        : (snapshot.focus.isNotEmpty ? snapshot.focus : snapshot.programTitle);
    return GymCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: context.lwTitle),
          if (snapshot.programTitle.trim().isNotEmpty &&
              snapshot.programTitle != title) ...<Widget>[
            GymSpacing.gapXs,
            Text(snapshot.programTitle, style: context.lwCaption),
          ],
          GymSpacing.gapMd,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: <Widget>[
              if (snapshot.durationMinutes >= 5)
                GymChip(label: '${snapshot.durationMinutes} دقیقه'),
              GymChip(
                label: '${snapshot.completedSets}/${snapshot.totalSets} ست',
              ),
              GymChip(
                label:
                    '${snapshot.completedExercises}/${snapshot.plannedExercises} حرکت',
              ),
              if (snapshot.totalVolumeKg > 0)
                GymChip(
                  label: 'حجم ${snapshot.totalVolumeKg.round()} کیلو',
                ),
              if (calories != null)
                GymChip(
                  label: ProductCopy.estimatedCaloriesLabel(calories),
                ),
            ],
          ),
          if (snapshot.isIncomplete) ...<Widget>[
            GymSpacing.gapMd,
            Text(
              ProductCopy.incompleteSessionHint(
                completed: snapshot.completedExercises,
                planned: snapshot.plannedExercises,
              ),
              style: context.lwBody.copyWith(
                color: context.gymWarning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SessionAnalysisLoggedWorkSection extends StatelessWidget {
  const SessionAnalysisLoggedWorkSection({required this.snapshot, super.key});

  final SessionAnalysisSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final rows = snapshot.comparisons
        .where((item) => item.todaySets.isNotEmpty)
        .toList(growable: false);
    final skipped = snapshot.skippedExerciseNames
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
    if (rows.isEmpty && skipped.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: GymSpacing.md),
      child: GymCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(ProductCopy.sessionLoggedWorkTitle, style: context.lwTitle),
          GymSpacing.gapSm,
          for (final item in rows)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.exerciseName,
                      style: context.lwCaption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      _joinSets(item.todaySets),
                      textAlign: TextAlign.left,
                      style: context.lwCaption,
                    ),
                  ),
                ],
              ),
            ),
          if (skipped.isNotEmpty) ...<Widget>[
            GymSpacing.gapXs,
            Text(
              'نزدی: ${skipped.take(4).join('، ')}'
              '${skipped.length > 4 ? '…' : ''}',
              style: context.lwCaption.copyWith(color: context.gymWarning),
            ),
            GymSpacing.gapXs,
            Text(
              ProductCopy.skippedExercisesCoachNote,
              style: context.lwCaption,
            ),
          ],
        ],
      ),
      ),
    );
  }

  static String _joinSets(List<PreviousExerciseSet> sets) {
    if (sets.isEmpty) return '—';
    final body = sets.map((s) => s.summaryLabel).join(' / ');
    return '\u2066$body\u2069';
  }
}

class SessionAnalysisCoachNarrativeCard extends StatelessWidget {
  const SessionAnalysisCoachNarrativeCard({
    required this.loading,
    required this.fallbackHeadline,
    required this.fallbackBullets,
    required this.nextFocus,
    required this.completedExercises,
    required this.plannedExercises,
    this.narrative,
    super.key,
  });

  final bool loading;
  final String? narrative;
  final String fallbackHeadline;
  final List<String> fallbackBullets;
  final String nextFocus;
  final int completedExercises;
  final int plannedExercises;

  @override
  Widget build(BuildContext context) {
    final uniqueBullets = <String>[];
    for (final b in fallbackBullets) {
      final t = b.trim();
      if (t.isEmpty) continue;
      if (t == nextFocus.trim()) continue;
      if (!uniqueBullets.contains(t)) uniqueBullets.add(t);
    }

    return GymCard(
      variant: GymCardVariant.insight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(ProductCopy.sessionDebriefTitle, style: context.lwTitle),
          GymSpacing.gapXs,
          Text(
            '$completedExercises از $plannedExercises حرکت',
            style: context.lwCaption,
          ),
          GymSpacing.gapMd,
          if (loading)
            Text(ProductCopy.sessionAnalysisThinking, style: context.lwCaption)
          else if (narrative != null && narrative!.trim().isNotEmpty)
            Text(narrative!, style: context.lwBody.copyWith(height: 1.55))
          else ...<Widget>[
            Text(
              fallbackHeadline,
              style: context.lwBody.copyWith(fontWeight: FontWeight.w700),
            ),
            GymSpacing.gapSm,
            for (final bullet in uniqueBullets.take(5))
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text('• $bullet', style: context.lwBody),
              ),
          ],
          if (nextFocus.trim().isNotEmpty) ...<Widget>[
            GymSpacing.gapMd,
            Text(
              ProductCopy.nextFocusTitle,
              style: context.lwCaption.copyWith(fontWeight: FontWeight.w800),
            ),
            GymSpacing.gapXs,
            Text(nextFocus, style: context.lwBody),
          ],
        ],
      ),
    );
  }
}

class SessionAnalysisComparisonsSection extends StatelessWidget {
  const SessionAnalysisComparisonsSection({
    required this.comparisons,
    super.key,
  });

  final List<SessionExerciseComparison> comparisons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(ProductCopy.sessionCompareTitle, style: context.lwTitle),
        GymSpacing.gapMd,
        for (final item in comparisons) ...<Widget>[
          GymCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.exerciseName,
                        style: context.lwBody.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (item.badge != null) GymChip(label: item.badge!),
                  ],
                ),
                GymSpacing.gapSm,
                Text(
                  'امروز: ${_joinSets(item.todaySets)}',
                  style: context.lwCaption,
                ),
                if (item.hasPreviousHistory)
                  Text(
                    'قبل${_dateSuffix(item.previousLogDate)}: '
                    '${_joinSets(item.previousSets)}',
                    style: context.lwCaption,
                  )
                else
                  Text(
                    'اولین ثبت این حرکت',
                    style: context.lwCaption,
                  ),
                if (item.comparisonLine != null &&
                    item.comparisonLine!.trim().isNotEmpty) ...<Widget>[
                  GymSpacing.gapSm,
                  Text(
                    item.comparisonLine!,
                    style: context.lwBody.copyWith(height: 1.55),
                  ),
                ],
                if (item.decision?.targetLine != null) ...<Widget>[
                  GymSpacing.gapSm,
                  Text(
                    item.decision!.targetLine!,
                    style: context.lwBody.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
          GymSpacing.gapSm,
        ],
      ],
    );
  }

  static String _joinSets(List<PreviousExerciseSet> sets) {
    if (sets.isEmpty) return '—';
    final body = sets.map((s) => s.summaryLabel).join(' / ');
    return '\u2066$body\u2069';
  }

  static String _dateSuffix(DateTime? date) {
    if (date == null) return '';
    final j = Jalali.fromDateTime(date);
    return ' (${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')})';
  }
}

class SessionAnalysisSuggestionsSection extends StatelessWidget {
  const SessionAnalysisSuggestionsSection({
    required this.suggestions,
    super.key,
  });

  final List<SessionNextSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(ProductCopy.sessionSuggestionsTitle, style: context.lwTitle),
          GymSpacing.gapMd,
          for (final item in suggestions.take(8)) ...<Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                '${item.title} — ${item.body}',
                style: context.lwBody.copyWith(height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SessionAnalysisObservationsSection extends StatelessWidget {
  const SessionAnalysisObservationsSection({
    required this.observations,
    super.key,
  });

  final List<CoachObservation> observations;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(ProductCopy.coachObservationsTitle, style: context.lwTitle),
          GymSpacing.gapMd,
          for (final item in observations) ...<Widget>[
            Text(
              item.severityLabel,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.goldColor,
              ),
            ),
            GymSpacing.gapXs,
            Text(item.message, style: context.lwBody),
            GymSpacing.gapMd,
          ],
        ],
      ),
    );
  }
}
