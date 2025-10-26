import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/widgets/exercise_note_button.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/widgets/exercise_stepper.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  final Function(String?) onNoteChanged;
  final Function(ExerciseStyle) onStyleChanged;
  final Function(int) onSetsChanged;
  final Function(int) onRepsChanged;
  final Function(int) onTimeChanged;
  final Function(double) onWeightChanged;
  final Function(int, ExerciseStyle) onSupersetStyleChanged;
  final Function(int, int) onSupersetSetsChanged;
  final Function(int, int) onSupersetRepsChanged;
  final Function(int, int) onSupersetTimeChanged;
  final List<Exercise> allExercises;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.amber[700]!;
    final Color backgroundColor = Colors.amber[50]!;
    final Color borderColor = Colors.amber[200]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, backgroundColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
        border: Border.all(color: borderColor, width: 2),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    if (index > 0 && index < totalExercises - 1) ...[
                      GestureDetector(
                        onTap: onMoveUp,
                        child: SizedBox(
                          width: 8.w,
                          height: 8.h,
                          child: Icon(
                            Icons.arrow_upward,
                            color: primaryColor,
                            size: 12.sp,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onMoveDown,
                        child: SizedBox(
                          width: 8.w,
                          height: 8.h,
                          child: Icon(
                            Icons.arrow_downward,
                            color: primaryColor,
                            size: 12.sp,
                          ),
                        ),
                      ),
                    ],
                    if (index == 0 && totalExercises > 1)
                      GestureDetector(
                        onTap: onMoveDown,
                        child: SizedBox(
                          width: 8.w,
                          height: 8.h,
                          child: Icon(
                            Icons.arrow_downward,
                            color: primaryColor,
                            size: 12.sp,
                          ),
                        ),
                      ),
                    if (index == totalExercises - 1 && totalExercises > 1)
                      GestureDetector(
                        onTap: onMoveUp,
                        child: SizedBox(
                          width: 8.w,
                          height: 8.h,
                          child: Icon(
                            Icons.arrow_upward,
                            color: primaryColor,
                            size: 12.sp,
                          ),
                        ),
                      ),
                  ],
                ),
                // Exercise image or icon
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
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
                          ),
                        )
                      : Icon(
                          LucideIcons.dumbbell,
                          color: primaryColor,
                          size: 14.sp,
                        ),
                ),
                const SizedBox(width: 8),
                // Exercise name only
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 160.w,
                        child: Text(
                          exerciseDetails.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: 14.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (exercise is NormalExercise)
                        ExerciseNoteButton(
                          note: (exercise as NormalExercise).note,
                          onNoteChanged: onNoteChanged,
                          iconSize: 16,
                          color: Colors.amber[700],
                        ),
                      if (exercise is SupersetExercise)
                        ExerciseNoteButton(
                          note: (exercise as SupersetExercise).note,
                          onNoteChanged: onNoteChanged,
                          iconSize: 16,
                          color: Colors.amber[700],
                        ),
                      // Delete button only
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.trash2,
                            color: Colors.red[600],
                            size: 18.sp,
                          ),
                          onPressed: onDelete,
                          tooltip: 'حذف حرکت',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Note display
            if (exercise is NormalExercise &&
                (exercise as NormalExercise).note != null &&
                (exercise as NormalExercise).note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  (exercise as NormalExercise).note!.length > 100
                      ? '${(exercise as NormalExercise).note!.substring(0, 100)}...'
                      : (exercise as NormalExercise).note!,
                  style: TextStyle(
                    color: Colors.amber[900],
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (exercise is SupersetExercise &&
                (exercise as SupersetExercise).note != null &&
                (exercise as SupersetExercise).note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  (exercise as SupersetExercise).note!.length > 100
                      ? '${(exercise as SupersetExercise).note!.substring(0, 100)}...'
                      : (exercise as SupersetExercise).note!,
                  style: TextStyle(
                    color: Colors.amber[900],
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Exercise configuration
            if (exercise is NormalExercise)
              _buildNormalExerciseConfig(exercise as NormalExercise),
            if (exercise is SupersetExercise)
              _buildSupersetExerciseConfig(exercise as SupersetExercise),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalExerciseConfig(NormalExercise exercise) {
    final Color primaryColor = Colors.amber[700]!;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        color: Colors.amber[50],
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 4.h, top: 2),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Text(
                      'نوع حرکت:',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.amber[300]!),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      child: Row(
                        children: [
                          ChoiceChip(
                            key: ValueKey(
                              'sets-reps-${exercise.id}-${exercise.style}',
                            ),
                            avatar: Icon(
                              Icons.repeat,
                              size: 15.sp,
                              color: exercise.style == ExerciseStyle.setsReps
                                  ? Colors.brown
                                  : Colors.amber[700],
                            ),
                            label: const Text(
                              'ست-تکرار',
                              style: TextStyle(fontSize: 11),
                            ),
                            selected: exercise.style == ExerciseStyle.setsReps,
                            onSelected: (selected) {
                              if (selected &&
                                  exercise.style != ExerciseStyle.setsReps) {
                                onStyleChanged(ExerciseStyle.setsReps);
                              }
                            },
                            selectedColor: Colors.amber[300],
                            backgroundColor: Colors.amber[50],
                            labelStyle: TextStyle(
                              color: exercise.style == ExerciseStyle.setsReps
                                  ? Colors.brown
                                  : Colors.amber[700],
                              fontWeight:
                                  exercise.style == ExerciseStyle.setsReps
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            elevation: exercise.style == ExerciseStyle.setsReps
                                ? 2
                                : 0,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            key: ValueKey(
                              'sets-time-${exercise.id}-${exercise.style}',
                            ),
                            avatar: Icon(
                              Icons.timer,
                              size: 15.sp,
                              color: exercise.style == ExerciseStyle.setsTime
                                  ? Colors.brown
                                  : Colors.amber[700],
                            ),
                            label: const Text(
                              'ست-زمان',
                              style: TextStyle(fontSize: 11),
                            ),
                            selected: exercise.style == ExerciseStyle.setsTime,
                            onSelected: (selected) {
                              if (selected &&
                                  exercise.style != ExerciseStyle.setsTime) {
                                onStyleChanged(ExerciseStyle.setsTime);
                              }
                            },
                            selectedColor: Colors.amber[300],
                            backgroundColor: Colors.amber[50],
                            labelStyle: TextStyle(
                              color: exercise.style == ExerciseStyle.setsTime
                                  ? Colors.brown
                                  : Colors.amber[700],
                              fontWeight:
                                  exercise.style == ExerciseStyle.setsTime
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            elevation: exercise.style == ExerciseStyle.setsTime
                                ? 2
                                : 0,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Text(
                      'ست:',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ExerciseStepper(
                      value: exercise.sets.length,
                      min: 1,
                      onChanged: onSetsChanged,
                      small: true,
                    ),
                    const SizedBox(width: 8),
                    if (exercise.style == ExerciseStyle.setsReps) ...[
                      Text(
                        'تکرار:',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ExerciseStepper(
                        value: exercise.sets.isNotEmpty
                            ? (exercise.sets[0].reps ?? 10)
                            : 10,
                        min: 1,
                        onChanged: onRepsChanged,
                        small: true,
                      ),
                    ] else ...[
                      Text(
                        'زمان (ثانیه):',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ExerciseStepper(
                        value: exercise.sets.isNotEmpty
                            ? (exercise.sets[0].timeSeconds ?? 30)
                            : 30,
                        min: 1,
                        onChanged: onTimeChanged,
                        small: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupersetExerciseConfig(SupersetExercise exercise) {
    final Color primaryColor = Colors.amber[700]!;

    return Padding(
      key: UniqueKey(),
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        color: Colors.amber[50],
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'سوپرست',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                                ),
                              )
                            else
                              Icon(
                                LucideIcons.dumbbell,
                                color: Colors.amber[700],
                                size: 20.sp,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                exDetails.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber[900],
                                  fontSize: 14.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Individual style selection for each exercise
                        Row(
                          children: [
                            const SizedBox(width: 14),
                            Text(
                              'نوع حرکت:',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.amber[300]!),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 2.h,
                              ),
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    key: ValueKey(
                                      'sets-reps-${supersetItem.exerciseId}-${supersetItem.style}',
                                    ),
                                    avatar: Icon(
                                      Icons.repeat,
                                      size: 15.sp,
                                      color:
                                          supersetItem.style ==
                                              ExerciseStyle.setsReps
                                          ? Colors.brown
                                          : Colors.amber[700],
                                    ),
                                    label: const Text(
                                      'ست-تکرار',
                                      style: TextStyle(fontSize: 11),
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
                                    selectedColor: Colors.amber[300],
                                    backgroundColor: Colors.amber[50],
                                    labelStyle: TextStyle(
                                      color:
                                          supersetItem.style ==
                                              ExerciseStyle.setsReps
                                          ? Colors.brown
                                          : Colors.amber[700],
                                      fontWeight:
                                          supersetItem.style ==
                                              ExerciseStyle.setsReps
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    elevation:
                                        supersetItem.style ==
                                            ExerciseStyle.setsReps
                                        ? 2
                                        : 0,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 4),
                                  ChoiceChip(
                                    key: ValueKey(
                                      'sets-time-${supersetItem.exerciseId}-${supersetItem.style}',
                                    ),
                                    avatar: Icon(
                                      Icons.timer,
                                      size: 15.sp,
                                      color:
                                          supersetItem.style ==
                                              ExerciseStyle.setsTime
                                          ? Colors.brown
                                          : Colors.amber[700],
                                    ),
                                    label: const Text(
                                      'ست-زمان',
                                      style: TextStyle(fontSize: 11),
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
                                    selectedColor: Colors.amber[300],
                                    backgroundColor: Colors.amber[50],
                                    labelStyle: TextStyle(
                                      color:
                                          supersetItem.style ==
                                              ExerciseStyle.setsTime
                                          ? Colors.brown
                                          : Colors.amber[700],
                                      fontWeight:
                                          supersetItem.style ==
                                              ExerciseStyle.setsTime
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    elevation:
                                        supersetItem.style ==
                                            ExerciseStyle.setsTime
                                        ? 2
                                        : 0,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              Text(
                                'ست:',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                ),
                              ),
                              const SizedBox(width: 4),
                              ExerciseStepper(
                                value: supersetItem.sets.length,
                                min: 1,
                                onChanged: (val) {
                                  onSupersetSetsChanged(i, val);
                                },
                                small: true,
                              ),
                              const SizedBox(width: 12),
                              if (supersetItem.style ==
                                  ExerciseStyle.setsReps) ...[
                                const SizedBox(width: 32),
                                Text(
                                  'تکرار:',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                const SizedBox(width: 4),
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
                              ] else ...[
                                Text(
                                  'زمان (ثانیه):',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                ExerciseStepper(
                                  value: supersetItem.sets.isNotEmpty
                                      ? (supersetItem.sets[0].timeSeconds ?? 30)
                                      : 30,
                                  min: 1,
                                  onChanged: (val) {
                                    onSupersetTimeChanged(i, val);
                                  },
                                  small: true,
                                ),
                              ],
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (i < exercise.exercises.length - 1)
                  Divider(color: Colors.amber[100], height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
