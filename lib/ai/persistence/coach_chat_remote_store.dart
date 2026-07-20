import 'dart:convert';

import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase persistence for coach chat messages.
class CoachChatRemoteStore {
  CoachChatRemoteStore({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;
  static const _table = 'coach_chat_messages';

  SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return Supabase.instance.client;
    } on Object {
      return null;
    }
  }

  String? get _userId => _client?.auth.currentUser?.id;

  Future<List<CoachChatMessage>> fetchMessages(
    String userId, {
    int limit = 200,
  }) async {
    if (_client == null || _userId == null || _userId != userId) {
      return const <CoachChatMessage>[];
    }

    final rows = await _client!
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .limit(limit);

    return (rows as List<Object?>)
        .map(_messageFromRow)
        .whereType<CoachChatMessage>()
        .toList(growable: false);
  }

  Future<void> upsertMessages(
    String userId,
    List<CoachChatMessage> messages,
  ) async {
    if (_client == null || _userId == null || _userId != userId || messages.isEmpty) {
      return;
    }

    final payload = messages
        .map((message) => _messageToRow(userId, message))
        .toList(growable: false);
    await _client!.from(_table).upsert(payload, onConflict: 'user_id,id');
  }

  Map<String, Object?> _messageToRow(String userId, CoachChatMessage message) {
    return <String, Object?>{
      'id': message.id,
      'user_id': userId,
      'role': message.role.name,
      'message_type': message.type.name,
      'content': message.text,
      'cards': message.cards
          .map(
            (card) => <String, Object?>{
              'type': card.type.name,
              'title': card.title,
              'items': card.items,
            },
          )
          .toList(growable: false),
      'created_at': message.createdAt.toIso8601String(),
    };
  }

  CoachChatMessage? _messageFromRow(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;
    final map = raw.map((key, value) => MapEntry(key.toString(), value));

    final id = map['id']?.toString();
    final roleName = map['role']?.toString();
    final typeName = map['message_type']?.toString();
    final text = map['content']?.toString();
    final createdAtRaw = map['created_at']?.toString();
    if (id == null ||
        roleName == null ||
        typeName == null ||
        text == null ||
        createdAtRaw == null) {
      return null;
    }

    final role = CoachChatMessageRole.values.asNameMap()[roleName];
    final type = CoachChatMessageType.values.asNameMap()[typeName];
    final createdAt = DateTime.tryParse(createdAtRaw);
    if (role == null || type == null || createdAt == null) return null;

    final cardsRaw = map['cards'];
    final cards = <CoachChatMessageCard>[];
    if (cardsRaw is List<Object?>) {
      for (final entry in cardsRaw) {
        final card = _cardFromJson(entry);
        if (card != null) cards.add(card);
      }
    } else if (cardsRaw is String && cardsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(cardsRaw);
        if (decoded is List<Object?>) {
          for (final entry in decoded) {
            final card = _cardFromJson(entry);
            if (card != null) cards.add(card);
          }
        }
      } on Object {
        // Ignore malformed card payloads.
      }
    }

    return CoachChatMessage(
      id: id,
      role: role,
      type: type,
      text: text,
      createdAt: createdAt,
      cards: cards,
    );
  }

  CoachChatMessageCard? _cardFromJson(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final typeName = map['type']?.toString();
    final title = map['title']?.toString();
    final itemsRaw = map['items'];
    if (typeName == null || title == null || itemsRaw is! List<Object?>) {
      return null;
    }
    final type = CoachChatCardType.values.asNameMap()[typeName];
    if (type == null) return null;
    return CoachChatMessageCard(
      type: type,
      title: title,
      items: itemsRaw.map((item) => item.toString()).toList(growable: false),
    );
  }
}
