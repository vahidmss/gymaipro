import 'dart:convert';

import 'package:gymaipro/ai/context/coach_conversation_summary.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_keys.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Local + Supabase store for rolling coach conversation summaries.
class ConversationSummaryRepository {
  ConversationSummaryRepository({
    SharedPreferences? preferences,
    SupabaseClient? client,
    this.enableRemoteSync = true,
  }) : _preferences = preferences,
       _clientOverride = client;

  final SharedPreferences? _preferences;
  final SupabaseClient? _clientOverride;
  final bool enableRemoteSync;
  static const _table = 'coach_conversation_summaries';

  SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return Supabase.instance.client;
    } on Object {
      return null;
    }
  }

  String? get _userId => _client?.auth.currentUser?.id;

  Future<CoachConversationSummary> loadSummary(String userId) async {
    final local = await _loadLocal(userId);
    if (local != null && !local.placeholder) return local;

    final remote = enableRemoteSync ? await _fetchRemote(userId) : null;
    if (remote != null) {
      await _saveLocal(userId, remote);
      return remote;
    }
    return local ?? CoachConversationSummary.empty;
  }

  Future<void> saveSummary(
    String userId,
    CoachConversationSummary summary,
  ) async {
    await _saveLocal(userId, summary);
    if (!enableRemoteSync) return;
    CoachPersistenceSync.run(
      'conversation_summary',
      () => _upsertRemote(userId, summary),
    );
  }

  Future<CoachConversationSummary?> _loadLocal(String userId) async {
    final prefs = await _prefs();
    final raw = prefs.getString(CoachPersistenceKeys.conversationSummary(userId));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<Object?, Object?>) return null;
      final map = decoded.map((key, value) => MapEntry(key.toString(), value));
      final summary = map['summary'] as String?;
      final messageCount = (map['messageCount'] as num?)?.toInt() ?? 0;
      final updatedAtRaw = map['lastUpdatedAt'] as String?;
      return CoachConversationSummary(
        summary: summary,
        messageCount: messageCount,
        lastUpdatedAt: updatedAtRaw == null
            ? null
            : DateTime.tryParse(updatedAtRaw),
        placeholder: summary == null || summary.trim().isEmpty,
      );
    } on Object {
      return null;
    }
  }

  Future<void> _saveLocal(
    String userId,
    CoachConversationSummary summary,
  ) async {
    final prefs = await _prefs();
    final payload = <String, Object?>{
      'summary': summary.summary,
      'messageCount': summary.messageCount,
      'lastUpdatedAt': summary.lastUpdatedAt?.toIso8601String(),
    };
    await prefs.setString(
      CoachPersistenceKeys.conversationSummary(userId),
      jsonEncode(payload),
    );
  }

  Future<CoachConversationSummary?> _fetchRemote(String userId) async {
    if (_client == null || _userId == null || _userId != userId) return null;

    final row = await _client!
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;

    final map = (row as Map<Object?, Object?>)
        .map((key, value) => MapEntry(key.toString(), value));
    final summary = map['summary'] as String?;
    final messageCount = (map['message_count'] as num?)?.toInt() ?? 0;
    final updatedAtRaw = map['updated_at'] as String?;
    return CoachConversationSummary(
      summary: summary,
      messageCount: messageCount,
      lastUpdatedAt: updatedAtRaw == null
          ? null
          : DateTime.tryParse(updatedAtRaw),
      placeholder: summary == null || summary.trim().isEmpty,
    );
  }

  Future<void> _upsertRemote(
    String userId,
    CoachConversationSummary summary,
  ) async {
    if (_client == null || _userId == null || _userId != userId) return;

    await _client!.from(_table).upsert(<String, Object?>{
      'user_id': userId,
      'summary': summary.summary,
      'message_count': summary.messageCount,
      'updated_at':
          (summary.lastUpdatedAt ?? DateTime.now()).toIso8601String(),
    });
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ?? SharedPreferences.getInstance();
  }
}
