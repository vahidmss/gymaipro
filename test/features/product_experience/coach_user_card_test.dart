import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';
import 'package:gymaipro/features/product_experience/domain/coach_user_card.dart';

void main() {
  final metadata = CoachContextMetadata(
    buildTime: DateTime(2026, 8, 13),
    sourceCount: 3,
    missingProviders: const {},
    confidence: 0.9,
    contextVersion: CoachContext.contextVersion,
  );

  test('builds identity, program, injury, and last session for engines', () {
    final card = CoachUserCard.fromContext(
      CoachContext(
        intent: AIIntent.generalChat,
        metadata: metadata,
        profile: const <String, Object?>{
          'first_name': 'وحید',
          'age': 34,
          'weight': 92,
        },
        goals: const <String>['حجم'],
        restrictions: const <String>['درد شانه'],
        activeProgram: const <String, Object?>{
          'name': 'شروع باشگاه',
          'focus': 'روز ۲',
        },
        memories: <CoachMemory>[
          CoachMemory(
            key: 'last_completed_workout',
            value: 'سینه: ۲ از ۳ ست روی ۴۰ — وزنه را زیاد نکن.',
            category: MemoryCategory.workout,
            confidence: 0.95,
            importance: MemoryImportance.high,
            source: MemorySource.user,
            createdAt: DateTime(2026, 8, 13),
            updatedAt: DateTime(2026, 8, 13),
            editable: true,
            userEditable: false,
            aiGenerated: false,
          ),
        ],
      ),
    );

    expect(card.sparse, isFalse);
    expect(card.identityLine, contains('وحید'));
    expect(card.identityLine, contains('92'));
    expect(card.constraintLine, contains('شانه'));
    expect(card.programLine, contains('شروع باشگاه'));
    expect(card.userFacingLines, isNot(contains(contains('incomplete'))));
    expect(card.promptText, contains('وزنه را زیاد نکن'));
  });

  test('sparse card still exists and forbids inventing facts', () {
    final card = CoachUserCard.fromContext(
      CoachContext(intent: AIIntent.generalChat, metadata: metadata),
    );

    expect(card.sparse, isTrue);
    expect(card.promptText, contains('حدس نزن'));
    expect(card.toPromptContent()['card_fa'], isNotEmpty);
  });

  test(
    'lock next-focus is for the model, not dumped as jargon to the user',
    () {
      final card = CoachUserCard.fromContext(
        CoachContext(
          intent: AIIntent.generalChat,
          metadata: metadata,
          profile: const <String, Object?>{'first_name': 'وحید'},
        ),
        decisionLock: <String, Object?>{
          'debrief': <String, Object?>{
            'next_focus': 'جلسه بعد اول همه ست‌ها را کامل کن؛ بعد وزنه.',
          },
          'decisions': <Object?>[
            <String, Object?>{'incomplete_volume': true},
          ],
        },
      );

      expect(card.nextFocusLine, contains('ست'));
      expect(card.userFacingLines.join(), isNot(contains('incomplete_volume')));
      expect(card.promptText, contains('تمرکز جلسه بعد'));
    },
  );
}
