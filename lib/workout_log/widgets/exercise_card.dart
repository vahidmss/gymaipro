import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';
import 'package:gymaipro/features/product_experience/presentation/workout_exercise_coach_feedback_card.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/models/previous_exercise_performance.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:gymaipro/workout_log/widgets/workout_set_entry_row.dart';
import 'package:gymaipro/workout_log/widgets/workout_set_numpad.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    required this.exercise,
    required this.exerciseDetails,
    required this.exerciseControllers,
    required this.exerciseFocusNodes,
    required this.setSavedStatus,
    required this.collapsedExercises,
    required this.onToggleCollapse,
    required this.onNavigateToTutorial,
    required this.onSaveSet,
    this.onUnsaveSet,
    this.previousSetsByExerciseId = const {},
    this.orderIndex = 1,
    this.exerciseCoachFeedback = const <String, WorkoutExerciseCoachFeedback>{},
    this.compact = false,
    this.onDismissKeyboard,
    this.numpad,
    super.key,
  });

  final WorkoutExercise exercise;
  final Map<int, Exercise> exerciseDetails;
  final Map<String, List<Map<String, TextEditingController>>>
  exerciseControllers;
  final Map<String, List<Map<String, FocusNode>>> exerciseFocusNodes;
  final Map<String, List<bool>> setSavedStatus;
  final Map<String, bool> collapsedExercises;
  final Map<String, WorkoutExerciseCoachFeedback> exerciseCoachFeedback;
  final Map<int, List<PreviousExerciseSet>> previousSetsByExerciseId;
  final void Function(String) onToggleCollapse;
  final void Function(int) onNavigateToTutorial;
  final Future<bool> Function(String, int) onSaveSet;
  final void Function(String, int)? onUnsaveSet;

  /// ترتیب حرکت در جلسه (۱، ۲، ۳، …)
  final int orderIndex;
  final bool compact;
  final VoidCallback? onDismissKeyboard;
  final WorkoutSetNumpadController? numpad;

  @override
  Widget build(BuildContext context) {
    if (exercise is NormalExercise) {
      return _buildNormal(context, exercise as NormalExercise);
    }
    if (exercise is SupersetExercise) {
      return _buildSuperset(context, exercise as SupersetExercise);
    }
    return const SizedBox.shrink();
  }

  Widget _shell({
    required BuildContext context,
    required bool complete,
    required Widget child,
    bool focused = false,
  }) {
    final borderColor = focused
        ? AppTheme.goldColor.withValues(alpha: 0.42)
        : complete
        ? WorkoutLogColors.successSolid(context).withValues(alpha: 0.4)
        : WorkoutLogColors.inputBorder(context);

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 6.h : 8.h),
      decoration: BoxDecoration(
        color: focused
            ? context.surfaceElevated
            : WorkoutLogColors.sectionBackground(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: focused ? 1.2.w : 1.w),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  Widget _buildNormal(BuildContext context, NormalExercise exercise) {
    final exerciseId = exercise.exerciseId.toString();
    final savedStatus = setSavedStatus[exerciseId] ?? [];
    final focusNodes = exerciseFocusNodes[exerciseId] ?? [];
    final controllers = exerciseControllers[exerciseId] ?? [];
    final isCollapsed = collapsedExercises[exerciseId] ?? false;
    final completedSets = savedStatus.where((s) => s).length;
    final totalSets = exercise.sets.length;
    final isComplete = totalSets > 0 && completedSets >= totalSets;
    final name = _name(exercise.exerciseId, fallbackTag: exercise.tag);
    final statusText = isCollapsed && isComplete
        ? _summary(exercise, controllers, savedStatus)
        : isComplete
        ? 'کامل'
        : (!isCollapsed
              ? 'در حال ثبت · $completedSets/$totalSets'
              : '$completedSets/$totalSets');
    final note = exercise.note?.trim();

    return _shell(
      context: context,
      complete: isComplete,
      focused: !isCollapsed && !isComplete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              onDismissKeyboard?.call();
              numpad?.close();
              onToggleCollapse(exerciseId);
            },
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 8.w, 11.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderBadge(index: orderIndex, complete: isComplete),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: WorkoutLogTypography.exerciseTitle(
                            context,
                          ).copyWith(fontSize: 15.sp, height: 1.25),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          statusText,
                          style: WorkoutLogTypography.caption(
                            context,
                            color: isComplete
                                ? WorkoutLogColors.successText(context)
                                : WorkoutLogColors.mutedText(context),
                            fontWeight: FontWeight.w700,
                          ).copyWith(fontSize: 11.sp),
                          textDirection: isCollapsed && isComplete
                              ? TextDirection.ltr
                              : null,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isCollapsed &&
                            note != null &&
                            note.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: WorkoutLogTypography.caption(
                              context,
                              color: WorkoutLogColors.mutedText(context),
                            ).copyWith(fontSize: 11.sp, height: 1.35),
                          ),
                        ],
                        if (!isCollapsed)
                          _PreviousSetsLine(
                            previousSets:
                                previousSetsByExerciseId[exercise.exerciseId],
                          ),
                      ],
                    ),
                  ),
                  _HeaderActions(
                    isCollapsed: isCollapsed,
                    onTutorial: () => onNavigateToTutorial(exercise.exerciseId),
                  ),
                ],
              ),
            ),
          ),
          if (!isCollapsed)
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 8.h),
              child: Column(
                children: [
                  _SetColumnLabels(style: exercise.style),
                  ...List.generate(exercise.sets.length, (setIndex) {
                    if (controllers.length <= setIndex) {
                      return const SizedBox.shrink();
                    }
                    final previous =
                        previousSetsByExerciseId[exercise.exerciseId];
                    final prevSet =
                        previous != null && setIndex < previous.length
                        ? previous[setIndex]
                        : null;
                    return WorkoutSetEntryRow(
                      setIndex: setIndex,
                      isSaved:
                          savedStatus.length > setIndex &&
                          savedStatus[setIndex],
                      setControllers: controllers[setIndex],
                      style: exercise.style,
                      focusNodes: focusNodes.length > setIndex
                          ? focusNodes[setIndex]
                          : null,
                      isLastSet: setIndex == exercise.sets.length - 1,
                      defaultReps: exercise.style == ExerciseStyle.setsReps
                          ? exercise.sets[setIndex].reps
                          : null,
                      defaultWeight: exercise.style == ExerciseStyle.setsReps
                          ? exercise.sets[setIndex].weight
                          : null,
                      defaultTimeSeconds:
                          exercise.style == ExerciseStyle.setsTime
                          ? exercise.sets[setIndex].timeSeconds
                          : null,
                      previousReps: prevSet?.reps,
                      previousWeight: prevSet?.weight,
                      previousTimeSeconds: prevSet?.seconds,
                      numpad: numpad,
                      onSaveSet: () => onSaveSet(exerciseId, setIndex),
                      onUnsaveSet: () =>
                          onUnsaveSet?.call(exerciseId, setIndex),
                      onOpenNextSet: setIndex < exercise.sets.length - 1
                          ? () => _openNextSetDock(
                              numpad: numpad,
                              controllers: controllers,
                              savedStatus: savedStatus,
                              style: exercise.style,
                              exerciseId: exerciseId,
                              nextIndex: setIndex + 1,
                              lastIndex: exercise.sets.length - 1,
                              sets: exercise.sets,
                              previousSets: previous,
                              onSaveSet: onSaveSet,
                              onUnsaveSet: onUnsaveSet,
                            )
                          : null,
                    );
                  }),
                ],
              ),
            ),
          if (isComplete && exerciseCoachFeedback[exerciseId] != null)
            WorkoutExerciseCoachFeedbackCard(
              feedback: exerciseCoachFeedback[exerciseId]!,
              compact: true,
            ),
        ],
      ),
    );
  }

  Widget _buildSuperset(BuildContext context, SupersetExercise exercise) {
    final exerciseId = exercise.id;
    final isCollapsed = collapsedExercises[exerciseId] ?? false;
    var completed = 0;
    var total = 0;
    for (final item in exercise.exercises) {
      final itemId = '${exercise.id}_${item.exerciseId}';
      final status = setSavedStatus[itemId] ?? [];
      completed += status.where((s) => s).length;
      total += item.sets.length;
    }
    final isComplete = total > 0 && completed >= total;

    return _shell(
      context: context,
      complete: isComplete,
      focused: !isCollapsed && !isComplete,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              onDismissKeyboard?.call();
              numpad?.close();
              onToggleCollapse(exerciseId);
            },
            borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 10.w, 10.h),
              child: Row(
                children: [
                  _OrderBadge(index: orderIndex, complete: isComplete),
                  SizedBox(width: 10.w),
                  Icon(LucideIcons.zap, size: 14.sp, color: AppTheme.goldColor),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.tag.isNotEmpty
                              ? 'سوپرست · ${exercise.tag}'
                              : 'سوپرست',
                          style: WorkoutLogTypography.exerciseTitle(
                            context,
                          ).copyWith(fontSize: 14.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isComplete
                              ? 'کامل'
                              : (!isCollapsed
                                    ? 'در حال ثبت · $completed/$total'
                                    : '$completed/$total'),
                          style: WorkoutLogTypography.caption(
                            context,
                            color: isComplete
                                ? WorkoutLogColors.successText(context)
                                : WorkoutLogColors.mutedText(context),
                            fontWeight: FontWeight.w700,
                          ).copyWith(fontSize: 11.sp),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isCollapsed
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronUp,
                    size: 18.sp,
                    color: WorkoutLogColors.mutedText(context),
                  ),
                ],
              ),
            ),
          ),
          if (!isCollapsed)
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 8.h),
              child: Column(
                children: exercise.exercises.map((item) {
                  final itemId = '${exercise.id}_${item.exerciseId}';
                  final controllers = exerciseControllers[itemId] ?? [];
                  final focusNodes = exerciseFocusNodes[itemId] ?? [];
                  final savedStatus = setSavedStatus[itemId] ?? [];
                  return Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text(
                            _name(item.exerciseId),
                            style: WorkoutLogTypography.caption(
                              context,
                              fontWeight: FontWeight.w800,
                            ).copyWith(fontSize: 12.sp),
                          ),
                        ),
                        _PreviousSetsLine(
                          previousSets:
                              previousSetsByExerciseId[item.exerciseId],
                        ),
                        SizedBox(height: 4.h),
                        ...List.generate(item.sets.length, (setIndex) {
                          if (controllers.length <= setIndex) {
                            return const SizedBox.shrink();
                          }
                          final previous =
                              previousSetsByExerciseId[item.exerciseId];
                          final prevSet =
                              previous != null && setIndex < previous.length
                              ? previous[setIndex]
                              : null;
                          return WorkoutSetEntryRow(
                            setIndex: setIndex,
                            isSaved:
                                savedStatus.length > setIndex &&
                                savedStatus[setIndex],
                            setControllers: controllers[setIndex],
                            style: item.style,
                            focusNodes: focusNodes.length > setIndex
                                ? focusNodes[setIndex]
                                : null,
                            isLastSet: setIndex == item.sets.length - 1,
                            defaultReps: item.style == ExerciseStyle.setsReps
                                ? item.sets[setIndex].reps
                                : null,
                            defaultWeight: item.style == ExerciseStyle.setsReps
                                ? item.sets[setIndex].weight
                                : null,
                            defaultTimeSeconds:
                                item.style == ExerciseStyle.setsTime
                                ? item.sets[setIndex].timeSeconds
                                : null,
                            previousReps: prevSet?.reps,
                            previousWeight: prevSet?.weight,
                            previousTimeSeconds: prevSet?.seconds,
                            numpad: numpad,
                            onSaveSet: () => onSaveSet(itemId, setIndex),
                            onUnsaveSet: () =>
                                onUnsaveSet?.call(itemId, setIndex),
                            onOpenNextSet: setIndex < item.sets.length - 1
                                ? () => _openNextSetDock(
                                    numpad: numpad,
                                    controllers: controllers,
                                    savedStatus: savedStatus,
                                    style: item.style,
                                    exerciseId: itemId,
                                    nextIndex: setIndex + 1,
                                    lastIndex: item.sets.length - 1,
                                    sets: item.sets,
                                    previousSets: previous,
                                    onSaveSet: onSaveSet,
                                    onUnsaveSet: onUnsaveSet,
                                  )
                                : null,
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _openNextSetDock({
    required WorkoutSetNumpadController? numpad,
    required List<Map<String, TextEditingController>> controllers,
    required List<bool> savedStatus,
    required ExerciseStyle style,
    required String exerciseId,
    required int nextIndex,
    required int lastIndex,
    required List<ExerciseSet> sets,
    required Future<bool> Function(String, int) onSaveSet,
    required void Function(String, int)? onUnsaveSet,
    List<PreviousExerciseSet>? previousSets,
  }) {
    if (numpad == null || nextIndex >= controllers.length) return;
    final c = controllers[nextIndex];
    final set = sets[nextIndex];
    final prev = previousSets != null && nextIndex < previousSets.length
        ? previousSets[nextIndex]
        : null;
    final hintReps = prev?.reps ?? set.reps;
    final hintWeight = (prev?.weight != null && prev!.weight! > 0)
        ? prev.weight
        : set.weight;
    final hintTime = prev?.seconds ?? set.timeSeconds;
    final isSaved = savedStatus.length > nextIndex && savedStatus[nextIndex];

    void seed() {
      if (style == ExerciseStyle.setsReps) {
        if ((c['reps']?.text.trim().isEmpty ?? true) && hintReps != null) {
          c['reps']!.text = hintReps.toString();
        }
        if ((c['weight']?.text.trim().isEmpty ?? true) &&
            hintWeight != null &&
            hintWeight > 0) {
          final w = hintWeight;
          c['weight']!.text = w == w.roundToDouble()
              ? w.toInt().toString()
              : w.toString();
        }
      } else if ((c['time']?.text.trim().isEmpty ?? true) && hintTime != null) {
        c['time']!.text = hintTime.toString();
      }
    }

    final field = style == ExerciseStyle.setsReps
        ? WorkoutSetNumpadFieldKind.reps
        : WorkoutSetNumpadFieldKind.time;

    numpad.open(
      WorkoutSetNumpadSession(
        controllers: c,
        style: style,
        isSaved: isSaved,
        repsHint: hintReps?.toString(),
        weightHint: hintWeight != null && hintWeight > 0
            ? (hintWeight == hintWeight.roundToDouble()
                  ? hintWeight.toInt().toString()
                  : hintWeight.toString())
            : null,
        timeHint: hintTime?.toString(),
        onCommit: () async {
          seed();
          return onSaveSet(exerciseId, nextIndex);
        },
        onPersistEdits: () {
          // ignore: discarded_futures
          onSaveSet(exerciseId, nextIndex);
        },
        onFinished: nextIndex < lastIndex
            ? () => _openNextSetDock(
                numpad: numpad,
                controllers: controllers,
                savedStatus: savedStatus,
                style: style,
                exerciseId: exerciseId,
                nextIndex: nextIndex + 1,
                lastIndex: lastIndex,
                sets: sets,
                previousSets: previousSets,
                onSaveSet: onSaveSet,
                onUnsaveSet: onUnsaveSet,
              )
            : null,
        field: field,
      ),
      field: field,
    );
  }

  String _summary(
    NormalExercise exercise,
    List<Map<String, TextEditingController>> controllers,
    List<bool> savedStatus,
  ) {
    final parts = <String>[];
    for (var i = 0; i < controllers.length; i++) {
      if (i >= savedStatus.length || !savedStatus[i]) continue;
      final c = controllers[i];
      if (exercise.style == ExerciseStyle.setsTime) {
        final t = c['time']?.text.trim() ?? '';
        if (t.isNotEmpty) parts.add('$tث');
      } else {
        final reps = c['reps']?.text.trim() ?? '';
        final weight = c['weight']?.text.trim() ?? '';
        if (reps.isEmpty && weight.isEmpty) continue;
        if (weight.isEmpty) {
          parts.add(reps);
        } else if (reps.isEmpty) {
          parts.add(_fmtWeight(weight));
        } else {
          parts.add('\u200E$reps\u00D7${_fmtWeight(weight)}');
        }
      }
    }
    return parts.isEmpty ? 'کامل' : parts.join('  ·  ');
  }

  static String _fmtWeight(String raw) {
    final d = double.tryParse(raw);
    if (d == null) return raw;
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toString();
  }

  String _name(int exerciseId, {String? fallbackTag}) {
    final detail = exerciseDetails[exerciseId];
    if (detail != null) return detail.name;
    if (fallbackTag != null && fallbackTag.isNotEmpty) return fallbackTag;
    return 'تمرین';
  }
}

class _OrderBadge extends StatelessWidget {
  const _OrderBadge({required this.index, this.complete = false});

  final int index;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final bg = complete
        ? WorkoutLogColors.successSolid(context).withValues(alpha: 0.14)
        : AppTheme.goldColor.withValues(alpha: 0.12);
    final fg = complete
        ? WorkoutLogColors.successText(context)
        : AppTheme.goldColor;

    return Container(
      width: 26.w,
      height: 26.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w900,
          fontSize: 12.sp,
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.isCollapsed, required this.onTutorial});

  final bool isCollapsed;
  final VoidCallback onTutorial;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'آموزش',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: 30.w, height: 30.w),
          onPressed: onTutorial,
          icon: Icon(
            LucideIcons.circlePlay,
            size: 16.sp,
            color: WorkoutLogColors.mutedText(context),
          ),
        ),
        Icon(
          isCollapsed ? LucideIcons.chevronDown : LucideIcons.chevronUp,
          size: 17.sp,
          color: WorkoutLogColors.mutedText(context),
        ),
        SizedBox(width: 2.w),
      ],
    );
  }
}

class _SetColumnLabels extends StatelessWidget {
  const _SetColumnLabels({required this.style});

  final ExerciseStyle style;

  @override
  Widget build(BuildContext context) {
    Widget label(String value) => Text(
      value,
      textAlign: TextAlign.center,
      style: WorkoutLogTypography.caption(
        context,
        color: WorkoutLogColors.mutedText(context),
        fontWeight: FontWeight.w700,
      ).copyWith(fontSize: 9.5.sp),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 3.h),
        child: Row(
          children: [
            SizedBox(width: 32.w, child: label('ست')),
            SizedBox(width: 8.w),
            if (style == ExerciseStyle.setsReps) ...[
              Expanded(child: label('تکرار')),
              SizedBox(width: 20.w),
              Expanded(child: label('وزنه')),
              SizedBox(width: 6.w),
              SizedBox(width: 40.w, child: label('RPE')),
            ] else ...[
              Expanded(child: label('زمان')),
              SizedBox(width: 6.w),
              SizedBox(width: 40.w, child: label('RPE')),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviousSetsLine extends StatelessWidget {
  const _PreviousSetsLine({this.previousSets});

  final List<PreviousExerciseSet>? previousSets;

  @override
  Widget build(BuildContext context) {
    final sets = previousSets;
    if (sets == null || sets.isEmpty) return const SizedBox.shrink();

    final summary = sets.map((s) => s.summaryLabel).join('  ·  ');
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'قبلی · ',
              style: WorkoutLogTypography.caption(
                context,
                color: WorkoutLogColors.mutedText(context),
                fontWeight: FontWeight.w700,
              ).copyWith(fontSize: 10.5.sp, height: 1.3),
            ),
            TextSpan(
              text: summary,
              style:
                  WorkoutLogTypography.caption(
                    context,
                    color: WorkoutLogColors.mutedText(context),
                  ).copyWith(
                    fontSize: 10.5.sp,
                    height: 1.3,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
