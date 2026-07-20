import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_navigation.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

void main() {
  group('ProgramModifyNavigation.isModifyAction', () {
    test('unifies modify and replace ids', () {
      expect(ProgramModifyNavigation.isModifyAction('modify'), isTrue);
      expect(ProgramModifyNavigation.isModifyAction('modify_program'), isTrue);
      expect(ProgramModifyNavigation.isModifyAction('modify_workout'), isTrue);
      expect(ProgramModifyNavigation.isModifyAction('replace'), isTrue);
      expect(ProgramModifyNavigation.isModifyAction('replace_exercise'), isTrue);
      expect(ProgramModifyNavigation.isModifyAction('ask_coach'), isFalse);
      expect(ProgramModifyNavigation.isModifyAction(null), isFalse);
    });
  });

  group('ProductExperienceFormatter modify labels', () {
    test('replace uses اصلاح برنامه label', () {
      expect(
        ProductExperienceFormatter.quickActionLabel('replace_exercise', 'x'),
        'اصلاح برنامه',
      );
      expect(
        ProductExperienceFormatter.quickActionLabel('modify_program', 'x'),
        'اصلاح برنامه',
      );
    });
  });
}
