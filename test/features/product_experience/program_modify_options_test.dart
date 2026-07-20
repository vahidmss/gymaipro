import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/features/product_experience/domain/program_modify_options.dart';

void main() {
  group('ProgramModifyGoal', () {
    test('replace needs exercise and reason', () {
      expect(ProgramModifyGoal.replaceExercise.needsExercise, isTrue);
      expect(ProgramModifyGoal.replaceExercise.needsReason, isTrue);
      expect(
        ProgramModifyGoal.replaceExercise.engineTypes,
        contains(WorkoutModificationType.replaceExercise),
      );
    });

    test('session-level goals do not need exercise', () {
      expect(ProgramModifyGoal.easierSession.needsExercise, isFalse);
      expect(ProgramModifyGoal.shorterSession.needsExercise, isFalse);
      expect(ProgramModifyGoal.homeVersion.needsExercise, isFalse);
    });

    test('builds persian request text with exercise', () {
      final text = ProgramModifyGoal.replaceExercise.buildRequestText(
        exerciseName: 'اسکوات',
        reasonLabel: 'درد / ناراحتی',
        sessionDay: 'روز ۱',
      );
      expect(text.contains('اسکوات'), isTrue);
      expect(text.contains('روز ۱'), isTrue);
      expect(text.contains('جایگزین'), isTrue);
    });
  });
}
