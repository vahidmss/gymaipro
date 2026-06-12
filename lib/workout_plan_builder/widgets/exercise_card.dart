import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/widgets/exercise_note_button.dart';
import 'package:gymaipro/workout_plan_builder/widgets/exercise_stepper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    required this.exercise,
    required this.exerciseDetails,
    required this.index,
    required this.totalExercises,
    required this.onDelete,
    required this.onNoteChanged,
    required this.onStyleChanged,
    required this.onSetsChanged,
    required this.onRepsChanged,
    required this.onTimeChanged,
    required this.onWeightChanged,
    required this.onSupersetStyleChanged,
    required this.onSupersetSetsChanged,
    required this.onSupersetRepsChanged,
    required this.onSupersetTimeChanged,
    required this.allExercises,
    super.key,
    this.onMoveUp,
    this.onMoveDown,
  });
  final WorkoutExercise exercise;
  final Exercise exerciseDetails;
  final int index;
  final int totalExercises;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final void Function(String?) onNoteChanged;
  final void Function(ExerciseStyle) onStyleChanged;
  final void Function(int) onSetsChanged;
  final void Function(int) onRepsChanged;
  final void Function(int) onTimeChanged;
  final void Function(double) onWeightChanged;
  final void Function(int, ExerciseStyle) onSupersetStyleChanged;
  final void Function(int, int) onSupersetSetsChanged;
  final void Function(int, int) onSupersetRepsChanged;
  final void Function(int, int) onSupersetTimeChanged;
  final List<Exercise> allExercises;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.goldGradientColors[0].withValues(alpha: 0.15),
                  context.cardColor,
                  context.goldGradientColors[1].withValues(alpha: 0.1),
                ],
              ),
        color: isDark ? context.backgroundColor : null,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.35),
            blurRadius: 16.r,
            offset: Offset(0.w, 6.h),
            spreadRadius: 1.r,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : AppTheme.lightTextColor.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0 && index < totalExercises - 1) ...[
                      GestureDetector(
                        onTap: onMoveUp,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor.withValues(
                              alpha: isDark ? 0.2 : 0.15,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(
                            LucideIcons.chevronUp,
                            color: AppTheme.goldColor,
                            size: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: onMoveDown,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor.withValues(
                              alpha: isDark ? 0.2 : 0.15,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(
                            LucideIcons.chevronDown,
                            color: AppTheme.goldColor,
                            size: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    if (index == 0 && totalExercises > 1) ...[
                      GestureDetector(
                        onTap: onMoveDown,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor.withValues(
                              alpha: isDark ? 0.2 : 0.15,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(
                            LucideIcons.chevronDown,
                            color: AppTheme.goldColor,
                            size: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    if (index == totalExercises - 1 && totalExercises > 1) ...[
                      GestureDetector(
                        onTap: onMoveUp,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor.withValues(
                              alpha: isDark ? 0.2 : 0.15,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(
                            LucideIcons.chevronUp,
                            color: AppTheme.goldColor,
                            size: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                  ],
                ),
                // Exercise image or icon
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.2 : 0.15,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: exerciseDetails.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            exerciseDetails.imageUrl,
                            width: 36.w,
                            height: 36.h,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              LucideIcons.dumbbell,
                              color: AppTheme.goldColor,
                              size: 20.sp,
                            ),
                          ),
                        )
                      : Icon(
                          LucideIcons.dumbbell,
                          color: AppTheme.goldColor,
                          size: 20.sp,
                        ),
                ),
                SizedBox(width: 12.w),
                // Exercise name
                Expanded(
                  child: Text(
                    exerciseDetails.name,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.goldColor : context.textColor,
                      fontSize: 13.sp,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                SizedBox(width: 8.w),
                // Note button
                if (exercise is NormalExercise)
                  ExerciseNoteButton(
                    note: (exercise as NormalExercise).note,
                    onNoteChanged: onNoteChanged,
                    iconSize: 18,
                    color: AppTheme.goldColor,
                  ),
                if (exercise is SupersetExercise)
                  ExerciseNoteButton(
                    note: (exercise as SupersetExercise).note,
                    onNoteChanged: onNoteChanged,
                    iconSize: 18,
                    color: AppTheme.goldColor,
                  ),
                SizedBox(width: 4.w),
                // Delete button
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: isDark ? 0.4 : 0.3),
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.trash2,
                      color: Colors.red[600],
                      size: 18.sp,
                    ),
                    onPressed: onDelete,
                    tooltip: 'حذف حرکت',
                    padding: EdgeInsets.all(8.w),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
            // Note display
            if (exercise is NormalExercise &&
                (exercise as NormalExercise).note != null &&
                (exercise as NormalExercise).note!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.15 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(
                        alpha: isDark ? 0.3 : 0.2,
                      ),
                    ),
                  ),
                  child: Text(
                    (exercise as NormalExercise).note!.length > 100
                        ? '${(exercise as NormalExercise).note!.substring(0, 100)}...'
                        : (exercise as NormalExercise).note!,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark
                          ? AppTheme.goldColor.withValues(alpha: 0.9)
                          : context.textColor.withValues(alpha: 0.8),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (exercise is SupersetExercise &&
                (exercise as SupersetExercise).note != null &&
                (exercise as SupersetExercise).note!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.15 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(
                        alpha: isDark ? 0.3 : 0.2,
                      ),
                    ),
                  ),
                  child: Text(
                    (exercise as SupersetExercise).note!.length > 100
                        ? '${(exercise as SupersetExercise).note!.substring(0, 100)}...'
                        : (exercise as SupersetExercise).note!,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark
                          ? AppTheme.goldColor.withValues(alpha: 0.9)
                          : context.textColor.withValues(alpha: 0.8),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            // Exercise configuration
            if (exercise is NormalExercise)
              _buildNormalExerciseConfig(context, exercise as NormalExercise),
            if (exercise is SupersetExercise)
              _buildSupersetExerciseConfig(
                context,
                exercise as SupersetExercise,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalExerciseConfig(
    BuildContext context,
    NormalExercise exercise,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCardColor
              : context.cardColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'نوع حرکت:',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark ? AppTheme.goldColor : context.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(
                        alpha: isDark ? 0.2 : 0.15,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(
                          alpha: isDark ? 0.4 : 0.3,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ChoiceChip(
                          key: ValueKey(
                            'sets-reps-${exercise.id}-${exercise.style}',
                          ),
                          avatar: Icon(
                            LucideIcons.repeat,
                            size: 14.sp,
                            color: exercise.style == ExerciseStyle.setsReps
                                ? (isDark ? AppTheme.goldColor : Colors.black)
                                : AppTheme.goldColor.withValues(alpha: 0.7),
                          ),
                          label: Text(
                            'ست-تکرار',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                            ),
                          ),
                          selected: exercise.style == ExerciseStyle.setsReps,
                          onSelected: (selected) {
                            if (selected &&
                                exercise.style != ExerciseStyle.setsReps) {
                              onStyleChanged(ExerciseStyle.setsReps);
                            }
                          },
                          selectedColor: AppTheme.goldColor,
                          backgroundColor: Colors.transparent,
                          labelStyle: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: exercise.style == ExerciseStyle.setsReps
                                ? (isDark ? Colors.black : Colors.black)
                                : (isDark
                                      ? AppTheme.goldColor
                                      : context.textColor),
                            fontWeight: exercise.style == ExerciseStyle.setsReps
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                        ),
                        SizedBox(width: 4.w),
                        ChoiceChip(
                          key: ValueKey(
                            'sets-time-${exercise.id}-${exercise.style}',
                          ),
                          avatar: Icon(
                            LucideIcons.timer,
                            size: 14.sp,
                            color: exercise.style == ExerciseStyle.setsTime
                                ? (isDark ? AppTheme.goldColor : Colors.black)
                                : AppTheme.goldColor.withValues(alpha: 0.7),
                          ),
                          label: Text(
                            'ست-زمان',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                            ),
                          ),
                          selected: exercise.style == ExerciseStyle.setsTime,
                          onSelected: (selected) {
                            if (selected &&
                                exercise.style != ExerciseStyle.setsTime) {
                              onStyleChanged(ExerciseStyle.setsTime);
                            }
                          },
                          selectedColor: AppTheme.goldColor,
                          backgroundColor: Colors.transparent,
                          labelStyle: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: exercise.style == ExerciseStyle.setsTime
                                ? (isDark ? Colors.black : Colors.black)
                                : (isDark
                                      ? AppTheme.goldColor
                                      : context.textColor),
                            fontWeight: exercise.style == ExerciseStyle.setsTime
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ست:',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isDark
                                  ? AppTheme.goldColor
                                  : context.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.sp,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          ExerciseStepper(
                            value: exercise.sets.length,
                            min: 1,
                            onChanged: onSetsChanged,
                            small: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (exercise.style == ExerciseStyle.setsReps) ...[
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تکرار:',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? AppTheme.goldColor
                                    : context.textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.sp,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            ExerciseStepper(
                              value: exercise.sets.isNotEmpty
                                  ? (exercise.sets[0].reps ?? 10)
                                  : 10,
                              min: 1,
                              onChanged: onRepsChanged,
                              small: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'زمان:',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? AppTheme.goldColor
                                    : context.textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.sp,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            ExerciseStepper(
                              value: exercise.sets.isNotEmpty
                                  ? (exercise.sets[0].timeSeconds ?? 30)
                                  : 30,
                              min: 1,
                              onChanged: onTimeChanged,
                              small: true,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'ثانیه',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? AppTheme.goldColor
                                    : context.textColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupersetExerciseConfig(
    BuildContext context,
    SupersetExercise exercise,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      key: UniqueKey(),
      padding: EdgeInsets.only(top: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCardColor
              : context.cardColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.2 : 0.15,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.4 : 0.3,
                    ),
                  ),
                ),
                child: Text(
                  'سوپرست',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              for (int i = 0; i < exercise.exercises.length; i++) ...[
                Builder(
                  builder: (context) {
                    final supersetItem = exercise.exercises[i];
                    final exDetails = allExercises.firstWhere(
                      (e) => e.id == supersetItem.exerciseId,
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
                    final itemIsDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (exDetails.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6.r),
                                child: Image.network(
                                  exDetails.imageUrl,
                                  width: 28.w,
                                  height: 28.h,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    LucideIcons.dumbbell,
                                    color: AppTheme.goldColor,
                                    size: 20.sp,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                LucideIcons.dumbbell,
                                color: AppTheme.goldColor,
                                size: 20.sp,
                              ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                exDetails.name,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w600,
                                  color: itemIsDark
                                      ? AppTheme.goldColor
                                      : context.textColor,
                                  fontSize: 12.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        // Individual style selection for each exercise
                        Row(
                          children: [
                            Text(
                              'نوع حرکت:',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: itemIsDark
                                    ? AppTheme.goldColor
                                    : context.textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.goldColor.withValues(
                                  alpha: itemIsDark ? 0.2 : 0.15,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppTheme.goldColor.withValues(
                                    alpha: itemIsDark ? 0.4 : 0.3,
                                  ),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 2.h,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ChoiceChip(
                                    key: ValueKey(
                                      'sets-reps-${supersetItem.exerciseId}-${supersetItem.style}',
                                    ),
                                    avatar: Icon(
                                      LucideIcons.repeat,
                                      size: 14.sp,
                                      color:
                                          supersetItem.style ==
                                              ExerciseStyle.setsReps
                                          ? (itemIsDark
                                                ? AppTheme.goldColor
                                                : Colors.black)
                                          : AppTheme.goldColor.withValues(
                                              alpha: 0.7,
                                            ),
                                    ),
                                    label: Text(
                                      'ست-تکرار',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                    selected:
                                        supersetItem.style ==
                                        ExerciseStyle.setsReps,
                                    onSelected: (selected) {
                                      if (selected &&
                                          supersetItem.style !=
                                              ExerciseStyle.setsReps) {
                                        onSupersetStyleChanged(
                                          i,
                                          ExerciseStyle.setsReps,
                                        );
                                      }
                                    },
                                    selectedColor: AppTheme.goldColor,
                                    backgroundColor: Colors.transparent,
                                    labelStyle: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      color:
                                          supersetItem.style ==
                                              ExerciseStyle.setsReps
                                          ? (itemIsDark
                                                ? Colors.black
                                                : Colors.black)
                                          : (itemIsDark
                                                ? AppTheme.goldColor
                                                : context.textColor),
                                      fontWeight:
                                          supersetItem.style ==
                                              ExerciseStyle.setsReps
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    elevation: 0,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  SizedBox(width: 4.w),
                                  ChoiceChip(
                                    key: ValueKey(
                                      'sets-time-${supersetItem.exerciseId}-${supersetItem.style}',
                                    ),
                                    avatar: Icon(
                                      LucideIcons.timer,
                                      size: 14.sp,
                                      color:
                                          supersetItem.style ==
                                              ExerciseStyle.setsTime
                                          ? (itemIsDark
                                                ? AppTheme.goldColor
                                                : Colors.black)
                                          : AppTheme.goldColor.withValues(
                                              alpha: 0.7,
                                            ),
                                    ),
                                    label: Text(
                                      'ست-زمان',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                    selected:
                                        supersetItem.style ==
                                        ExerciseStyle.setsTime,
                                    onSelected: (selected) {
                                      if (selected &&
                                          supersetItem.style !=
                                              ExerciseStyle.setsTime) {
                                        onSupersetStyleChanged(
                                          i,
                                          ExerciseStyle.setsTime,
                                        );
                                      }
                                    },
                                    selectedColor: AppTheme.goldColor,
                                    backgroundColor: Colors.transparent,
                                    labelStyle: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      color:
                                          supersetItem.style ==
                                              ExerciseStyle.setsTime
                                          ? (itemIsDark
                                                ? Colors.black
                                                : Colors.black)
                                          : (itemIsDark
                                                ? AppTheme.goldColor
                                                : context.textColor),
                                      fontWeight:
                                          supersetItem.style ==
                                              ExerciseStyle.setsTime
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    elevation: 0,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'ست:',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      color: itemIsDark
                                          ? AppTheme.goldColor
                                          : context.textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  ExerciseStepper(
                                    value: supersetItem.sets.length,
                                    min: 1,
                                    onChanged: (val) {
                                      onSupersetSetsChanged(i, val);
                                    },
                                    small: true,
                                  ),
                                ],
                              ),
                            ),
                            if (supersetItem.style ==
                                ExerciseStyle.setsReps) ...[
                              Flexible(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تکرار:',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        color: itemIsDark
                                            ? AppTheme.goldColor
                                            : context.textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    ExerciseStepper(
                                      value: supersetItem.sets.isNotEmpty
                                          ? (supersetItem.sets[0].reps ?? 10)
                                          : 10,
                                      min: 1,
                                      onChanged: (val) {
                                        onSupersetRepsChanged(i, val);
                                      },
                                      small: true,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'زمان:',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          color: itemIsDark
                                              ? AppTheme.goldColor
                                              : context.textColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      ExerciseStepper(
                                        value: supersetItem.sets.isNotEmpty
                                            ? (supersetItem
                                                      .sets[0]
                                                      .timeSeconds ??
                                                  30)
                                            : 30,
                                        min: 1,
                                        onChanged: (val) {
                                          onSupersetTimeChanged(i, val);
                                        },
                                        small: true,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'ثانیه',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          color: itemIsDark
                                              ? AppTheme.goldColor
                                              : context.textColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
                ),
                if (i < exercise.exercises.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Divider(
                      color: AppTheme.goldColor.withValues(
                        alpha: isDark ? 0.2 : 0.3,
                      ),
                      height: 1,
                      thickness: 1,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
