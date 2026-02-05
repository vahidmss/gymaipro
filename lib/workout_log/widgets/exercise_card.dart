import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gymaipro/theme/app_theme.dart';

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
    super.key,
  });
  final WorkoutExercise exercise;
  final Map<int, Exercise> exerciseDetails;
  final Map<String, List<Map<String, TextEditingController>>>
  exerciseControllers;
  final Map<String, List<Map<String, FocusNode>>> exerciseFocusNodes;
  final Map<String, List<bool>> setSavedStatus;
  final Map<String, bool> collapsedExercises;
  final void Function(String) onToggleCollapse;
  final void Function(int) onNavigateToTutorial;
  final void Function(String, int) onSaveSet;

  @override
  Widget build(BuildContext context) {
    if (exercise is NormalExercise) {
      return _buildNormalExerciseCard(exercise as NormalExercise);
    } else if (exercise is SupersetExercise) {
      return _buildSupersetExerciseCard(exercise as SupersetExercise);
    }
    return const SizedBox.shrink();
  }

  Widget _buildNormalExerciseCard(NormalExercise exercise) {
    final exerciseId = exercise.exerciseId.toString();
    final savedStatus = setSavedStatus[exerciseId] ?? [];
    final focusNodes = exerciseFocusNodes[exerciseId] ?? [];
    final exerciseDetails = this.exerciseDetails[exercise.exerciseId];
    final isCollapsed = collapsedExercises[exerciseId] ?? true;

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.darkCardColor,
                      AppTheme.darkCardColor.withValues(alpha: 0.9),
                      AppTheme.veryDarkBackground,
                    ]
                  : [
                      AppTheme.lightCardColor,
                      AppTheme.lightCardColor.withValues(alpha: 0.95),
                      AppTheme.lightSurfaceColor,
                    ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.3),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : AppTheme.lightTextColor.withValues(alpha: 0.1),
                blurRadius: 20.r,
                offset: Offset(0.w, 8.h),
              ),
              BoxShadow(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.15 : 0.1,
                ),
                blurRadius: 10.r,
                offset: Offset(0.w, 4.h),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header - Always visible
              InkWell(
                onTap: () => onToggleCollapse(exerciseId),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  child: Row(
                    children: [
                      // Exercise icon
                      Container(
                        width: 36.w,
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(
                            alpha: isDark ? 0.15 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppTheme.goldColor.withValues(alpha: 0.25),
                            width: 0.8.w,
                          ),
                        ),
                        child: exerciseDetails?.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.network(
                                  exerciseDetails!.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        LucideIcons.dumbbell,
                                        color: AppTheme.goldColor,
                                        size: 16.sp,
                                      ),
                                ),
                              )
                            : Icon(
                                LucideIcons.dumbbell,
                                color: AppTheme.goldColor,
                                size: 16.sp,
                              ),
                      ),
                      SizedBox(width: 10.w),
                      // Exercise info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getExerciseName(
                                exercise.exerciseId,
                                fallbackTag: exercise.tag,
                              ),
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextColor
                                    : AppTheme.lightTextColor,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: AppTheme.fontFamily,
                                letterSpacing: 0.2,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Display exercise note if available
                            if (exercise.note != null &&
                                exercise.note!.isNotEmpty) ...[
                              SizedBox(height: 6.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.amber[700]!.withValues(
                                          alpha: 0.12,
                                        )
                                      : Colors.amber[800]!.withValues(
                                          alpha: 0.15,
                                        ),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.amber[700]!.withValues(
                                            alpha: 0.3,
                                          )
                                        : Colors.amber[800]!.withValues(
                                            alpha: 0.5,
                                          ),
                                    width: 0.5.w,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.messageCircle,
                                      color: isDark
                                          ? Colors.amber[700]
                                          : Colors.amber[900],
                                      size: 11.sp,
                                    ),
                                    SizedBox(width: 5.w),
                                    Expanded(
                                      child: Text(
                                        exercise.note!,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.amber[700]
                                              : Colors.black,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppTheme.fontFamily,
                                          fontStyle: FontStyle.italic,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // Tutorial button - مینیمال و شیک
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.r),
                          onTap: () =>
                              onNavigateToTutorial(exercise.exerciseId),
                          child: Container(
                            width: 32.w,
                            height: 32.h,
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: Colors.blue[500]!.withValues(
                                alpha: isDark ? 0.2 : 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.blue[400]!.withValues(alpha: 0.4),
                                width: 1.w,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.playCircle,
                              color: Colors.blue[600],
                              size: 16.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // Collapse/Expand icon - مینیمال و شیک
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.r),
                          onTap: () => onToggleCollapse(exerciseId),
                          child: Container(
                            width: 32.w,
                            height: 32.h,
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withValues(
                                alpha: isDark ? 0.12 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.25,
                                ),
                                width: 1.w,
                              ),
                            ),
                            child: Icon(
                              isCollapsed
                                  ? LucideIcons.chevronDown
                                  : LucideIcons.chevronUp,
                              color: AppTheme.goldColor,
                              size: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Sets - Collapsible با انیمیشن
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : AppTheme.lightSurfaceColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12.r),
                    ),
                  ),
                  child: Column(
                    children: List.generate(exercise.sets.length, (setIndex) {
                      final defaultReps =
                          exercise.style == ExerciseStyle.setsReps
                          ? exercise.sets[setIndex].reps
                          : null;
                      final defaultTimeSeconds =
                          exercise.style == ExerciseStyle.setsTime
                          ? exercise.sets[setIndex].timeSeconds
                          : null;
                      return _buildCompactSetRow(
                        exerciseId,
                        setIndex,
                        exercise.style,
                        savedStatus.length > setIndex
                            ? savedStatus[setIndex]
                            : false,
                        focusNodes: focusNodes.length > setIndex
                            ? focusNodes[setIndex]
                            : null,
                        isLastSet: setIndex == exercise.sets.length - 1,
                        defaultReps: defaultReps,
                        defaultTimeSeconds: defaultTimeSeconds,
                      );
                    }),
                  ),
                ),
                crossFadeState: isCollapsed
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 300),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupersetExerciseCard(SupersetExercise exercise) {
    final exerciseId = exercise.id;
    final isCollapsed = collapsedExercises[exerciseId] ?? true;
    final totalSets = exercise.exercises.first.sets.length;
    final supersetTag = exercise.tag; // tag برای کل superset

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.15),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : AppTheme.lightTextColor.withValues(alpha: 0.05),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header - Always visible
              InkWell(
                onTap: () => onToggleCollapse(exerciseId),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  child: Row(
                    children: [
                      // Superset icon
                      Container(
                        width: 36.w,
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(
                            alpha: isDark ? 0.15 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppTheme.goldColor.withValues(alpha: 0.25),
                            width: 0.8.w,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.zap,
                          color: AppTheme.goldColor,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      // Superset info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldColor.withValues(
                                      alpha: isDark ? 0.15 : 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: AppTheme.goldColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 0.5.w,
                                    ),
                                  ),
                                  child: Text(
                                    'سوپرست',
                                    style: TextStyle(
                                      color: AppTheme.goldColor,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: AppTheme.fontFamily,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 4.h,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey[800]!.withValues(
                                            alpha: 0.3,
                                          )
                                        : AppTheme.lightDividerColor.withValues(
                                            alpha: 0.25,
                                          ),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.grey.withValues(alpha: 0.15)
                                          : AppTheme.lightDividerColor
                                                .withValues(alpha: 0.5),
                                      width: 0.5.w,
                                    ),
                                  ),
                                  child: Text(
                                    '${exercise.exercises.length} تمرین • $totalSets ست',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[300]
                                          : AppTheme.lightTextSecondary,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: AppTheme.fontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Display superset exercise note if available
                            if (exercise.note != null &&
                                exercise.note!.isNotEmpty) ...[
                              SizedBox(height: 6.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.amber[700]!.withValues(
                                          alpha: 0.12,
                                        )
                                      : Colors.amber[800]!.withValues(
                                          alpha: 0.15,
                                        ),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.amber[700]!.withValues(
                                            alpha: 0.3,
                                          )
                                        : Colors.amber[800]!.withValues(
                                            alpha: 0.5,
                                          ),
                                    width: 0.5.w,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.messageCircle,
                                      color: isDark
                                          ? Colors.amber[700]
                                          : Colors.amber[900],
                                      size: 11.sp,
                                    ),
                                    SizedBox(width: 5.w),
                                    Expanded(
                                      child: Text(
                                        exercise.note!,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.amber[700]
                                              : Colors.black,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppTheme.fontFamily,
                                          fontStyle: FontStyle.italic,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // Collapse/Expand icon - مینیمال و شیک
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.r),
                          onTap: () => onToggleCollapse(exerciseId),
                          child: Container(
                            width: 32.w,
                            height: 32.h,
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withValues(
                                alpha: isDark ? 0.12 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.25,
                                ),
                                width: 1.w,
                              ),
                            ),
                            child: Icon(
                              isCollapsed
                                  ? LucideIcons.chevronDown
                                  : LucideIcons.chevronUp,
                              color: AppTheme.goldColor,
                              size: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Exercises - Collapsible با انیمیشن
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : AppTheme.lightSurfaceColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12.r),
                    ),
                  ),
                  child: Column(
                    children: exercise.exercises.map((item) {
                      final itemId = '${exercise.id}_${item.exerciseId}';
                      final savedStatus = this.setSavedStatus[itemId] ?? [];
                      final focusNodes = this.exerciseFocusNodes[itemId] ?? [];
                      final itemExerciseDetails =
                          this.exerciseDetails[item.exerciseId];

                      return Column(
                        children: [
                          // Exercise header
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.2)
                                  : AppTheme.lightCardColor.withValues(
                                      alpha: 0.4,
                                    ),
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark
                                      ? Colors.grey.withValues(alpha: 0.1)
                                      : AppTheme.lightDividerColor.withValues(
                                          alpha: 0.35,
                                        ),
                                  width: 0.5.w,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28.w,
                                  height: 28.h,
                                  decoration: BoxDecoration(
                                    color: Colors.amber[700]!.withValues(
                                      alpha: isDark ? 0.18 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: Colors.amber[700]!.withValues(
                                        alpha: 0.25,
                                      ),
                                      width: 0.5.w,
                                    ),
                                  ),
                                  child: itemExerciseDetails?.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6.r,
                                          ),
                                          child: Image.network(
                                            itemExerciseDetails!.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      LucideIcons.dumbbell,
                                                      color: Colors.amber[700],
                                                      size: 12.sp,
                                                    ),
                                          ),
                                        )
                                      : Icon(
                                          LucideIcons.dumbbell,
                                          color: Colors.amber[700],
                                          size: 12.sp,
                                        ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    _getExerciseName(
                                      item.exerciseId,
                                      fallbackTag: supersetTag,
                                    ),
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextColor
                                          : AppTheme.lightTextColor,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: AppTheme.fontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Sets for this exercise
                          ...List.generate(item.sets.length, (setIndex) {
                            final defaultReps =
                                item.style == ExerciseStyle.setsReps
                                ? item.sets[setIndex].reps
                                : null;
                            final defaultTimeSeconds =
                                item.style == ExerciseStyle.setsTime
                                ? item.sets[setIndex].timeSeconds
                                : null;
                            return _buildCompactSetRow(
                              itemId,
                              setIndex,
                              item.style,
                              savedStatus.length > setIndex
                                  ? savedStatus[setIndex]
                                  : false,
                              focusNodes: focusNodes.length > setIndex
                                  ? focusNodes[setIndex]
                                  : null,
                              isLastSet: setIndex == item.sets.length - 1,
                              defaultReps: defaultReps,
                              defaultTimeSeconds: defaultTimeSeconds,
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                crossFadeState: isCollapsed
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 300),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactSetRow(
    String exerciseId,
    int setIndex,
    ExerciseStyle style,
    bool isSaved, {
    Map<String, FocusNode>? focusNodes,
    bool isLastSet = false,
    int? defaultReps,
    int? defaultTimeSeconds,
  }) {
    final controllers = exerciseControllers[exerciseId];
    if (controllers == null || controllers.length <= setIndex) {
      return const SizedBox.shrink();
    }

    final setControllers = controllers[setIndex];

    // تعیین هینت عددی: اول از مقدار ذخیره شده، سپس از خود برنامه
    final String savedReps = setControllers['reps']?.text.trim() ?? '';
    final String savedTime = setControllers['time']?.text.trim() ?? '';
    final String savedWeight = setControllers['weight']?.text.trim() ?? '';

    final String numericHint = style == ExerciseStyle.setsReps
        ? (savedReps.isNotEmpty ? savedReps : (defaultReps?.toString() ?? ''))
        : (savedTime.isNotEmpty
              ? savedTime
              : (defaultTimeSeconds?.toString() ?? ''));

    final String weightHint = savedWeight.isNotEmpty ? savedWeight : '0';

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(bottom: 3.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isSaved
                ? AppTheme.successColor.withValues(alpha: isDark ? 0.15 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSaved
                  ? AppTheme.successColor.withValues(alpha: 0.3)
                  : (isDark
                        ? Colors.grey.withValues(alpha: 0.12)
                        : AppTheme.lightDividerColor.withValues(alpha: 0.4)),
              width: isSaved ? 1.w : 0.5.w,
            ),
          ),
          child: Row(
            children: [
              // Set number badge - مینیمال
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: isSaved
                      ? AppTheme.successColor
                      : AppTheme.goldColor.withValues(
                          alpha: isDark ? 0.2 : 0.15,
                        ),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSaved
                        ? AppTheme.successColor.withValues(alpha: 0.6)
                        : AppTheme.goldColor.withValues(alpha: 0.3),
                    width: 1.w,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isSaved
                        ? Icon(
                            Icons.check_rounded,
                            key: const ValueKey('check'),
                            color: Colors.white,
                            size: 16.sp,
                          )
                        : Text(
                            '${setIndex + 1}',
                            key: ValueKey('number-$setIndex'),
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.goldColor
                                  : AppTheme.darkGold,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              // Reps/Time input (FIRST)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style == ExerciseStyle.setsReps ? 'تکرار' : 'زمان',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey[400]
                            : AppTheme.lightTextSecondary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    TextField(
                      controller: style == ExerciseStyle.setsReps
                          ? setControllers['reps']
                          : setControllers['time'],
                      focusNode: focusNodes != null
                          ? (style == ExerciseStyle.setsReps
                                ? focusNodes['reps']
                                : focusNodes['time'])
                          : null,
                      keyboardType: const TextInputType.numberWithOptions(),
                      textInputAction: style == ExerciseStyle.setsReps
                          ? TextInputAction.next
                          : (isLastSet
                                ? TextInputAction.done
                                : TextInputAction.next),
                      enableSuggestions: false,
                      autocorrect: false,
                      onChanged: (value) {
                        // Auto-save will be triggered by listener in parent
                      },
                      onSubmitted: (value) {
                        // Move to next field or close keyboard
                        if (style == ExerciseStyle.setsReps) {
                          // Move to weight field
                          focusNodes?['weight']?.requestFocus();
                        } else {
                          // For time-based exercises, move to next set or close keyboard
                          if (isLastSet) {
                            focusNodes?['time']?.unfocus();
                          } else {
                            // Find next set's time focus node
                            _moveToNextSet(exerciseId, setIndex, 'time');
                          }
                        }
                        onSaveSet(exerciseId, setIndex);
                      },
                      onEditingComplete: () {
                        // Save when user finishes editing
                        onSaveSet(exerciseId, setIndex);
                      },
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextColor
                            : AppTheme.lightTextColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      decoration: InputDecoration(
                        hintText: numericHint.isNotEmpty ? numericHint : '0',
                        hintStyle: TextStyle(
                          color: (isSaved && numericHint.isNotEmpty)
                              ? (isDark
                                    ? AppTheme.darkTextColor
                                    : AppTheme.lightTextColor)
                              : (isDark
                                    ? Colors.grey[500]
                                    : AppTheme.lightTextSecondary.withValues(
                                        alpha: 0.6,
                                      )),
                          fontSize: 12.sp,
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: (isSaved && numericHint.isNotEmpty)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        suffixText: style == ExerciseStyle.setsTime
                            ? 'ثانیه'
                            : null,
                        suffixStyle: TextStyle(
                          color: isDark
                              ? Colors.grey[400]
                              : AppTheme.lightTextSecondary,
                          fontSize: 10.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : AppTheme.lightCardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey.withValues(alpha: 0.15)
                                : AppTheme.lightDividerColor,
                            width: 0.8.w,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: AppTheme.goldColor,
                            width: 1.5.w,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              if (style == ExerciseStyle.setsReps) ...[
                SizedBox(width: 8.w),
                // Weight input (SECOND)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وزن',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey[400]
                              : AppTheme.lightTextSecondary,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      TextField(
                        controller: setControllers['weight'],
                        focusNode: focusNodes?['weight'],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: isLastSet
                            ? TextInputAction.done
                            : TextInputAction.next,
                        enableSuggestions: false,
                        autocorrect: false,
                        onChanged: (value) {
                          // Auto-save will be triggered by listener in parent
                        },
                        onSubmitted: (value) {
                          // Move to next set's reps field or close keyboard
                          if (isLastSet) {
                            focusNodes?['weight']?.unfocus();
                          } else {
                            // Find next set's reps focus node
                            _moveToNextSet(exerciseId, setIndex, 'reps');
                          }
                          onSaveSet(exerciseId, setIndex);
                        },
                        onEditingComplete: () {
                          // Save when user finishes editing
                          onSaveSet(exerciseId, setIndex);
                        },
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9\\.]'),
                          ),
                        ],
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextColor
                              : AppTheme.lightTextColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        decoration: InputDecoration(
                          hintText: weightHint,
                          hintStyle: TextStyle(
                            color: (isSaved && weightHint != '0')
                                ? (isDark
                                      ? AppTheme.darkTextColor
                                      : AppTheme.lightTextColor)
                                : (isDark
                                      ? Colors.grey[500]
                                      : AppTheme.lightTextSecondary.withValues(
                                          alpha: 0.6,
                                        )),
                            fontSize: 12.sp,
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: (isSaved && weightHint != '0')
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          suffixText: 'کیلو',
                          suffixStyle: TextStyle(
                            color: isDark
                                ? Colors.grey[400]
                                : AppTheme.lightTextSecondary,
                            fontSize: 10.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : AppTheme.lightCardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.withValues(alpha: 0.15)
                                  : AppTheme.lightDividerColor,
                              width: 0.8.w,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppTheme.goldColor,
                              width: 1.5.w,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getExerciseName(int exerciseId, {String? fallbackTag}) {
    final exerciseDetail = exerciseDetails[exerciseId];
    if (exerciseDetail != null) {
      return exerciseDetail.name;
    }
    // اگر exerciseDetail موجود نباشد، از tag استفاده کن
    if (fallbackTag != null && fallbackTag.isNotEmpty) {
      return fallbackTag;
    }
    return 'تمرین';
  }

  void _moveToNextSet(
    String exerciseId,
    int currentSetIndex,
    String fieldType,
  ) {
    // Find the next set's focus node
    final controllers = exerciseControllers[exerciseId];
    if (controllers == null || currentSetIndex >= controllers.length - 1) {
      return;
    }

    final nextSetIndex = currentSetIndex + 1;
    final nextFocusNodes = exerciseFocusNodes[exerciseId];
    if (nextFocusNodes != null && nextSetIndex < nextFocusNodes.length) {
      final nextSetFocusNodes = nextFocusNodes[nextSetIndex];
      nextSetFocusNodes[fieldType]?.requestFocus();
    }
  }
}
