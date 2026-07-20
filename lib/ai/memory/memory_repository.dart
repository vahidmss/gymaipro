import 'dart:convert';

import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/persistence/coach_memory_remote_store.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_keys.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence adapter for Coach Memory (local cache + optional Supabase sync).
class MemoryRepository {
  MemoryRepository({
    SharedPreferences? preferences,
    CoachMemoryRemoteStore? remoteStore,
    this.storagePrefix = CoachPersistenceKeys.memoryPrefix,
    this.enableRemoteSync = true,
  }) : _preferences = preferences,
       _remoteStore = enableRemoteSync
           ? (remoteStore ?? CoachMemoryRemoteStore())
           : null;

  final SharedPreferences? _preferences;
  final CoachMemoryRemoteStore? _remoteStore;
  final bool enableRemoteSync;

  /// Storage key prefix.
  final String storagePrefix;

  /// Loads all memories for [userId].
  Future<List<CoachMemory>> loadMemories(String userId) async {
    final local = await _loadLocalMemories(userId);
    if (!enableRemoteSync || _remoteStore == null) {
      return local;
    }

    try {
      final remote = await _remoteStore.fetchMemories(userId);
      if (remote.isEmpty) {
        if (local.isNotEmpty) {
          CoachPersistenceSync.run(
            'memory_bootstrap',
            () => _remoteStore.upsertMemories(userId, local),
          );
        }
        return local;
      }

      final merged = _mergeMemories(local, remote);
      await _saveLocalMemories(userId, merged);
      return merged;
    } on Object {
      return local;
    }
  }

  /// Saves all memories for [userId].
  Future<void> saveMemories(String userId, List<CoachMemory> memories) async {
    await _saveLocalMemories(userId, memories);
    _syncRemote(userId, memories);
  }

  /// Inserts or replaces one memory by key.
  Future<void> upsertMemory(String userId, CoachMemory memory) async {
    final memories = await _loadLocalMemories(userId);
    final byKey = <String, CoachMemory>{
      for (final item in memories) item.key: item,
      memory.key: memory,
    };
    await saveMemories(userId, byKey.values.toList(growable: false));
  }

  /// Deletes one memory by key.
  Future<void> deleteMemory(String userId, String key) async {
    final memories = await _loadLocalMemories(userId);
    final kept = memories
        .where((memory) => memory.key != key)
        .toList(growable: false);
    await _saveLocalMemories(userId, kept);
    if (enableRemoteSync && _remoteStore != null) {
      CoachPersistenceSync.run(
        'memory_delete',
        () => _remoteStore!.deleteMemory(userId, key),
      );
    }
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

  Future<List<CoachMemory>> _loadLocalMemories(String userId) async {
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

  Future<void> _saveLocalMemories(
    String userId,
    List<CoachMemory> memories,
  ) async {
    final prefs = await _prefs();
    final payload = memories.map((memory) => memory.toJson()).toList();
    await prefs.setString(_storageKey(userId), jsonEncode(payload));
  }

  void _syncRemote(String userId, List<CoachMemory> memories) {
    if (!enableRemoteSync || _remoteStore == null) return;
    CoachPersistenceSync.run(
      'memory_upsert',
      () => _remoteStore!.upsertMemories(userId, memories),
    );
  }

  List<CoachMemory> _mergeMemories(
    List<CoachMemory> local,
    List<CoachMemory> remote,
  ) {
    final merged = <String, CoachMemory>{
      for (final memory in local) memory.key: memory,
    };

    for (final memory in remote) {
      final existing = merged[memory.key];
      if (existing == null || memory.updatedAt.isAfter(existing.updatedAt)) {
        merged[memory.key] = memory;
      }
    }

    return merged.values.toList(growable: false);
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
