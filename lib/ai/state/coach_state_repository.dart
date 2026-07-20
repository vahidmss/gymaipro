import 'dart:convert';

import 'package:gymaipro/ai/persistence/coach_persistence_keys.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_sync.dart';
import 'package:gymaipro/ai/persistence/coach_state_remote_store.dart';
import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/state/conversation_phase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence adapter for coach conversation state.
class CoachStateRepository {
  CoachStateRepository({
    SharedPreferences? preferences,
    CoachStateRemoteStore? remoteStore,
    this.storagePrefix = CoachPersistenceKeys.statePrefix,
    this.enableRemoteSync = true,
  }) : _preferences = preferences,
       _remoteStore = enableRemoteSync
           ? (remoteStore ?? CoachStateRemoteStore())
           : null;

  final SharedPreferences? _preferences;
  final CoachStateRemoteStore? _remoteStore;
  final bool enableRemoteSync;
  final Map<String, CoachConversationState> _memory =
      <String, CoachConversationState>{};

  /// Storage key prefix.
  final String storagePrefix;

  /// Saves [state] to memory and optional persistent storage.
  Future<void> saveState(CoachConversationState state) async {
    _memory[state.id] = state;
    final prefs = await _prefs();
    final states = await _loadPersistedStates(state.userId, prefs: prefs);
    states[state.id] = state;
    await _persistStates(
      state.userId,
      states.values.toList(growable: false),
      prefs,
    );
  }

  /// Loads one state by id.
  Future<CoachConversationState?> loadState({
    required String userId,
    required String stateId,
  }) async {
    final cached = _memory[stateId];
    if (cached != null && cached.userId == userId) return cached;

    final states = await loadStates(userId);
    return states.where((state) => state.id == stateId).firstOrNull;
  }

  /// Loads all states for [userId].
  Future<List<CoachConversationState>> loadStates(String userId) async {
    final prefs = await _prefs();
    final persisted = await _loadPersistedStates(userId, prefs: prefs);
    final merged = <String, CoachConversationState>{
      for (final state in persisted.values)
        if (state.userId == userId) state.id: state,
      for (final state in _memory.values)
        if (state.userId == userId) state.id: state,
    };

    if (enableRemoteSync && _remoteStore != null) {
      try {
        final remote = await _remoteStore!.fetchStates(userId);
        for (final state in remote) {
          final existing = merged[state.id];
          if (existing == null ||
              state.updatedAt.isAfter(existing.updatedAt)) {
            merged[state.id] = state;
          }
        }
        if (remote.isNotEmpty) {
          await _persistStates(
            userId,
            merged.values.toList(growable: false),
            prefs,
          );
        } else if (merged.isNotEmpty) {
          CoachPersistenceSync.run(
            'state_bootstrap',
            () => _remoteStore!.upsertStates(
              userId,
              merged.values.toList(growable: false),
            ),
          );
        }
      } on Object {
        // Keep local snapshot when remote is unavailable.
      }
    }

    final values = merged.values.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<CoachConversationState>.unmodifiable(values);
  }

  /// Returns active resumable states for [userId].
  Future<List<CoachConversationState>> loadResumableStates(
    String userId,
  ) async {
    final states = await loadStates(userId);
    return List<CoachConversationState>.unmodifiable(
      states.where((state) => state.canResume),
    );
  }

  /// Deletes one state.
  Future<void> deleteState({
    required String userId,
    required String stateId,
  }) async {
    _memory.remove(stateId);
    final prefs = await _prefs();
    final states = await _loadPersistedStates(userId, prefs: prefs);
    states.remove(stateId);
    await _persistStates(userId, states.values.toList(growable: false), prefs);
    if (enableRemoteSync && _remoteStore != null) {
      CoachPersistenceSync.run(
        'state_delete',
        () => _remoteStore!.deleteState(userId, stateId),
      );
    }
  }

  /// Marks expired states and returns the updated list for [userId].
  Future<List<CoachConversationState>> pruneExpired(
    String userId, {
    DateTime? now,
  }) async {
    final states = await loadStates(userId);
    final effectiveNow = now ?? DateTime.now();
    final updated = <CoachConversationState>[];

    for (final state in states) {
      if (!state.isExpired(now: effectiveNow) ||
          state.status == ConversationStateStatus.expired) {
        updated.add(state);
        continue;
      }

      final expiredState = state.copyWith(
        currentPhase: ConversationPhase.expired,
        status: ConversationStateStatus.expired,
        resumable: false,
        updatedAt: effectiveNow,
        notes: <String>[
          ...state.notes,
          'Conversation state expired at ${effectiveNow.toIso8601String()}.',
        ],
      );
      updated.add(expiredState);
      await saveState(expiredState);
    }

    return List<CoachConversationState>.unmodifiable(updated);
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ?? SharedPreferences.getInstance();
  }

  Future<Map<String, CoachConversationState>> _loadPersistedStates(
    String userId, {
    required SharedPreferences prefs,
  }) async {
    final raw = prefs.getString(_storageKey(userId));
    if (raw == null || raw.isEmpty) return <String, CoachConversationState>{};

    final decoded = jsonDecode(raw);
    if (decoded is! List<Object?>) return <String, CoachConversationState>{};

    final states = <String, CoachConversationState>{};
    for (final entry in decoded) {
      final map = _asStringObjectMap(entry);
      if (map == null) continue;
      final state = CoachConversationState.fromJson(map);
      states[state.id] = state;
    }
    return states;
  }

  Future<void> _persistStates(
    String userId,
    List<CoachConversationState> states,
    SharedPreferences prefs,
  ) async {
    final payload = states
        .map((state) => state.toJson())
        .toList(growable: false);
    await prefs.setString(_storageKey(userId), jsonEncode(payload));
    if (enableRemoteSync && _remoteStore != null) {
      CoachPersistenceSync.run(
        'state_upsert',
        () => _remoteStore!.upsertStates(userId, states),
      );
    }
  }

  String _storageKey(String userId) => '$storagePrefix:$userId';

  Map<String, Object?>? _asStringObjectMap(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;
    return Map<String, Object?>.unmodifiable(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

extension _CoachConversationStateList on Iterable<CoachConversationState> {
  CoachConversationState? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
