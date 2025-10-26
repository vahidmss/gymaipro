import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WorkoutProgramExerciseCard extends StatefulWidget {
  const WorkoutProgramExerciseCard({
    required this.exercise,
    required this.allExercises,
    required this.onDelete,
    super.key,
    this.onMoveUp,
    this.onMoveDown,
  });
  final WorkoutExercise exercise;
  final List<Exercise> allExercises;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<WorkoutProgramExerciseCard> createState() =>
      _WorkoutProgramExerciseCardState();
}

class _WorkoutProgramExerciseCardState
    extends State<WorkoutProgramExerciseCard> {
  bool _isExpanded = false;

  // رنگ‌های اصلی برای بهبود مشاهده‌پذیری
  final Color primaryColor = const Color(0xFF3F51B5);
  final Color secondaryColor = const Color(0xFF4CAF50);
  final Color accentColor = const Color(0xFFFF9800);
  final Color lightTextColor = Colors.white;
  final Color darkTextColor = Colors.black87;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDarkMode),
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 320,
                ), // Limit height to avoid drag target error
                child: SingleChildScrollView(
                  child: _buildExerciseDetails(isDarkMode),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    final exercise = widget.exercise;
    String title;
    String subtitle;
    String imageUrl;

    if (exercise is NormalExercise) {
      final exerciseDetails = _findExerciseById(exercise.exerciseId);
      title = exerciseDetails?.name ?? 'تمرین ناشناخته';
      subtitle = '${exercise.sets.length} ست';
      imageUrl = exerciseDetails?.imageUrl ?? '';
    } else if (exercise is SupersetExercise) {
      title = 'سوپرست (${exercise.exercises.length} تمرین)';
      subtitle = '${exercise.exercises.first.sets.length} ست';

      final firstExercise = _findExerciseById(
        exercise.exercises.first.exerciseId,
      );
      imageUrl = firstExercise?.imageUrl ?? '';
    } else if (exercise is TrisetExercise) {
      title = 'تریپل‌ست (${exercise.exercises.length} تمرین)';
      subtitle = '${exercise.exercises.first.sets.length} ست';

      final firstExercise = _findExerciseById(
        exercise.exercises.first.exerciseId,
      );
      imageUrl = firstExercise?.imageUrl ?? '';
    } else {
      title = 'تمرین نامشخص';
      subtitle = '';
      imageUrl = '';
    }

    return Row(
      children: [
        // Exercise image
        Hero(
          tag: 'exercise_${exercise.id}',
          child: Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 5.r,
                  offset: Offset(0.w, 2.h),
                ),
              ],
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: imageUrl.isEmpty
                  ? primaryColor.withValues(alpha: 0.1)
                  : null,
            ),
            child: imageUrl.isEmpty
                ? Icon(LucideIcons.dumbbell, color: primaryColor, size: 24)
                : null,
          ),
        ),
        const SizedBox(width: 12),

        // Exercise info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: isDarkMode ? lightTextColor : darkTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDarkMode
                      ? lightTextColor.withValues(alpha: 0.1)
                      : Colors.grey[600],
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),

        // Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onMoveUp != null)
              IconButton(
                icon: Icon(
                  LucideIcons.arrowUp,
                  size: 18.sp,
                  color: accentColor,
                ),
                onPressed: widget.onMoveUp,
                tooltip: 'حرکت به بالا',
                padding: EdgeInsets.all(4.w),
                constraints: const BoxConstraints(),
              ),
            if (widget.onMoveDown != null)
              IconButton(
                icon: Icon(
                  LucideIcons.arrowDown,
                  size: 18.sp,
                  color: accentColor,
                ),
                onPressed: widget.onMoveDown,
                tooltip: 'حرکت به پایین',
                padding: EdgeInsets.all(4.w),
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _isExpanded ? LucideIcons.chevronsUp : LucideIcons.chevronsDown,
                size: 18.sp,
                color: primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              tooltip: _isExpanded ? 'بستن' : 'مشاهده جزئیات',
              padding: EdgeInsets.all(4.w),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(LucideIcons.trash2, size: 18.sp, color: Colors.red),
              onPressed: widget.onDelete,
              tooltip: 'حذف',
              padding: EdgeInsets.all(4.w),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseDetails(bool isDarkMode) {
    final exercise = widget.exercise;

    if (exercise is NormalExercise) {
      return _buildNormalExerciseDetails(exercise, isDarkMode);
    } else if (exercise is SupersetExercise) {
      return _buildSupersetExerciseDetails(exercise, isDarkMode);
    } else if (exercise is TrisetExercise) {
      return _buildTrisetExerciseDetails(exercise, isDarkMode);
    } else {
      return const Text('جزئیات در دسترس نیست');
    }
  }

  Widget _buildNormalExerciseDetails(NormalExercise exercise, bool isDarkMode) {
    final style = exercise.style == ExerciseStyle.setsReps
        ? 'ست-تکرار'
        : 'ست-زمان';

    // تعداد ست و تکرار برای نمایش و ویرایش
    int sets = exercise.sets.length;
    int reps = exercise.style == ExerciseStyle.setsReps
        ? (exercise.sets.isNotEmpty ? exercise.sets.first.reps ?? 10 : 10)
        : 0;
    int timeSeconds = exercise.style == ExerciseStyle.setsTime
        ? (exercise.sets.isNotEmpty
              ? exercise.sets.first.timeSeconds ?? 60
              : 60)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise type and style
        Chip(
          label: Text(
            style,
            style: TextStyle(fontSize: 12.sp, color: Colors.white),
          ),
          backgroundColor: primaryColor,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        const SizedBox(height: 12),

        // Sets and reps editor
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? primaryColor.withValues(alpha: 0.1)
                : primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
          ),
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Sets counter
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تعداد ست',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  if (sets > 1) {
                                    sets--;
                                    exercise.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps:
                                            exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds:
                                            exercise.style ==
                                                ExerciseStyle.setsTime
                                            ? timeSeconds
                                            : null,
                                        weight: 0,
                                      ),
                                    );
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 12.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.black26
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                '$sets',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  sets++;
                                  exercise.sets = List.generate(
                                    sets,
                                    (index) => ExerciseSet(
                                      reps:
                                          exercise.style ==
                                              ExerciseStyle.setsReps
                                          ? reps
                                          : null,
                                      timeSeconds:
                                          exercise.style ==
                                              ExerciseStyle.setsTime
                                          ? timeSeconds
                                          : null,
                                      weight: 0,
                                    ),
                                  );
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Reps counter
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.style == ExerciseStyle.setsReps
                              ? 'تکرار در هر ست'
                              : 'زمان (ثانیه)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  if (exercise.style ==
                                      ExerciseStyle.setsReps) {
                                    if (reps > 1) reps--;
                                  } else {
                                    if (timeSeconds > 10) timeSeconds -= 5;
                                  }
                                  exercise.sets = List.generate(
                                    sets,
                                    (index) => ExerciseSet(
                                      reps:
                                          exercise.style ==
                                              ExerciseStyle.setsReps
                                          ? reps
                                          : null,
                                      timeSeconds:
                                          exercise.style ==
                                              ExerciseStyle.setsTime
                                          ? timeSeconds
                                          : null,
                                      weight: 0,
                                    ),
                                  );
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 12.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.black26
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                exercise.style == ExerciseStyle.setsReps
                                    ? '$reps'
                                    : exercise.style == ExerciseStyle.setsTime
                                    ? '$timeSeconds'
                                    : '0',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  if (exercise.style ==
                                      ExerciseStyle.setsReps) {
                                    reps++;
                                  } else {
                                    timeSeconds += 5;
                                  }
                                  exercise.sets = List.generate(
                                    sets,
                                    (index) => ExerciseSet(
                                      reps:
                                          exercise.style ==
                                              ExerciseStyle.setsReps
                                          ? reps
                                          : null,
                                      timeSeconds:
                                          exercise.style ==
                                              ExerciseStyle.setsTime
                                          ? timeSeconds
                                          : null,
                                      weight: 0,
                                    ),
                                  );
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupersetExerciseDetails(
    SupersetExercise exercise,
    bool isDarkMode,
  ) {
    final style = exercise.style == ExerciseStyle.setsReps
        ? 'ست-تکرار'
        : 'ست-زمان';

    // تعداد ست و تکرار برای تمامی تمرین‌های سوپرست
    int sets = exercise.exercises.isNotEmpty
        ? exercise.exercises.first.sets.length
        : 0;
    int reps = exercise.style == ExerciseStyle.setsReps
        ? (exercise.exercises.isNotEmpty &&
                  exercise.exercises.first.sets.isNotEmpty
              ? exercise.exercises.first.sets.first.reps ?? 10
              : 10)
        : 0;
    int timeSeconds = exercise.style == ExerciseStyle.setsTime
        ? (exercise.exercises.isNotEmpty &&
                  exercise.exercises.first.sets.isNotEmpty
              ? exercise.exercises.first.sets.first.timeSeconds ?? 60
              : 60)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise type info
        Chip(
          label: Text(
            style,
            style: TextStyle(fontSize: 12.sp, color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        const SizedBox(height: 12),

        // Exercise list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exercise.exercises.length,
          itemBuilder: (context, index) {
            final exerciseItem = exercise.exercises[index];
            final exerciseDetails = _findExerciseById(exerciseItem.exerciseId);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exerciseDetails?.name ?? 'تمرین ناشناخته',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Shared sets and reps editor for all exercises in superset
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
          ),
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Sets counter
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تعداد ست',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  if (sets > 1) {
                                    sets--;
                                    // Update all exercises in superset
                                    for (final item in exercise.exercises) {
                                      item.sets = List.generate(
                                        sets,
                                        (index) => ExerciseSet(
                                          reps:
                                              exercise.style ==
                                                  ExerciseStyle.setsReps
                                              ? reps
                                              : null,
                                          timeSeconds:
                                              exercise.style ==
                                                  ExerciseStyle.setsTime
                                              ? timeSeconds
                                              : null,
                                          weight: 0,
                                        ),
                                      );
                                    }
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 12.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.black26
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                '$sets',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  sets++;
                                  // Update all exercises in superset
                                  for (final item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps:
                                            exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds:
                                            exercise.style ==
                                                ExerciseStyle.setsTime
                                            ? timeSeconds
                                            : null,
                                        weight: 0,
                                      ),
                                    );
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Reps counter
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.style == ExerciseStyle.setsReps
                              ? 'تکرار در هر ست'
                              : 'زمان (ثانیه)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  if (exercise.style ==
                                      ExerciseStyle.setsReps) {
                                    if (reps > 1) reps--;
                                  } else {
                                    if (timeSeconds > 10) timeSeconds -= 5;
                                  }
                                  // Update all exercises in superset
                                  for (final item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps:
                                            exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds:
                                            exercise.style ==
                                                ExerciseStyle.setsTime
                                            ? timeSeconds
                                            : null,
                                        weight: 0,
                                      ),
                                    );
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 12.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.black26
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                exercise.style == ExerciseStyle.setsReps
                                    ? '$reps'
                                    : exercise.style == ExerciseStyle.setsTime
                                    ? '$timeSeconds'
                                    : '0',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  if (exercise.style ==
                                      ExerciseStyle.setsReps) {
                                    reps++;
                                  } else {
                                    timeSeconds += 5;
                                  }
                                  // Update all exercises in superset
                                  for (final item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps:
                                            exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds:
                                            exercise.style ==
                                                ExerciseStyle.setsTime
                                            ? timeSeconds
                                            : null,
                                        weight: 0,
                                      ),
                                    );
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrisetExerciseDetails(TrisetExercise exercise, bool isDarkMode) {
    final style = exercise.style == ExerciseStyle.setsReps
        ? 'ست-تکرار'
        : 'ست-زمان';

    // تعداد ست و تکرار برای تمامی تمرین‌های تریست
    int sets = exercise.exercises.isNotEmpty
        ? exercise.exercises.first.sets.length
        : 0;
    int reps = exercise.style == ExerciseStyle.setsReps
        ? (exercise.exercises.isNotEmpty &&
                  exercise.exercises.first.sets.isNotEmpty
              ? exercise.exercises.first.sets.first.reps ?? 10
              : 10)
        : 0;
    int timeSeconds = exercise.style == ExerciseStyle.setsTime
        ? (exercise.exercises.isNotEmpty &&
                  exercise.exercises.first.sets.isNotEmpty
              ? exercise.exercises.first.sets.first.timeSeconds ?? 60
              : 60)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise type info
        Chip(
          label: Text(
            style,
            style: TextStyle(fontSize: 12.sp, color: Colors.white),
          ),
          backgroundColor: Colors.purple,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        const SizedBox(height: 12),

        // Exercise list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exercise.exercises.length,
          itemBuilder: (context, index) {
            final exerciseItem = exercise.exercises[index];
            final exerciseDetails = _findExerciseById(exerciseItem.exerciseId);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.purple.withValues(alpha: 0.1)
                    : Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purple,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exerciseDetails?.name ?? 'تمرین ناشناخته',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Shared sets and reps editor for all exercises in triset
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.purple.withValues(alpha: 0.1)
                : Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
          ),
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Sets counter
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تعداد ست',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  if (sets > 1) {
                                    sets--;
                                    // Update all exercises in triset
                                    for (final item in exercise.exercises) {
                                      item.sets = List.generate(
                                        sets,
                                        (index) => ExerciseSet(
                                          reps:
                                              exercise.style ==
                                                  ExerciseStyle.setsReps
                                              ? reps
                                              : null,
                                          timeSeconds:
                                              exercise.style ==
                                                  ExerciseStyle.setsTime
                                              ? timeSeconds
                                              : null,
                                          weight: 0,
                                        ),
                                      );
                                    }
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 12.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.black26
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                '$sets',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  sets++;
                                  // Update all exercises in triset
                                  for (final item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps:
                                            exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds:
                                            exercise.style ==
                                                ExerciseStyle.setsTime
                                            ? timeSeconds
                                            : null,
                                        weight: 0,
                                      ),
                                    );
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Reps counter
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.style == ExerciseStyle.setsReps
                              ? 'تکرار در هر ست'
                              : 'زمان (ثانیه)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  if (exercise.style ==
                                      ExerciseStyle.setsReps) {
                                    if (reps > 1) reps--;
                                  } else {
                                    if (timeSeconds > 10) timeSeconds -= 5;
                                  }
                                  // Update all exercises in triset
                                  for (final item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps:
                                            exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds:
                                            exercise.style ==
                                                ExerciseStyle.setsTime
                                            ? timeSeconds
                                            : null,
                                        weight: 0,
                                      ),
                                    );
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 12.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.black26
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                exercise.style == ExerciseStyle.setsReps
                                    ? '$reps'
                                    : exercise.style == ExerciseStyle.setsTime
                                    ? '$timeSeconds'
                                    : '0',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  if (exercise.style ==
                                      ExerciseStyle.setsReps) {
                                    reps++;
                                  } else {
                                    timeSeconds += 5;
                                  }
                                  // Update all exercises in triset
                                  for (final item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps:
                                            exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds:
                                            exercise.style ==
                                                ExerciseStyle.setsTime
                                            ? timeSeconds
                                            : null,
                                        weight: 0,
                                      ),
                                    );
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Exercise? _findExerciseById(int id) {
    try {
      return widget.allExercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}
