import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../models/workout_program_log.dart';
import '../theme/app_theme.dart';
import 'set_row.dart';

class ExerciseCard extends StatelessWidget {
  final NormalExercise exercise;
  final Exercise? exerciseDetails;
  final int loggedSets;
  final Map<int, List<TextEditingController>> repsControllers;
  final Map<int, List<TextEditingController>> weightControllers;
  final Map<String, Map<int, bool>> savedSets;
  final Function(int, int) onSaveSet;
  final Function(int, int)? findLastSetLog;

  const ExerciseCard({
    Key? key,
    required this.exercise,
    required this.exerciseDetails,
    required this.loggedSets,
    required this.repsControllers,
    required this.weightControllers,
    required this.savedSets,
    required this.onSaveSet,
    this.findLastSetLog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExerciseHeader(),
          _buildExerciseSets(),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          _buildExerciseImage(),
          const SizedBox(width: 12),
          Expanded(child: _buildExerciseInfo()),
        ],
      ),
    );
  }

  Widget _buildExerciseImage() {
    final hasImage = exerciseDetails?.imageUrl != null &&
        exerciseDetails!.imageUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: exerciseDetails!.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade300,
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (c, e, s) => Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade300,
                child: const Icon(LucideIcons.dumbbell, size: 24),
              ),
            )
          : Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade300,
              child: const Icon(LucideIcons.dumbbell, size: 24),
            ),
    );
  }

  Widget _buildExerciseInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exerciseDetails?.name ?? 'تمرین',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          exercise.tag,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                exercise.style == ExerciseStyle.setsReps
                    ? 'ست-تکرار'
                    : 'ست-زمان',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.goldColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (loggedSets > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$loggedSets/${exercise.sets.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseSets() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          exercise.sets.length,
          (setIdx) {
            final exerciseKey = exercise.exerciseId.toString();
            final isLogged = savedSets[exerciseKey]?[setIdx] ?? false;
            final lastLog = findLastSetLog?.call(exercise.exerciseId, setIdx);
            final setPlannedValue = _getSetPlannedValue(setIdx);

            final repsControllerList = repsControllers[exercise.exerciseId];
            final weightControllerList = weightControllers[exercise.exerciseId];

            if (repsControllerList == null ||
                weightControllerList == null ||
                setIdx >= repsControllerList.length ||
                setIdx >= weightControllerList.length) {
              return Container();
            }

            return SetRow(
              exercise: exercise,
              setIdx: setIdx,
              isLogged: isLogged,
              lastLog: lastLog,
              repsController: repsControllerList[setIdx],
              weightController: weightControllerList[setIdx],
              onSave: () => onSaveSet(exercise.exerciseId, setIdx),
              setPlannedValue: setPlannedValue,
            );
          },
        ),
      ),
    );
  }

  String _getSetPlannedValue(int setIdx) {
    return exercise.style == ExerciseStyle.setsReps
        ? (exercise.sets[setIdx].reps?.toString() ?? '')
        : (exercise.sets[setIdx].timeSeconds?.toString() ?? '');
  }
}
