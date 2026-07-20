import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_split_strategy.dart';
import 'package:gymaipro/ai/workout/labels/workout_session_labels.dart';

void main() {
  group('WorkoutSessionLabels', () {
    test('4-day labels are unique and upper/lower serialised', () {
      final labels = WorkoutSessionLabels.forDaysPerWeek(4);
      expect(labels.length, 4);
      expect(labels.toSet().length, 4);
      expect(labels[0], 'روز ۱ — بالاتنه ۱');
      expect(labels[1], 'روز ۲ — پایین‌تنه ۱');
      expect(labels[2], 'روز ۳ — بالاتنه ۲');
      expect(labels[3], 'روز ۴ — پایین‌تنه ۲');
    });

    test('3-day PPL labels stay unique without serial when not repeated', () {
      final labels = WorkoutSessionLabels.forDaysPerWeek(3);
      expect(labels, <String>[
        'روز ۱ — فشار',
        'روز ۲ — کشش',
        'روز ۳ — پا',
      ]);
      expect(labels.toSet().length, 3);
    });

    test('normalizes duplicate LLM "فشار" names', () {
      final fixed = WorkoutSessionLabels.normalizeParsed(const <String>[
        'فشار',
        'کشش',
        'پا',
        'فشار',
      ]);
      expect(fixed.toSet().length, 4);
      expect(fixed[0], contains('فشار ۱'));
      expect(fixed[3], contains('فشار ۲'));
      expect(fixed[0], isNot(equals(fixed[3])));
    });

    test('pushPullLegs strategy never emits identical raw labels', () {
      final labels = WorkoutSessionLabels.forStrategy(
        WorkoutSplitStrategy.pushPullLegs,
        4,
      );
      expect(labels.toSet().length, 4);
      expect(WorkoutSessionLabels.hasDuplicateLabels(labels), isFalse);
    });

    test('WorkoutScience.dayLabels delegates to unique labels', () {
      final labels = WorkoutScience.dayLabels(4);
      expect(labels.toSet().length, 4);
    });
  });
}
