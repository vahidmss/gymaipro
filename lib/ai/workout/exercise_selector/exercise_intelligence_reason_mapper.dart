import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_reason.dart';

/// Maps exercise intelligence reasons into generator explainability records.
class ExerciseIntelligenceReasonMapper {
  const ExerciseIntelligenceReasonMapper();

  List<WorkoutGeneratorReason> toGeneratorReasons(
    List<ExerciseIntelligenceReason> reasons,
  ) {
    return reasons
        .map(
          (reason) => WorkoutGeneratorReason(
            code: 'intelligence.${reason.code}',
            subject: reason.subject,
            because: reason.because,
          ),
        )
        .toList();
  }

  WorkoutGeneratorReason replacementReason({
    required String selectedName,
    required String replacedName,
  }) {
    return WorkoutGeneratorReason(
      code: 'intelligence.replacement.chosen',
      subject: selectedName,
      because: <String>[
        'Chosen Instead Of $replacedName',
        'Better Replacement',
      ],
    );
  }
}
