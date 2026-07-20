import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/product_experience/form_guidance/form_exercise_guidance.dart';
import 'package:gymaipro/features/product_experience/navigation/form_guidance_navigation.dart';

void main() {
  group('FormExerciseGuidance', () {
    test('prefers catalog tips over program note', () {
      const item = FormExerciseGuidance(
        name: 'اسکوات',
        tips: <String>['زانو را هم‌راستا با پنجه نگه دار'],
        programNote: 'یادداشت برنامه',
      );

      expect(item.hasLocalTips, isTrue);
      expect(item.displayTips, hasLength(1));
      expect(item.displayTips.first, contains('زانو'));
      expect(item.askCoachPrompt, contains('اسکوات'));
    });

    test('falls back to short program note when tips empty', () {
      const item = FormExerciseGuidance(
        name: 'ددلیفت',
        tips: <String>[],
        programNote: 'کمر را صاف نگه دار',
      );

      expect(item.hasLocalTips, isFalse);
      expect(item.displayTips, equals(<String>['کمر را صاف نگه دار']));
    });

    test('empty tips and long note yields empty display', () {
      const item = FormExerciseGuidance(
        name: 'پرس سینه',
        tips: <String>[],
        programNote:
            'این یادداشت خیلی طولانی است و نباید به‌عنوان نکته فرم کوتاه استفاده شود '
            'چون بیشتر از حد مجاز برای نمایش جایگزین است و باید کاربر را به مربی بفرستد '
            'تا تکنیک کامل حرکت را با جزئیات ایمنی و اشتباهات رایج توضیح دهد.',
      );

      expect(item.programNote!.length > 180, isTrue);
      expect(item.displayTips, isEmpty);
    });
  });

  test('FormGuidanceNavigation recognizes form actions', () {
    expect(FormGuidanceNavigation.isFormAction('form'), isTrue);
    expect(FormGuidanceNavigation.isFormAction('ask_form'), isTrue);
    expect(FormGuidanceNavigation.isFormAction('recovery'), isFalse);
  });
}
