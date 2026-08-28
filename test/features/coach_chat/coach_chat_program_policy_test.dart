import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_program_policy.dart';

void main() {
  group('CoachChatProgramPolicy.looksLikeProgramRequest', () {
    test('blocks explicit build requests', () {
      const blocked = <String>[
        'برای من یک برنامه تمرینی بساز',
        'رژیم بده',
        'یه برنامه غذایی برام بنویس',
        'برنامه بساز',
        'رژیم میخوام',
        'make me a program',
      ];
      for (final message in blocked) {
        expect(
          CoachChatProgramPolicy.looksLikeProgramRequest(message),
          isTrue,
          reason: 'باید بلاک شود: $message',
        );
      }
    });

    test('allows consultative questions about diet and programs', () {
      const allowed = <String>[
        'به نظرت من رژیم میخوام؟',
        'به نظر تو من به رژیم نیاز دارم؟',
        'فکر میکنی برنامه‌ام خوبه؟',
        'آیا من رژیم لازم دارم؟',
        'رژیم کتوژنیک چیه؟',
        'برای عضله‌سازی پروتئین چقدر بخورم؟',
        'برنامه‌ی فعلی‌م چطوره؟',
      ];
      for (final message in allowed) {
        expect(
          CoachChatProgramPolicy.looksLikeProgramRequest(message),
          isFalse,
          reason: 'نباید بلاک شود: $message',
        );
      }
    });
  });
}
