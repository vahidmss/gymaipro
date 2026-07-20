/// SharedPreferences keys for coach v2 local persistence.
abstract final class CoachPersistenceKeys {
  static const memoryPrefix = 'gym_ai_coach_memory';
  static const statePrefix = 'gym_ai_coach_conversation_state';
  static const summaryPrefix = 'gym_ai_coach_conversation_summary';

  static String chatMessages(String userId) => 'coach_chat_messages_$userId';

  static String memories(String userId) => '$memoryPrefix.$userId';

  static String conversationStates(String userId) => '$statePrefix:$userId';

  static String conversationSummary(String userId) =>
      '$summaryPrefix.$userId';

  /// Prefixes cleared on logout (local cache only; cloud data remains).
  static const logoutPrefixes = <String>[
    memoryPrefix,
    statePrefix,
    summaryPrefix,
    'coach_chat_messages_',
    'recovery_score_',
    'last_workout_completed_at_',
    'ai_user_context_cache',
    'ai_chat_',
    'message_rate_limiter_',
    'ai_chat_daily_messages',
    'ai_chat_last_reset_date',
  ];
}
