import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/workout_plan_builder/utils/workout_program_name_uniquifier.dart';

void main() {
  final now = DateTime(2026, 7, 17);

  test('keeps base name when free', () {
    expect(
      ensureUniqueWorkoutProgramName(
        'چربی‌سوز ۳روزه باشگاهی',
        const <String>[],
        now: now,
      ),
      'چربی‌سوز ۳روزه باشگاهی',
    );
  });

  test('appends date when base taken', () {
    expect(
      ensureUniqueWorkoutProgramName(
        'چربی‌سوز ۳روزه باشگاهی',
        const <String>['چربی‌سوز ۳روزه باشگاهی'],
        now: now,
      ),
      'چربی‌سوز ۳روزه باشگاهی (7/17)',
    );
  });

  test('appends counter when dated name also taken', () {
    expect(
      ensureUniqueWorkoutProgramName(
        'چربی‌سوز ۳روزه باشگاهی',
        const <String>[
          'چربی‌سوز ۳روزه باشگاهی',
          'چربی‌سوز ۳روزه باشگاهی (7/17)',
        ],
        now: now,
      ),
      'چربی‌سوز ۳روزه باشگاهی (7/17 #2)',
    );
  });

  test('increments counter past existing numbered names', () {
    expect(
      ensureUniqueWorkoutProgramName(
        'چربی‌سوز ۳روزه باشگاهی',
        const <String>[
          'چربی‌سوز ۳روزه باشگاهی',
          'چربی‌سوز ۳روزه باشگاهی (7/17)',
          'چربی‌سوز ۳روزه باشگاهی (7/17 #2)',
        ],
        now: now,
      ),
      'چربی‌سوز ۳روزه باشگاهی (7/17 #3)',
    );
  });
}
