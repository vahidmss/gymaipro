import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/exercise/ai_exercise_muscle_normalizer.dart';

void main() {
  test('bench and OHP are not triceps', () {
    expect(
      AiExerciseMuscleNormalizer.inferMainMuscle('پرس سینه با هالتر'),
      'chest',
    );
    expect(
      AiExerciseMuscleNormalizer.inferMainMuscle('پرس سینه با دمبل'),
      'chest',
    );
    expect(
      AiExerciseMuscleNormalizer.inferMainMuscle('پرس سرشانه با هالتر'),
      'shoulder_anterior',
    );
  });

  test('resolve overrides poisoned stored tags', () {
    expect(
      AiExerciseMuscleNormalizer.resolveMainMuscle(
        name: 'پرس سینه با هالتر',
        storedMainMuscle: 'triceps',
      ),
      'chest',
    );
    expect(
      AiExerciseMuscleNormalizer.resolveMainMuscle(
        name: 'جلو بازو هالتر',
        storedMainMuscle: 'back_lat',
      ),
      'biceps',
    );
    expect(
      AiExerciseMuscleNormalizer.resolveMainMuscle(
        name: 'هیپ تراست',
        storedMainMuscle: 'back_lat',
      ),
      'glutes',
    );
  });

  test('keeps compatible stored tags', () {
    expect(
      AiExerciseMuscleNormalizer.resolveMainMuscle(
        name: 'پرس سینه اسمیت',
        storedMainMuscle: 'chest',
      ),
      'chest',
    );
  });
}
