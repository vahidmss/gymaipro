import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_profile_metrics.dart';

void main() {
  group('CoachProfileMetrics', () {
    test('computes BMI and overweight verdict from height/weight', () {
      final profile = <String, Object?>{
        'height': 175,
        'weight': 90,
      };

      CoachProfileMetrics.enrich(profile);

      expect(profile['bmi'], 29.4);
      expect(profile['bmi_category'], 'اضافه وزن');
      expect(
        profile['bmi_verdict']?.toString(),
        contains('اضافه وزن'),
      );
      expect(
        profile['body_metrics_summary_fa']?.toString(),
        contains('قد 175'),
      );
    });

    test('reads questionnaire aliases', () {
      final profile = <String, Object?>{
        'bb_height_cm': 160,
        'bb_weight_kg': 50,
      };

      CoachProfileMetrics.enrich(profile);

      expect(profile['height'], 160);
      expect(profile['weight'], 50);
      expect(profile['bmi_category'], 'محدودهٔ طبیعی');
      expect(
        profile['bmi_verdict']?.toString(),
        contains('اضافه وزن نداری'),
      );
    });

    test('underweight verdict', () {
      final profile = <String, Object?>{
        'height_cm': 170,
        'weight_kg': 48,
      };

      CoachProfileMetrics.enrich(profile);

      expect(profile['bmi_category'], 'کمبود وزن');
      expect(
        profile['bmi_verdict']?.toString(),
        contains('کمبود وزن'),
      );
    });
  });
}
