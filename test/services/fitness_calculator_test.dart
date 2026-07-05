import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/services/fitness_calculator.dart';

/// تست مسیر حیاتی: محاسبات سلامتی (BMI/BMR/TDEE/چربی بدن)
/// این مقادیر مستقیماً به کاربر نمایش داده می‌شوند، پس باید دقیق بمانند.
void main() {
  group('FitnessCalculator.calculateBMI', () {
    test('محاسبه صحیح BMI برای مقادیر معمول', () {
      // 70kg, 175cm => 22.857...
      expect(
        FitnessCalculator.calculateBMI(70, 175),
        closeTo(22.86, 0.01),
      );
    });

    test('قد به متر تبدیل می‌شود (نه سانتی‌متر)', () {
      // اگر تبدیل سانتی‌متر انجام نشود عدد کاملاً غلط می‌شود
      final bmi = FitnessCalculator.calculateBMI(80, 180);
      expect(bmi, closeTo(24.69, 0.01));
    });
  });

  group('FitnessCalculator.getBMICategory', () {
    test('کم‌وزن زیر 18.5', () {
      expect(FitnessCalculator.getBMICategory(17), 'Underweight');
    });

    test('نرمال بین 18.5 و 25', () {
      expect(FitnessCalculator.getBMICategory(22), 'Normal');
    });

    test('اضافه‌وزن بین 25 و 30', () {
      expect(FitnessCalculator.getBMICategory(27), 'Overweight');
    });

    test('چاق 30 به بالا', () {
      expect(FitnessCalculator.getBMICategory(32), 'Obese');
    });

    test('مرزها: دقیقاً 18.5 نرمال و دقیقاً 25 اضافه‌وزن', () {
      expect(FitnessCalculator.getBMICategory(18.5), 'Normal');
      expect(FitnessCalculator.getBMICategory(25), 'Overweight');
      expect(FitnessCalculator.getBMICategory(30), 'Obese');
    });
  });

  group('FitnessCalculator.calculateBMR', () {
    test('فرمول Harris-Benedict برای مرد', () {
      // 88.362 + 13.397*70 + 4.799*175 - 5.677*30
      expect(
        FitnessCalculator.calculateBMR(70, 175, 30, true),
        closeTo(1695.67, 0.5),
      );
    });

    test('فرمول Harris-Benedict برای زن', () {
      // 447.593 + 9.247*60 + 3.098*165 - 4.330*30 = 1383.683
      expect(
        FitnessCalculator.calculateBMR(60, 165, 30, false),
        closeTo(1383.68, 0.5),
      );
    });

    test('BMR مرد بیشتر از زن با همان مشخصات است', () {
      final male = FitnessCalculator.calculateBMR(70, 175, 30, true);
      final female = FitnessCalculator.calculateBMR(70, 175, 30, false);
      expect(male, greaterThan(female));
    });
  });

  group('FitnessCalculator.calculateTDEE', () {
    const bmr = 1500.0;

    test('ضرایب سطح فعالیت درست اعمال می‌شوند', () {
      expect(
        FitnessCalculator.calculateTDEE(bmr, ActivityLevel.sedentary),
        closeTo(1800, 0.01),
      );
      expect(
        FitnessCalculator.calculateTDEE(bmr, ActivityLevel.lightlyActive),
        closeTo(2062.5, 0.01),
      );
      expect(
        FitnessCalculator.calculateTDEE(bmr, ActivityLevel.moderatelyActive),
        closeTo(2325, 0.01),
      );
      expect(
        FitnessCalculator.calculateTDEE(bmr, ActivityLevel.veryActive),
        closeTo(2587.5, 0.01),
      );
      expect(
        FitnessCalculator.calculateTDEE(bmr, ActivityLevel.extraActive),
        closeTo(2850, 0.01),
      );
    });

    test('TDEE با افزایش فعالیت صعودی است', () {
      final levels = [
        ActivityLevel.sedentary,
        ActivityLevel.lightlyActive,
        ActivityLevel.moderatelyActive,
        ActivityLevel.veryActive,
        ActivityLevel.extraActive,
      ];
      for (var i = 1; i < levels.length; i++) {
        expect(
          FitnessCalculator.calculateTDEE(bmr, levels[i]),
          greaterThan(FitnessCalculator.calculateTDEE(bmr, levels[i - 1])),
        );
      }
    });
  });

  group('FitnessCalculator.calculateBodyFatPercentage', () {
    test('برای مرد مقدار مثبت منطقی برمی‌گرداند', () {
      final bf = FitnessCalculator.calculateBodyFatPercentage(
        90, // waist
        40, // neck
        180, // height
        true,
        null,
      );
      expect(bf, greaterThan(0));
      expect(bf, lessThan(60));
    });

    test('برای زن بدون اندازه باسن مقدار 0 برمی‌گرداند', () {
      final bf = FitnessCalculator.calculateBodyFatPercentage(
        75,
        32,
        165,
        false,
        null,
      );
      expect(bf, 0);
    });

    test('برای زن با اندازه باسن مقدار مثبت برمی‌گرداند', () {
      final bf = FitnessCalculator.calculateBodyFatPercentage(
        75,
        32,
        165,
        false,
        100,
      );
      expect(bf, greaterThan(0));
    });
  });

  group('ActivityLevelConverter.toActivityLevel', () {
    test('نگاشت رشته‌های دیتابیس به enum', () {
      expect('sedentary'.toActivityLevel(), ActivityLevel.sedentary);
      expect('light'.toActivityLevel(), ActivityLevel.lightlyActive);
      expect('moderate'.toActivityLevel(), ActivityLevel.moderatelyActive);
      expect('active'.toActivityLevel(), ActivityLevel.veryActive);
      expect('very_active'.toActivityLevel(), ActivityLevel.extraActive);
    });

    test('مقدار ناشناخته به پیش‌فرض moderatelyActive می‌رود', () {
      expect(''.toActivityLevel(), ActivityLevel.moderatelyActive);
      expect('garbage'.toActivityLevel(), ActivityLevel.moderatelyActive);
    });
  });
}
