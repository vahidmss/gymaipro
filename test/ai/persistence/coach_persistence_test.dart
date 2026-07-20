import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_conversation_summary.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_clear_service.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_keys.dart';
import 'package:gymaipro/ai/persistence/conversation_summary_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConversationSummaryRepository', () {
    test('round-trips summary locally', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const userId = 'user_summary';
      final repository = ConversationSummaryRepository(enableRemoteSync: false);
      const summary = CoachConversationSummary(
        summary: 'کاربر روی ریکاوری زانو تاکید دارد.',
        messageCount: 12,
        lastUpdatedAt: null,
        placeholder: false,
      );

      await repository.saveSummary(userId, summary);
      final loaded = await repository.loadSummary(userId);

      expect(loaded.summary, summary.summary);
      expect(loaded.messageCount, 12);
      expect(loaded.placeholder, isFalse);
    });
  });

  group('CoachPersistenceClearService', () {
    test('clears coach local keys on logout', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        CoachPersistenceKeys.chatMessages('u1'): '[]',
        CoachPersistenceKeys.memories('u1'): '[]',
        CoachPersistenceKeys.conversationSummary('u1'): '{}',
        'unrelated_key': 'keep',
      });

      await CoachPersistenceClearService.clearLocalCoachData();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(CoachPersistenceKeys.chatMessages('u1')), isFalse);
      expect(prefs.containsKey('unrelated_key'), isTrue);
    });
  });
}
