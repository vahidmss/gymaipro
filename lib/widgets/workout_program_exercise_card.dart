import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/workout_program.dart';
import '../models/exercise.dart';

class WorkoutProgramExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final List<Exercise> allExercises;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const WorkoutProgramExerciseCard({
    Key? key,
    required this.exercise,
    required this.allExercises,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  }) : super(key: key);

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
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDarkMode),
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              _buildExerciseDetails(isDarkMode),
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

      final firstExercise =
          _findExerciseById(exercise.exercises.first.exerciseId);
      imageUrl = firstExercise?.imageUrl ?? '';
    } else if (exercise is TrisetExercise) {
      title = 'تریپل‌ست (${exercise.exercises.length} تمرین)';
      subtitle = '${exercise.exercises.first.sets.length} ست';

      final firstExercise =
          _findExerciseById(exercise.exercises.first.exerciseId);
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: imageUrl.isEmpty ? primaryColor.withOpacity(0.1) : null,
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
                  fontSize: 16,
                  color: isDarkMode ? lightTextColor : darkTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDarkMode
                      ? lightTextColor.withOpacity(0.7)
                      : Colors.grey[600],
                  fontSize: 13,
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
                icon: Icon(LucideIcons.arrowUp, size: 18, color: accentColor),
                onPressed: widget.onMoveUp,
                tooltip: 'حرکت به بالا',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            if (widget.onMoveDown != null)
              IconButton(
                icon: Icon(LucideIcons.arrowDown, size: 18, color: accentColor),
                onPressed: widget.onMoveDown,
                tooltip: 'حرکت به پایین',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _isExpanded ? LucideIcons.chevronsUp : LucideIcons.chevronsDown,
                size: 18,
                color: primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              tooltip: _isExpanded ? 'بستن' : 'مشاهده جزئیات',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
              onPressed: widget.onDelete,
              tooltip: 'حذف',
              padding: const EdgeInsets.all(4),
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
    final style =
        exercise.style == ExerciseStyle.setsReps ? 'ست-تکرار' : 'ست-زمان';

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
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: primaryColor,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
        const SizedBox(height: 12),

        // Sets and reps editor
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? primaryColor.withOpacity(0.1)
                : primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
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
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (sets > 1) {
                                    sets--;
                                    exercise.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps: exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds: exercise.style ==
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode ? Colors.black26 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '$sets',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  sets++;
                                  exercise.sets = List.generate(
                                    sets,
                                    (index) => ExerciseSet(
                                      reps: exercise.style ==
                                              ExerciseStyle.setsReps
                                          ? reps
                                          : null,
                                      timeSeconds: exercise.style ==
                                              ExerciseStyle.setsTime
                                          ? timeSeconds
                                          : null,
                                      weight: 0,
                                    ),
                                  );
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16,
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
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
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
                                      reps: exercise.style ==
                                              ExerciseStyle.setsReps
                                          ? reps
                                          : null,
                                      timeSeconds: exercise.style ==
                                              ExerciseStyle.setsTime
                                          ? timeSeconds
                                          : null,
                                      weight: 0,
                                    ),
                                  );
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode ? Colors.black26 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                exercise.style == ExerciseStyle.setsReps
                                    ? '$reps'
                                    : exercise.style == ExerciseStyle.setsTime
                                        ? '$timeSeconds'
                                        : '0',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
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
                                      reps: exercise.style ==
                                              ExerciseStyle.setsReps
                                          ? reps
                                          : null,
                                      timeSeconds: exercise.style ==
                                              ExerciseStyle.setsTime
                                          ? timeSeconds
                                          : null,
                                      weight: 0,
                                    ),
                                  );
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16,
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
      SupersetExercise exercise, bool isDarkMode) {
    final style =
        exercise.style == ExerciseStyle.setsReps ? 'ست-تکرار' : 'ست-زمان';

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
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                ? Colors.blue.withOpacity(0.1)
                : Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
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
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (sets > 1) {
                                    sets--;
                                    // Update all exercises in superset
                                    for (var item in exercise.exercises) {
                                      item.sets = List.generate(
                                        sets,
                                        (index) => ExerciseSet(
                                          reps: exercise.style ==
                                                  ExerciseStyle.setsReps
                                              ? reps
                                              : null,
                                          timeSeconds: exercise.style ==
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
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode ? Colors.black26 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '$sets',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  sets++;
                                  // Update all exercises in superset
                                  for (var item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps: exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds: exercise.style ==
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
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16,
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
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (exercise.style ==
                                      ExerciseStyle.setsReps) {
                                    if (reps > 1) reps--;
                                  } else {
                                    if (timeSeconds > 10) timeSeconds -= 5;
                                  }
                                  // Update all exercises in superset
                                  for (var item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps: exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds: exercise.style ==
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode ? Colors.black26 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                exercise.style == ExerciseStyle.setsReps
                                    ? '$reps'
                                    : exercise.style == ExerciseStyle.setsTime
                                        ? '$timeSeconds'
                                        : '0',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (exercise.style ==
                                      ExerciseStyle.setsReps) {
                                    reps++;
                                  } else {
                                    timeSeconds += 5;
                                  }
                                  // Update all exercises in superset
                                  for (var item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps: exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds: exercise.style ==
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16,
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
    final style =
        exercise.style == ExerciseStyle.setsReps ? 'ست-تکرار' : 'ست-زمان';

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
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: Colors.purple,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.purple.withOpacity(0.1)
                    : Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purple,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                ? Colors.purple.withOpacity(0.1)
                : Colors.purple.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
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
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (sets > 1) {
                                    sets--;
                                    // Update all exercises in triset
                                    for (var item in exercise.exercises) {
                                      item.sets = List.generate(
                                        sets,
                                        (index) => ExerciseSet(
                                          reps: exercise.style ==
                                                  ExerciseStyle.setsReps
                                              ? reps
                                              : null,
                                          timeSeconds: exercise.style ==
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
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode ? Colors.black26 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.purple.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '$sets',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  sets++;
                                  // Update all exercises in triset
                                  for (var item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps: exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds: exercise.style ==
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
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16,
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
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (exercise.style ==
                                      ExerciseStyle.setsReps) {
                                    if (reps > 1) reps--;
                                  } else {
                                    if (timeSeconds > 10) timeSeconds -= 5;
                                  }
                                  // Update all exercises in triset
                                  for (var item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps: exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds: exercise.style ==
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.minus,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode ? Colors.black26 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                exercise.style == ExerciseStyle.setsReps
                                    ? '$reps'
                                    : exercise.style == ExerciseStyle.setsTime
                                        ? '$timeSeconds'
                                        : '0',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (exercise.style ==
                                      ExerciseStyle.setsReps) {
                                    reps++;
                                  } else {
                                    timeSeconds += 5;
                                  }
                                  // Update all exercises in triset
                                  for (var item in exercise.exercises) {
                                    item.sets = List.generate(
                                      sets,
                                      (index) => ExerciseSet(
                                        reps: exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? reps
                                            : null,
                                        timeSeconds: exercise.style ==
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 16,
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

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Exercise? _findExerciseById(int id) {
    try {
      return widget.allExercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}
