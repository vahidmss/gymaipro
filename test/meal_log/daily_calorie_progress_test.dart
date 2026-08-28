import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/meal_log/widgets/daily_calorie_summary.dart';

void main() {
  group('DailyCalorieSummary.computeProgress', () {
    test('empty day is zero', () {
      final m = DailyCalorieSummary.computeProgress(consumed: 0, target: 2000);
      expect(m.percentage, 0);
      expect(m.barFill, 0);
      expect(m.isOver, isFalse);
      expect(m.remainingAbs, 2000);
    });

    test('half way shows 50%', () {
      final m = DailyCalorieSummary.computeProgress(
        consumed: 1100,
        target: 2200,
      );
      expect(m.percentage, 50);
      expect(m.barFill, 0.5);
      expect(m.isOver, isFalse);
      expect(m.remainingAbs, 1100);
    });

    test('exactly at target is 100% not over', () {
      final m = DailyCalorieSummary.computeProgress(
        consumed: 2200,
        target: 2200,
      );
      expect(m.percentage, 100);
      expect(m.barFill, 1.0);
      expect(m.isOver, isFalse);
      expect(m.remainingAbs, 0);
    });

    test('over target shows real percent above 100 and full bar', () {
      final m = DailyCalorieSummary.computeProgress(
        consumed: 2640,
        target: 2200,
      );
      expect(m.percentage, 120);
      expect(m.barFill, 1.0);
      expect(m.isOver, isTrue);
      expect(m.remainingAbs, 440);
      expect(m.ratio, closeTo(1.2, 0.001));
    });

    test('invalid target stays safe', () {
      final m = DailyCalorieSummary.computeProgress(consumed: 500, target: 0);
      expect(m.percentage, 0);
      expect(m.isOver, isFalse);
    });
  });
}
