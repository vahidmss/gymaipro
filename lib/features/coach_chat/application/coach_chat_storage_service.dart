import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/persistence/coach_chat_remote_store.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_keys.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_sync.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for coach chat conversations (per authenticated user).
class CoachChatStorageService {
  CoachChatStorageService({
    SharedPreferences? preferences,
    CoachChatRemoteStore? remoteStore,
    this.enableRemoteSync = true,
  }) : _preferences = preferences,
       _remoteStore = enableRemoteSync
           ? (remoteStore ?? CoachChatRemoteStore())
           : null;

  SharedPreferences? _preferences;
  final CoachChatRemoteStore? _remoteStore;
  final bool enableRemoteSync;

  static String messagesKey(String userId) =>
      CoachPersistenceKeys.chatMessages(userId);

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<List<CoachChatMessage>> loadMessages(String userId) async {
    if (userId.isEmpty) return const <CoachChatMessage>[];

    final local = await _loadLocalMessages(userId);
    if (!enableRemoteSync || _remoteStore == null) return local;

    try {
      final remote = await _remoteStore.fetchMessages(userId);
      if (remote.isEmpty) {
        if (local.isNotEmpty) {
          CoachPersistenceSync.run(
            'chat_bootstrap',
            () => _remoteStore!.upsertMessages(userId, local),
          );
        }
        return local;
      }

      final merged = _mergeMessages(local, remote);
      await _saveLocalMessages(userId, merged);
      return merged;
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[CoachChatStorage] remote load failed: $error');
      }
      return local;
    }
  }

  Future<void> saveMessages(
    String userId,
    List<CoachChatMessage> messages,
  ) async {
    if (userId.isEmpty) return;

    await _saveLocalMessages(userId, messages);
    if (enableRemoteSync && _remoteStore != null) {
      CoachPersistenceSync.run(
        'chat_upsert',
        () => _remoteStore!.upsertMessages(userId, messages),
      );
    }
  }

  Future<void> clearMessages(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await _prefs();
    await prefs.remove(messagesKey(userId));
  }

  Future<List<CoachChatMessage>> _loadLocalMessages(String userId) async {
    final prefs = await _prefs();
    final raw = prefs.getString(messagesKey(userId));
    if (raw == null || raw.isEmpty) return const <CoachChatMessage>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) return const <CoachChatMessage>[];
      return decoded
          .map(_messageFromJson)
          .whereType<CoachChatMessage>()
          .toList(growable: false);
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[CoachChatStorage] failed to decode messages: $error');
      }
      return const <CoachChatMessage>[];
    }
  }

  Future<void> _saveLocalMessages(
    String userId,
    List<CoachChatMessage> messages,
  ) async {
    final prefs = await _prefs();
    final payload = jsonEncode(messages.map(_messageToJson).toList());
    await prefs.setString(messagesKey(userId), payload);
  }

  List<CoachChatMessage> _mergeMessages(
    List<CoachChatMessage> local,
    List<CoachChatMessage> remote,
  ) {
    final merged = <String, CoachChatMessage>{
      for (final message in local) message.id: message,
      for (final message in remote) message.id: message,
    };

    final values = merged.values.toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return values;
  }
}

Map<String, Object?> _messageToJson(CoachChatMessage message) {
  return <String, Object?>{
    'id': message.id,
    'role': message.role.name,
    'type': message.type.name,
    'text': message.text,
    'createdAt': message.createdAt.toIso8601String(),
    'cards': message.cards.map(_cardToJson).toList(),
  };
}

CoachChatMessage? _messageFromJson(Object? raw) {
  if (raw is! Map) return null;

  final id = raw['id']?.toString();
  final roleName = raw['role']?.toString();
  final typeName = raw['type']?.toString();
  final text = raw['text']?.toString();
  final createdAtRaw = raw['createdAt']?.toString();
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

  final cardsRaw = raw['cards'];
  final cards = cardsRaw is List<Object?>
      ? cardsRaw.map(_cardFromJson).whereType<CoachChatMessageCard>().toList()
      : const <CoachChatMessageCard>[];

  return CoachChatMessage(
    id: id,
    role: role,
    type: type,
    text: text,
    createdAt: createdAt,
    cards: cards,
  );
}

Map<String, Object?> _cardToJson(CoachChatMessageCard card) {
  return <String, Object?>{
    'type': card.type.name,
    'title': card.title,
    'items': card.items,
  };
}

CoachChatMessageCard? _cardFromJson(Object? raw) {
  if (raw is! Map) return null;

  final typeName = raw['type']?.toString();
  final title = raw['title']?.toString();
  final itemsRaw = raw['items'];
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
