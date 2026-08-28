import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/services/coach_chat_daily_limit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('daily quota is scoped per userId', () async {
    final service = CoachChatDailyLimitService();

    await service.recordSuccessfulReply(userId: 'user_a');
    await service.recordSuccessfulReply(userId: 'user_a');
    await service.recordSuccessfulReply(userId: 'user_b');

    final a = await service.load(userId: 'user_a');
    final b = await service.load(userId: 'user_b');

    expect(a.used, 2);
    expect(b.used, 1);
    expect(a.remaining, 8);
    expect(b.remaining, 9);
  });

  test('migrates legacy same-day global counter to user key', () async {
    final today = DateTime.now();
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues(<String, Object>{
      'ai_chat_daily_messages': 4,
      'ai_chat_last_reset_date': dateKey,
    });

    final service = CoachChatDailyLimitService();
    final snapshot = await service.load(userId: 'user_migrated');

    expect(snapshot.used, 4);
    expect(snapshot.remaining, 6);
  });
}
