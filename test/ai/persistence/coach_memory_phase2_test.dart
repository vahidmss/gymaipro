import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/entity/entity_type.dart';
import 'package:gymaipro/ai/integration/entity_memory_integration.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_fact_confirmation_service.dart';
import 'package:gymaipro/ai/memory/memory_manager.dart';
import 'package:gymaipro/ai/memory/memory_repository.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';
import 'package:gymaipro/ai/memory/memory_updater.dart';
import 'package:gymaipro/ai/persistence/conversation_summary_repository.dart';
import 'package:gymaipro/ai/persistence/conversation_summary_service.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConversationSummaryService', () {
    test('builds local summary after threshold', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const userId = 'summary_user';
      final service = ConversationSummaryService(
        repository: ConversationSummaryRepository(enableRemoteSync: false),
        messageThreshold: 3,
      );

      final messages = List<CoachChatMessage>.generate(4, (index) {
        final isUser = index.isEven;
        return CoachChatMessage(
          id: 'm$index',
          role: isUser
              ? CoachChatMessageRole.user
              : CoachChatMessageRole.coach,
          type: CoachChatMessageType.normal,
          text: isUser ? 'زانوم آسیب دیده' : 'تمرین را سبک‌تر می‌کنیم',
          createdAt: DateTime(2026, 7, 20, 12, index),
        );
      });

      final summary = await service.refreshIfNeeded(
        userId: userId,
        messages: messages,
        allowLlm: false,
      );

      expect(summary.placeholder, isFalse);
      expect(summary.messageCount, 4);
      expect(summary.summary, contains('زانوم آسیب دیده'));
    });
  });

  group('EntityMemoryIntegration sensitive gate', () {
    test('holds injury facts as pending confirmation', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const userId = 'injury_user';
      final memoryManager = MemoryManager(
        repository: MemoryRepository(enableRemoteSync: false),
      );
      final integration = EntityMemoryIntegration(
        memoryManager: memoryManager,
        confirmationService: MemoryFactConfirmationService(
          memoryManager: memoryManager,
        ),
      );

      final result = await integration.applyEntities(
        userId: userId,
        entities: <NormalizedEntity>[
          NormalizedEntity(
            type: EntityType.injury,
            value: 'knee_pain',
            confidence: 0.9,
            source: const EntityMatch(
              ruleId: 'keyword_injury',
              type: EntityType.injury,
              rawText: 'زانو درد',
              rawValue: 'knee_pain',
              score: 1,
              start: 0,
              end: 7,
            ),
          ),
        ],
      );

      expect(result.pendingConfirmations, isNotEmpty);
      expect(result.persistedCount, 0);
      expect(result.pendingConfirmations.first.originalKey, 'restrictions.injury');

      final pending = await MemoryFactConfirmationService(
        memoryManager: memoryManager,
      ).loadPending(userId);
      expect(pending, isNotEmpty);

      final resolution = await MemoryFactConfirmationService(
        memoryManager: memoryManager,
      ).tryResolveFromUserMessage(userId: userId, message: 'بله');

      expect(resolution?.confirmed, isTrue);
      final memories = await memoryManager.loadActiveMemories(userId);
      expect(
        memories.any((memory) => memory.key == 'restrictions.injury'),
        isTrue,
      );
      expect(
        memories.any((memory) => memory.key.startsWith('pending.confirm.')),
        isFalse,
      );
    });
  });

  group('MemoryFactConfirmationService prompts', () {
    test('builds persian confirmation prompt', () {
      final service = MemoryFactConfirmationService();
      final prompt = service.confirmationPrompt(
        const MemoryUpdateRequest(
          key: 'restrictions.injury',
          value: 'knee_pain',
          category: MemoryCategory.restriction,
          source: MemorySource.inference,
        ),
      );
      expect(prompt, contains('بله'));
      expect(prompt, contains('knee_pain'));
    });
  });
}
