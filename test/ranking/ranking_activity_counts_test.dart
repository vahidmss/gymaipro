import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ranking/utils/ranking_activity_counts.dart';

void main() {
  group('RankingActivityCounts.countLoggedMeals', () {
    test('ignores empty meal shells and counts only meals with foods', () {
      final rows = [
        {
          'meals': [
            {
              'title': 'صبحانه',
              'foods': [
                {'food_id': 1, 'amount': 100},
              ],
            },
            {'title': 'ناهار', 'foods': <Map<String, dynamic>>[]},
            {'title': 'شام', 'foods': <Map<String, dynamic>>[]},
            {'title': 'میان‌وعده 1', 'foods': <Map<String, dynamic>>[]},
            {'title': 'میان‌وعده 2', 'foods': <Map<String, dynamic>>[]},
            {'title': 'میان‌وعده 3', 'foods': <Map<String, dynamic>>[]},
          ],
        },
        {
          'meals': [
            {
              'title': 'صبحانه',
              'foods': [
                {'food_id': 2, 'amount': 50},
              ],
            },
            {
              'title': 'ناهار',
              'foods': [
                {'food_id': 3, 'amount': 80},
              ],
            },
            {'title': 'شام', 'foods': <Map<String, dynamic>>[]},
          ],
        },
      ];

      // قبلاً: ۱ روز×۶ + ۱ روز×۳ = ۹ پوچ+واقعی؛ حالا فقط ۳ وعدهٔ واقعی
      expect(RankingActivityCounts.countLoggedMeals(rows), 3);
    });

    test('six empty shells per day do not inflate to 36', () {
      final rows = List.generate(
        6,
        (_) => {
          'meals': [
            {'title': 'صبحانه', 'foods': <dynamic>[]},
            {'title': 'میان‌وعده 1', 'foods': <dynamic>[]},
            {'title': 'ناهار', 'foods': <dynamic>[]},
            {'title': 'میان‌وعده 2', 'foods': <dynamic>[]},
            {'title': 'شام', 'foods': <dynamic>[]},
            {'title': 'میان‌وعده 3', 'foods': <dynamic>[]},
          ],
        },
      );

      expect(RankingActivityCounts.countLoggedMeals(rows), 0);
    });
  });

  group('RankingActivityCounts.countMeaningfulWorkoutSessions', () {
    test('skips sessions without meaningful sets', () {
      final rows = [
        {
          'id': 'd1',
          'user_id': 'u1',
          'log_date': '2026-08-01',
          'created_at': '2026-08-01T10:00:00.000Z',
          'updated_at': '2026-08-01T10:00:00.000Z',
          'sessions': [
            {
              'id': 's1',
              'day': 'روز ۱',
              'exercises': [
                {
                  'id': 'e1',
                  'type': 'normal',
                  'exercise_id': 10,
                  'exercise_name': 'Bench',
                  'tag': '',
                  'style': 'sets_reps',
                  'sets': [
                    {'reps': 0, 'weight': 0},
                  ],
                },
              ],
            },
            {
              'id': 's2',
              'day': 'روز ۲',
              'exercises': [
                {
                  'id': 'e2',
                  'type': 'normal',
                  'exercise_id': 11,
                  'exercise_name': 'Squat',
                  'tag': '',
                  'style': 'sets_reps',
                  'sets': [
                    {'reps': 5, 'weight': 60},
                  ],
                },
              ],
            },
          ],
        },
      ];

      expect(
        RankingActivityCounts.countMeaningfulWorkoutSessions(rows),
        1,
      );
    });
  });
}
