import 'dart:convert';

import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence adapter for Coach Memory.
///
/// This repository is not wired into existing app flows. It stores data only
/// when future callers explicitly use it.
class MemoryRepository {
  MemoryRepository({
    SharedPreferences? preferences,
    this.storagePrefix = 'gym_ai_coach_memory',
  }) : _preferences = preferences;

  final SharedPreferences? _preferences;

  /// Storage key prefix.
  final String storagePrefix;

  /// Loads all memories for [userId].
  Future<List<CoachMemory>> loadMemories(String userId) async {
    final prefs = await _prefs();
    final raw = prefs.getString(_storageKey(userId));
    if (raw == null || raw.isEmpty) return const <CoachMemory>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<Object?>) return const <CoachMemory>[];

    final memories = <CoachMemory>[];
    for (final entry in decoded) {
      final map = _asStringObjectMap(entry);
      if (map == null) continue;
      memories.add(CoachMemory.fromJson(map));
    }
    return List<CoachMemory>.unmodifiable(memories);
  }

  /// Saves all memories for [userId].
  Future<void> saveMemories(String userId, List<CoachMemory> memories) async {
    final prefs = await _prefs();
    final payload = memories.map((memory) => memory.toJson()).toList();
    await prefs.setString(_storageKey(userId), jsonEncode(payload));
  }

  /// Inserts or replaces one memory by key.
  Future<void> upsertMemory(String userId, CoachMemory memory) async {
    final memories = await loadMemories(userId);
    final byKey = <String, CoachMemory>{
      for (final item in memories) item.key: item,
      memory.key: memory,
    };
    await saveMemories(userId, byKey.values.toList(growable: false));
  }

  /// Deletes one memory by key.
  Future<void> deleteMemory(String userId, String key) async {
    final memories = await loadMemories(userId);
    final kept = memories
        .where((memory) => memory.key != key)
        .toList(growable: false);
    await saveMemories(userId, kept);
  }

  /// Removes expired memories and returns the remaining list.
  Future<List<CoachMemory>> pruneExpired(String userId, {DateTime? now}) async {
    final memories = await loadMemories(userId);
    final kept = memories
        .where((memory) => !memory.isExpired(now))
        .toList(growable: false);
    if (kept.length != memories.length) {
      await saveMemories(userId, kept);
    }
    return List<CoachMemory>.unmodifiable(kept);
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ?? SharedPreferences.getInstance();
  }

  String _storageKey(String userId) => '$storagePrefix.$userId';

  Map<String, Object?>? _asStringObjectMap(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    return <String, Object?>{
      for (final entry in value.entries)
        if (entry.key is String) entry.key! as String: entry.value,
    };
  }
}
