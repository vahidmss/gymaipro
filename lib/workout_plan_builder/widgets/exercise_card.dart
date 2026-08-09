import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/widgets/exercise_note_button.dart';
import 'package:gymaipro/workout_plan_builder/widgets/set_scheme_editor.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    required this.exercise,
    required this.exerciseDetails,
    required this.index,
    required this.totalExercises,
    required this.expanded,
    required this.onToggleExpand,
    required this.onDelete,
    required this.onNoteChanged,
    required this.onStyleChanged,
    required this.onSetsChanged,
    required this.onRepsChanged,
    required this.onSetRepsChanged,
    required this.onTimeChanged,
    required this.onSetTimeChanged,
    required this.onRestChanged,
    required this.onSupersetStyleChanged,
    required this.onSupersetSetsChanged,
    required this.onSupersetRepsChanged,
    required this.onSupersetSetRepsChanged,
    required this.onSupersetTimeChanged,
    required this.onSupersetSetTimeChanged,
    required this.onSupersetRestChanged,
    required this.allExercises,
    super.key,
    this.onMoveUp,
    this.onMoveDown,
  });
  final WorkoutExercise exercise;
  final Exercise exerciseDetails;
  final int index;
  final int totalExercises;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final void Function(String?) onNoteChanged;
  final void Function(ExerciseStyle) onStyleChanged;
  final void Function(int) onSetsChanged;
  final void Function(int) onRepsChanged;
  final void Function(int setIndex, int reps) onSetRepsChanged;
  final void Function(int) onTimeChanged;
  final void Function(int setIndex, int time) onSetTimeChanged;
  final void Function(int?) onRestChanged;
  final void Function(int, ExerciseStyle) onSupersetStyleChanged;
  final void Function(int, int) onSupersetSetsChanged;
  final void Function(int, int) onSupersetRepsChanged;
  final void Function(int itemIndex, int setIndex, int reps)
  onSupersetSetRepsChanged;
  final void Function(int, int) onSupersetTimeChanged;
  final void Function(int itemIndex, int setIndex, int time)
  onSupersetSetTimeChanged;
  final void Function(int?) onSupersetRestChanged;
  final List<Exercise> allExercises;

  String? get _noteText {
    if (exercise is NormalExercise) return (exercise as NormalExercise).note;
    if (exercise is SupersetExercise) {
      return (exercise as SupersetExercise).note;
    }
    return null;
  }

  String get _summaryLine {
    if (exercise is NormalExercise) {
      final e = exercise as NormalExercise;
      final parts = <String>[
        if (e.tag.isNotEmpty) e.tag,
        formatSetScheme(e.sets, e.style),
        if (e.restSeconds != null) '${e.restSeconds}ث',
      ];
      return parts.where((p) => p.isNotEmpty).join(' · ');
    }
    if (exercise is SupersetExercise) {
      final e = exercise as SupersetExercise;
      final n = e.exercises.length;
      final label = n >= 3 ? 'تریست' : 'سوپرست';
      final first = e.exercises.isNotEmpty ? e.exercises.first : null;
      final scheme = first == null
          ? ''
          : formatSetScheme(first.sets, first.style);
      return [label, scheme, if (e.restSeconds != null) '${e.restSeconds}ث']
          .where((p) => p.isNotEmpty)
          .join(' · ');
    }
    return exercise.tag;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: expanded
              ? AppTheme.goldColor.withValues(alpha: 0.55)
              : AppTheme.goldColor.withValues(alpha: isDark ? 0.18 : 0.22),
          width: expanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: expanded ? 10.r : 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleExpand,
              borderRadius: BorderRadius.circular(14.r),
              child: Padding(
                padding: EdgeInsets.fromLTRB(10.w, 10.h, 6.w, 10.h),
                child: Row(
                  children: [
                    if (totalExercises > 1 && expanded) ...[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onMoveUp != null)
                            _TinyIcon(
                              icon: LucideIcons.chevronUp,
                              onTap: onMoveUp!,
                            ),
                          if (onMoveDown != null)
                            _TinyIcon(
                              icon: LucideIcons.chevronDown,
                              onTap: onMoveDown!,
                            ),
                        ],
                      ),
                      SizedBox(width: 4.w),
                    ],
                    _IndexBadge(index: index + 1),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseDetails.name,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.goldColor
                                  : context.textColor,
                              fontSize: 13.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_summaryLine.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: Text(
                                _summaryLine,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppTheme.goldColor.withValues(
                                          alpha: 0.7,
                                        )
                                      : context.textColor.withValues(
                                          alpha: 0.55,
                                        ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 18.sp,
                      color: AppTheme.goldColor.withValues(alpha: 0.8),
                    ),
                    SizedBox(width: 4.w),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (exercise is NormalExercise ||
                          exercise is SupersetExercise)
                        ExerciseNoteButton(
                          note: _noteText,
                          onNoteChanged: onNoteChanged,
                          color: AppTheme.goldColor,
                          iconSize: 16,
                        ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 14.sp,
                          color: const Color(0xFFB71C1C).withValues(alpha: 0.7),
                        ),
                        label: Text(
                          'حذف',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.sp,
                            color: const Color(
                              0xFFB71C1C,
                            ).withValues(alpha: 0.75),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          visualDensity: VisualDensity.compact,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  if (_noteText != null && _noteText!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Text(
                        _noteText!,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.8)
                              : context.textColor.withValues(alpha: 0.6),
                          fontSize: 11.sp,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (exercise is NormalExercise)
                    _buildNormal(context, exercise as NormalExercise),
                  if (exercise is SupersetExercise)
                    _buildSuperset(context, exercise as SupersetExercise),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNormal(BuildContext context, NormalExercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExerciseStyleToggle(style: exercise.style, onChanged: onStyleChanged),
        SizedBox(height: 8.h),
        SetSchemeEditor(
          sets: exercise.sets,
          style: exercise.style,
          restSeconds: exercise.restSeconds,
          onSetsChanged: onSetsChanged,
          onSetValueChanged: (setIndex, value) {
            if (exercise.style == ExerciseStyle.setsReps) {
              onSetRepsChanged(setIndex, value);
            } else {
              onSetTimeChanged(setIndex, value);
            }
          },
          onApplyAllValues: (value) {
            if (exercise.style == ExerciseStyle.setsReps) {
              onRepsChanged(value);
            } else {
              onTimeChanged(value);
            }
          },
          onRestChanged: onRestChanged,
        ),
      ],
    );
  }

  Widget _buildSuperset(BuildContext context, SupersetExercise exercise) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.18 : 0.12,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                exercise.exercises.length >= 3 ? 'تریست' : 'سوپرست',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.goldColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 5.w,
          runSpacing: 5.h,
          children: [
            for (final sec in const [60, 90, 120, 180])
              _MiniRestChip(
                label: '$secث',
                selected: exercise.restSeconds == sec,
                onTap: () => onSupersetRestChanged(
                  exercise.restSeconds == sec ? null : sec,
                ),
              ),
            _MiniRestChip(
              label: 'پیش‌فرض',
              selected: exercise.restSeconds == null,
              onTap: () => onSupersetRestChanged(null),
            ),
          ],
        ),
        for (var i = 0; i < exercise.exercises.length; i++) ...[
          Divider(
            height: 16.h,
            color: AppTheme.goldColor.withValues(alpha: 0.12),
          ),
          _buildSupersetItem(context, exercise, i),
        ],
      ],
    );
  }

  Widget _buildSupersetItem(
    BuildContext context,
    SupersetExercise block,
    int i,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = block.exercises[i];
    final exDetails = allExercises.firstWhere(
      (e) => e.id == item.exerciseId,
      orElse: () => Exercise(
        id: 0,
        title: '',
        name: 'حرکت ${i + 1}',
        mainMuscle: '',
        secondaryMuscles: '',
        tips: [],
        videoUrl: '',
        imageUrl: '',
        otherNames: [],
        content: '',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exDetails.name,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.goldColor : context.textColor,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 6.h),
        ExerciseStyleToggle(
          style: item.style,
          onChanged: (style) => onSupersetStyleChanged(i, style),
        ),
        SizedBox(height: 6.h),
        SetSchemeEditor(
          sets: item.sets,
          style: item.style,
          onSetsChanged: (sets) => onSupersetSetsChanged(i, sets),
          onSetValueChanged: (setIndex, value) {
            if (item.style == ExerciseStyle.setsReps) {
              onSupersetSetRepsChanged(i, setIndex, value);
            } else {
              onSupersetSetTimeChanged(i, setIndex, value);
            }
          },
          onApplyAllValues: (value) {
            if (item.style == ExerciseStyle.setsReps) {
              onSupersetRepsChanged(i, value);
            } else {
              onSupersetTimeChanged(i, value);
            }
          },
        ),
      ],
    );
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 28.w,
      height: 28.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 12.sp,
          color: AppTheme.goldColor,
        ),
      ),
    );
  }
}

class _TinyIcon extends StatelessWidget {
  const _TinyIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Icon(icon, size: 14.sp, color: AppTheme.goldColor),
      ),
    );
  }
}

class _MiniRestChip extends StatelessWidget {
  const _MiniRestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? AppTheme.goldColor
          : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.lightButtonBackground),
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppTheme.onGoldColor
                  : (isDark
                        ? AppTheme.goldColor.withValues(alpha: 0.85)
                        : context.textColor.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ),
    );
  }
}
