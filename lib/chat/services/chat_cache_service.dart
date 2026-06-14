import 'dart:async';
import 'dart:convert';

import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// کش لایه‌ای چت خصوصی: حافظه + دیسک (SharedPreferences).
/// stale-while-revalidate برای لیست گفتگوها و پیام‌های هر thread.
class ChatCacheService {
  factory ChatCacheService() => _instance;
  ChatCacheService._internal();
  static final ChatCacheService _instance = ChatCacheService._internal();

  static final Map<String, List<ChatMessage>> _messageMemory = {};
  static final Map<String, List<ChatConversation>> _conversationMemory = {};

  static const String _conversationsPrefix = 'chat_cache_conversations_';
  static const String _messagesPrefix = 'chat_cache_messages_';
  static const String _unreadPrefix = 'chat_cache_unread_';
  static const String _conversationsTsPrefix = 'chat_cache_conversations_ts_';

  String? _currentUserId() =>
      Supabase.instance.client.auth.currentUser?.id;

  String _messagesKey(String userId, String otherUserId) =>
      '$_messagesPrefix${userId}_$otherUserId';

  // ── Messages (memory) ──────────────────────────────────────────────

  List<ChatMessage> getMessagesMemory(String otherUserId) {
    final userId = _currentUserId();
    if (userId == null) return const [];
    return List<ChatMessage>.from(
      _messageMemory[_messagesKey(userId, otherUserId)] ?? const [],
    );
  }

  void setMessagesMemory(String otherUserId, List<ChatMessage> messages) {
    final userId = _currentUserId();
    if (userId == null) return;
    _messageMemory[_messagesKey(userId, otherUserId)] =
        List<ChatMessage>.from(messages);
  }

  Future<void> persistMessages(
    String otherUserId,
    List<ChatMessage> messages,
  ) async {
    final userId = _currentUserId();
    if (userId == null) return;
    setMessagesMemory(otherUserId, messages);
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
      await prefs.setString(_messagesKey(userId, otherUserId), encoded);
    } catch (_) {}
  }

  Future<List<ChatMessage>> loadMessagesDisk(String otherUserId) async {
    final userId = _currentUserId();
    if (userId == null) return const [];
    final mem = getMessagesMemory(otherUserId);
    if (mem.isNotEmpty) return mem;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_messagesKey(userId, otherUserId));
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw) as List<dynamic>;
      final messages = list
          .cast<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      setMessagesMemory(otherUserId, messages);
      return messages;
    } catch (_) {
      return const [];
    }
  }

  // ── Conversations (memory + disk) ──────────────────────────────────

  List<ChatConversation> getConversationsMemory() {
    final userId = _currentUserId();
    if (userId == null) return const [];
    return List<ChatConversation>.from(
      _conversationMemory[userId] ?? const [],
    );
  }

  void setConversationsMemory(List<ChatConversation> conversations) {
    final userId = _currentUserId();
    if (userId == null) return;
    _conversationMemory[userId] = List<ChatConversation>.from(conversations);
  }

  Future<void> persistConversations(
    List<ChatConversation> conversations,
  ) async {
    final userId = _currentUserId();
    if (userId == null) return;
    setConversationsMemory(conversations);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_conversationsPrefix$userId',
        jsonEncode(conversations.map((c) => c.toJson()).toList()),
      );
      await prefs.setString(
        '$_conversationsTsPrefix$userId',
        DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  Future<List<ChatConversation>> loadConversationsDisk() async {
    final userId = _currentUserId();
    if (userId == null) return const [];
    final mem = getConversationsMemory();
    if (mem.isNotEmpty) return mem;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_conversationsPrefix$userId');
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw) as List<dynamic>;
      final conversations = list
          .cast<Map<String, dynamic>>()
          .map(ChatConversation.fromJson)
          .toList();
      setConversationsMemory(conversations);
      return conversations;
    } catch (_) {
      return const [];
    }
  }

  DateTime? conversationsCacheTime() {
    final userId = _currentUserId();
    if (userId == null) return null;
    // sync read not ideal but acceptable for UI hint
    return null;
  }

  // ── Unread badge (offline) ─────────────────────────────────────────

  Future<void> persistUnreadCount(int count) async {
    final userId = _currentUserId();
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_unreadPrefix$userId', count);
    } catch (_) {}
  }

  Future<int> loadUnreadCount() async {
    final userId = _currentUserId();
    if (userId == null) return 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_unreadPrefix$userId') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ── Invalidation ───────────────────────────────────────────────────

  void invalidateMessages(String otherUserId) {
    final userId = _currentUserId();
    if (userId == null) return;
    _messageMemory.remove(_messagesKey(userId, otherUserId));
  }

  void patchConversation(ChatConversation conversation) {
    final userId = _currentUserId();
    if (userId == null) return;
    final list = List<ChatConversation>.from(
      _conversationMemory[userId] ?? const [],
    );
    final idx = list.indexWhere((c) => c.id == conversation.id);
    if (idx >= 0) {
      list[idx] = conversation;
    } else {
      list.insert(0, conversation);
    }
    list.sort(
      (a, b) => b.lastMessageDateTime.compareTo(a.lastMessageDateTime),
    );
    _conversationMemory[userId] = list;
    unawaited(persistConversations(list));
  }

  Future<void> clearAllForCurrentUser() async {
    final userId = _currentUserId();
    if (userId == null) return;
    _messageMemory.removeWhere((k, _) => k.contains(userId));
    _conversationMemory.remove(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (k) =>
            k == '$_conversationsPrefix$userId' ||
            k == '$_conversationsTsPrefix$userId' ||
            k == '$_unreadPrefix$userId' ||
            k.startsWith('$_messagesPrefix${userId}_') ||
            k.startsWith('avatar_url_'),
      );
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  static void clearAllMemory() {
    _messageMemory.clear();
    _conversationMemory.clear();
  }
}
