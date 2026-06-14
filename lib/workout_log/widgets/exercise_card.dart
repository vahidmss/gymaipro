import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';

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
    this.onDismissKeyboard,
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
  final VoidCallback? onDismissKeyboard;

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
    final isCollapsed = collapsedExercises[exerciseId] ?? false;
    final completedSets = savedStatus.where((s) => s).length;
    final totalSets = exercise.sets.length;

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
                                child: CachedNetworkImage(
                                  imageUrl: exerciseDetails!.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Icon(
                                    LucideIcons.dumbbell,
                                    color: WorkoutLogColors.secondaryText(context),
                                    size: 16.sp,
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    LucideIcons.dumbbell,
                                    color: WorkoutLogColors.iconOnSurface(context),
                                    size: 16.sp,
                                  ),
                                ),
                              )
                            : Icon(
                                LucideIcons.dumbbell,
                                color: WorkoutLogColors.iconOnSurface(context),
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
                              style: WorkoutLogTypography.exerciseTitle(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            _buildSetCompletionIndicator(
                              context,
                              completedSets,
                              totalSets,
                            ),
                            if (exercise.note != null &&
                                exercise.note!.isNotEmpty) ...[
                              SizedBox(height: 6.h),
                              _buildExerciseNote(context, exercise.note!),
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
                              color: WorkoutLogColors.iconOnSurface(context),
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
                    color: WorkoutLogColors.setsPanelBackground(context),
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
    final isCollapsed = collapsedExercises[exerciseId] ?? false;
    final totalSets = exercise.exercises.first.sets.length;
    final supersetTag = exercise.tag;
    int supersetCompletedSets = 0;
    int supersetTotalSets = 0;
    for (final item in exercise.exercises) {
      final itemId = '${exercise.id}_${item.exerciseId}';
      final itemStatus = setSavedStatus[itemId] ?? [];
      supersetCompletedSets += itemStatus.where((s) => s).length;
      supersetTotalSets += item.sets.length;
    }

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
                          color: WorkoutLogColors.iconOnSurface(context),
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
                                    style: WorkoutLogTypography.caption(
                                      context,
                                      color: WorkoutLogColors.labelAccent(
                                        context,
                                      ),
                                      fontWeight: FontWeight.w800,
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
                                    style: WorkoutLogTypography.caption(context),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            _buildSetCompletionIndicator(
                              context,
                              supersetCompletedSets,
                              supersetTotalSets,
                            ),
                            if (exercise.note != null &&
                                exercise.note!.isNotEmpty) ...[
                              SizedBox(height: 6.h),
                              _buildExerciseNote(context, exercise.note!),
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
                              color: WorkoutLogColors.iconOnSurface(context),
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
                    color: WorkoutLogColors.setsPanelBackground(context),
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
                                    color: WorkoutLogColors.accent(context)
                                        .withValues(alpha: isDark ? 0.18 : 0.12),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: WorkoutLogColors.accent(context)
                                          .withValues(alpha: 0.3),
                                      width: 0.5.w,
                                    ),
                                  ),
                                  child: itemExerciseDetails?.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6.r,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                itemExerciseDetails!.imageUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Icon(
                                              LucideIcons.dumbbell,
                                              color: WorkoutLogColors
                                                  .supersetAccent(context)
                                                  .withValues(alpha: 0.55),
                                              size: 12.sp,
                                            ),
                                            errorWidget:
                                                (context, url, error) => Icon(
                                                  LucideIcons.dumbbell,
                                                  color: WorkoutLogColors
                                                      .supersetAccent(context),
                                                  size: 12.sp,
                                                ),
                                          ),
                                        )
                                      : Icon(
                                          LucideIcons.dumbbell,
                                          color: WorkoutLogColors.supersetAccent(
                                            context,
                                          ),
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
                                    style: WorkoutLogTypography.exerciseTitle(
                                      context,
                                    ).copyWith(fontSize: 13.sp),
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(bottom: 3.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isSaved
                ? WorkoutLogColors.successBackground(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSaved
                  ? WorkoutLogColors.successBorder(context)
                  : WorkoutLogColors.inputBorder(context),
              width: isSaved ? 1.2.w : 0.8.w,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: WorkoutLogColors.setBadgeFill(
                    context,
                    isSaved: isSaved,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSaved
                        ? WorkoutLogColors.successBorder(context)
                        : WorkoutLogColors.accent(context).withValues(
                            alpha: 0.35,
                          ),
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
                              color: WorkoutLogColors.setBadgeText(
                                context,
                                isSaved: isSaved,
                              ),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style == ExerciseStyle.setsReps ? 'تکرار' : 'زمان',
                      style: WorkoutLogTypography.fieldLabel(context),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: style == ExerciseStyle.setsReps
                          ? setControllers['reps']
                          : setControllers['time'],
                      focusNode: focusNodes != null
                          ? (style == ExerciseStyle.setsReps
                                ? focusNodes['reps']
                                : focusNodes['time'])
                          : null,
                      keyboardType: TextInputType.number,
                      textInputAction: style == ExerciseStyle.setsReps
                          ? TextInputAction.next
                          : (isLastSet
                                ? TextInputAction.done
                                : TextInputAction.next),
                      enableSuggestions: false,
                      autocorrect: false,
                      onSubmitted: (value) {
                        if (style == ExerciseStyle.setsReps) {
                          focusNodes?['weight']?.requestFocus();
                        } else {
                          if (isLastSet) {
                            focusNodes?['time']?.unfocus();
                          } else {
                            _moveToNextSet(exerciseId, setIndex, 'time');
                          }
                        }
                        onSaveSet(exerciseId, setIndex);
                      },
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: WorkoutLogTypography.inputValue(context),
                      decoration: _inputDecoration(
                        context: context,
                        hintText: numericHint.isNotEmpty ? numericHint : '0',
                        suffixText:
                            style == ExerciseStyle.setsTime ? 'ثانیه' : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (style == ExerciseStyle.setsReps) ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وزن',
                        style: WorkoutLogTypography.fieldLabel(context),
                      ),
                      SizedBox(height: 4.h),
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
                        onSubmitted: (value) {
                          if (isLastSet) {
                            focusNodes?['weight']?.unfocus();
                          } else {
                            _moveToNextSet(exerciseId, setIndex, 'reps');
                          }
                          onSaveSet(exerciseId, setIndex);
                        },
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                            RegExp('[0-9.]'),
                          ),
                        ],
                        style: WorkoutLogTypography.inputValue(context),
                        decoration: _inputDecoration(
                          context: context,
                          hintText: weightHint,
                          suffixText: 'کیلو',
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

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hintText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: WorkoutLogTypography.inputHint(context),
      suffixText: suffixText,
      suffixStyle: WorkoutLogTypography.inputSuffix(context),
      filled: true,
      fillColor: WorkoutLogColors.inputFill(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(
          color: WorkoutLogColors.inputBorder(context),
          width: 1.w,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(
          color: WorkoutLogColors.inputBorderFocused(context),
          width: 1.6.w,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 9.h,
      ),
      isDense: true,
    );
  }

  Widget _buildExerciseNote(BuildContext context, String note) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: WorkoutLogColors.noteBackground(context),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: WorkoutLogColors.noteBorder(context),
          width: 0.8.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.messageCircle,
            color: WorkoutLogColors.noteText(context),
            size: 12.sp,
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              note,
              style: WorkoutLogTypography.note(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetCompletionIndicator(
    BuildContext context,
    int completed,
    int total,
  ) {
    if (total == 0) return const SizedBox.shrink();
    final isAllDone = completed == total;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(total, (i) {
          final done = i < completed;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 8.w,
            height: 8.w,
            margin: EdgeInsets.only(left: 3.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? WorkoutLogColors.successSolid(context)
                  : WorkoutLogColors.pendingDot(context),
            ),
          );
        }),
        SizedBox(width: 6.w),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            isAllDone ? '✓ کامل' : '$completed/$total ست',
            key: ValueKey('$completed-$total'),
            style: WorkoutLogTypography.caption(
              context,
              color: isAllDone
                  ? WorkoutLogColors.successText(context)
                  : WorkoutLogColors.secondaryText(context),
              fontWeight: isAllDone ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ],
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
