import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/profile_age_resolver.dart';
import 'package:gymaipro/ai/workout/equipment/workout_equipment_tokens.dart';

void main() {
  group('WorkoutEquipmentTokens', () {
    test('expands full gym preset to matcher tokens', () {
      final tokens = WorkoutEquipmentTokens.expand(const <String>['باشگاه کامل']);
      expect(tokens, contains('هالتر'));
      expect(tokens, contains('دمبل'));
      expect(tokens, contains('دستگاه'));
      expect(tokens, contains('کابل'));
      expect(tokens, contains('بدون تجهیزات'));
    });

    test('expands bodyweight preset', () {
      final tokens = WorkoutEquipmentTokens.expand(
        const <String>['فقط وزن بدن'],
      );
      expect(tokens, contains('بدون'));
      expect(tokens, contains('وزن بدن'));
      expect(tokens, contains('بدون تجهیزات'));
    });

    test('expands home dumbbell preset', () {
      final tokens = WorkoutEquipmentTokens.expand(
        const <String>['دمبل در خانه'],
      );
      expect(tokens, contains('دمبل'));
      expect(tokens, contains('خانه'));
      expect(tokens, contains('بدون تجهیزات'));
    });
  });

  group('ProfileAgeResolver', () {
    test('derives age from birth_date', () {
      final now = DateTime.now();
      final birth = DateTime(now.year - 28, now.month, now.day);
      final age = ProfileAgeResolver.resolve(<String, Object?>{
        'birth_date': birth.toIso8601String(),
      });
      expect(age, 28);
    });

    test('prefers explicit age when present', () {
      final age = ProfileAgeResolver.resolve(const <String, Object?>{
        'age': 31,
        'birth_date': '1990-01-01',
      });
      expect(age, 31);
    });
  });
}
