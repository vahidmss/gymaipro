import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    required this.exercise,
    required this.exerciseDetails,
    required this.exerciseControllers,
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
  final Map<String, List<bool>> setSavedStatus;
  final Map<String, bool> collapsedExercises;
  final Function(String) onToggleCollapse;
  final Function(int) onNavigateToTutorial;
  final Function(String, int) onSaveSet;

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
    final exerciseDetails = this.exerciseDetails[exercise.exerciseId];
    final isCollapsed = collapsedExercises[exerciseId] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20.r,
            offset: Offset(0.w, 8.h),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            child: Container(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  // Exercise icon
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFD4AF37).withValues(alpha: 0.2),
                          const Color(0xFFB8860B).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                        width: 1.5.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                          blurRadius: 8.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
                    ),
                    child: exerciseDetails?.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.network(
                              exerciseDetails!.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    LucideIcons.dumbbell,
                                    color: const Color(0xFFD4AF37),
                                    size: 22.sp,
                                  ),
                            ),
                          )
                        : Icon(
                            LucideIcons.dumbbell,
                            color: const Color(0xFFD4AF37),
                            size: 22.sp,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Exercise info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getExerciseName(exercise.exerciseId),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.2),
                                    const Color(
                                      0xFFB8860B,
                                    ).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                exercise.tag,
                                style: TextStyle(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Display exercise note if available
                        if (exercise.note != null &&
                            exercise.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[700]!.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: Colors.amber[700]!.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.messageCircle,
                                  color: Colors.amber[700],
                                  size: 12.sp,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    exercise.note!.length > 110
                                        ? '${exercise.note!.substring(0, 80)}...'
                                        : exercise.note!,
                                    style: TextStyle(
                                      color: Colors.amber[700],
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Tutorial button
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[600]!.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.blue[600]!.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () => onNavigateToTutorial(exercise.exerciseId),
                        child: Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Icon(
                            LucideIcons.eye,
                            color: Colors.blue[400],
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Collapse/Expand icon
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFD4AF37).withValues(alpha: 0.1),
                          const Color(0xFFB8860B).withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      isCollapsed
                          ? LucideIcons.chevronDown
                          : LucideIcons.chevronUp,
                      color: const Color(0xFFD4AF37),
                      size: 18.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sets - Collapsible
          if (!isCollapsed) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20.r),
                ),
              ),
              child: Column(
                children: List.generate(exercise.sets.length, (setIndex) {
                  final defaultReps = exercise.style == ExerciseStyle.setsReps
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
                    defaultReps: defaultReps,
                    defaultTimeSeconds: defaultTimeSeconds,
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupersetExerciseCard(SupersetExercise exercise) {
    final exerciseId = exercise.id;
    final isCollapsed = collapsedExercises[exerciseId] ?? true;
    final totalSets = exercise.exercises.first.sets.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20.r,
            offset: Offset(0.w, 8.h),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            child: Container(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  // Superset icon
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFD4AF37).withValues(alpha: 0.2),
                          const Color(0xFFB8860B).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                        width: 1.5.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                          blurRadius: 8.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.zap,
                      color: const Color(0xFFD4AF37),
                      size: 22.sp,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Superset info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.2),
                                    const Color(
                                      0xFFB8860B,
                                    ).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'سوپرست',
                                style: TextStyle(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              exercise.tag,
                              style: TextStyle(
                                color: const Color(
                                  0xFFD4AF37,
                                ).withValues(alpha: 0.8),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800]!.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              child: Text(
                                '${exercise.exercises.length} تمرین • $totalSets ست',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Display superset exercise note if available
                        if (exercise.note != null &&
                            exercise.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[700]!.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: Colors.amber[700]!.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.messageCircle,
                                  color: Colors.amber[700],
                                  size: 12.sp,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    exercise.note!.length > 80
                                        ? '${exercise.note!.substring(0, 80)}...'
                                        : exercise.note!,
                                    style: TextStyle(
                                      color: Colors.amber[700],
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Collapse/Expand icon
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFD4AF37).withValues(alpha: 0.1),
                          const Color(0xFFB8860B).withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      isCollapsed
                          ? LucideIcons.chevronDown
                          : LucideIcons.chevronUp,
                      color: const Color(0xFFD4AF37),
                      size: 18.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Exercises - Collapsible
          if (!isCollapsed) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20.r),
                ),
              ),
              child: Column(
                children: exercise.exercises.map((item) {
                  final itemId = '${exercise.id}_${item.exerciseId}';
                  final savedStatus = setSavedStatus[itemId] ?? [];
                  final exerciseDetails = this.exerciseDetails[item.exerciseId];

                  return Column(
                    children: [
                      // Exercise header
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1),
                              width: 0.5.w,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.h,
                              decoration: BoxDecoration(
                                color: Colors.amber[700]!.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: exerciseDetails?.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6.r),
                                      child: Image.network(
                                        exerciseDetails!.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  LucideIcons.dumbbell,
                                                  color: Colors.amber[700],
                                                  size: 16.sp,
                                                ),
                                      ),
                                    )
                                  : Icon(
                                      LucideIcons.dumbbell,
                                      color: Colors.amber[700],
                                      size: 16.sp,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getExerciseName(item.exerciseId),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sets for this exercise
                      ...List.generate(item.sets.length, (setIndex) {
                        final defaultReps = item.style == ExerciseStyle.setsReps
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
                          defaultReps: defaultReps,
                          defaultTimeSeconds: defaultTimeSeconds,
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactSetRow(
    String exerciseId,
    int setIndex,
    ExerciseStyle style,
    bool isSaved, {
    int? defaultReps,
    int? defaultTimeSeconds,
  }) {
    final controllers = exerciseControllers[exerciseId];
    if (controllers == null || controllers.length <= setIndex) {
      return const SizedBox.shrink();
    }

    final setControllers = controllers[setIndex];

    // تعیین هینت عددی از خود برنامه (reps یا timeSeconds)
    final String numericHint = style == ExerciseStyle.setsReps
        ? (defaultReps?.toString() ?? '')
        : (defaultTimeSeconds?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
      decoration: BoxDecoration(
        color: isSaved
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 0.5.w,
          ),
        ),
      ),
      child: Row(
        children: [
          // Set number
          Container(
            width: 28.w,
            height: 28.h,
            decoration: BoxDecoration(
              color: isSaved
                  ? Colors.green
                  : Colors.amber[700]!.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Center(
              child: isSaved
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : Text(
                      '${setIndex + 1}',
                      style: TextStyle(
                        color: isSaved ? Colors.white : Colors.amber[300],
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Reps/Time input (FIRST)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      style == ExerciseStyle.setsReps ? 'تکرار' : 'زمان',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: style == ExerciseStyle.setsReps
                      ? setControllers['reps']
                      : setControllers['time'],
                  enabled: !isSaved,
                  keyboardType: const TextInputType.numberWithOptions(),
                  textInputAction: TextInputAction.next,
                  enableSuggestions: false,
                  autocorrect: false,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: numericHint.isNotEmpty ? numericHint : '0',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                    suffixText: style == ExerciseStyle.setsTime
                        ? 'ثانیه'
                        : null,
                    suffixStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11.sp,
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 6.h,
                    ),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          if (style == ExerciseStyle.setsReps) ...[
            const SizedBox(width: 8),
            // Weight input (SECOND)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'وزن',
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: setControllers['weight'],
                    enabled: !isSaved,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    enableSuggestions: false,
                    autocorrect: false,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\\.]')),
                    ],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12.sp,
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 6.h,
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 8),
          // Save button
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: isSaved
                  ? Colors.green
                  : Colors.amber[700]!.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6.r),
                onTap: isSaved ? null : () => onSaveSet(exerciseId, setIndex),
                child: Center(
                  child: isSaved
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Icon(
                          LucideIcons.save,
                          color: Colors.amber[300],
                          size: 16.sp,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getExerciseName(int exerciseId) {
    final exerciseDetails = this.exerciseDetails[exerciseId];
    if (exerciseDetails != null) {
      return exerciseDetails.name;
    }
    return 'تمرین';
  }
}
