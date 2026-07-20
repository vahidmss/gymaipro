import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase persistence for multi-step coach conversation state.
class CoachStateRemoteStore {
  CoachStateRemoteStore({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;
  static const _table = 'coach_conversation_states';

  SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return Supabase.instance.client;
    } on Object {
      return null;
    }
  }

  String? get _userId => _client?.auth.currentUser?.id;

  Future<List<CoachConversationState>> fetchStates(String userId) async {
    if (_client == null || _userId == null || _userId != userId) {
      return const <CoachConversationState>[];
    }

    final rows = await _client!
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return (rows as List<Object?>)
        .map(_stateFromRow)
        .whereType<CoachConversationState>()
        .toList(growable: false);
  }

  Future<void> upsertStates(
    String userId,
    List<CoachConversationState> states,
  ) async {
    if (_client == null || _userId == null || _userId != userId || states.isEmpty) {
      return;
    }

    final payload = states
        .map((state) => _stateToRow(userId, state))
        .toList(growable: false);
    await _client!.from(_table).upsert(payload, onConflict: 'user_id,state_id');
  }

  Future<void> deleteState(String userId, String stateId) async {
    if (_client == null || _userId == null || _userId != userId) return;

    await _client!
        .from(_table)
        .delete()
        .eq('user_id', userId)
        .eq('state_id', stateId);
  }

  Map<String, Object?> _stateToRow(
    String userId,
    CoachConversationState state,
  ) {
    return <String, Object?>{
      'state_id': state.id,
      'user_id': userId,
      'state': state.toJson(),
      'expires_at': state.expiresAt?.toIso8601String(),
      'updated_at': state.updatedAt.toIso8601String(),
    };
  }

  CoachConversationState? _stateFromRow(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final stateRaw = map['state'];
    if (stateRaw is! Map<Object?, Object?>) return null;
    final stateMap = stateRaw.map((key, value) => MapEntry(key.toString(), value));
    try {
      return CoachConversationState.fromJson(stateMap);
    } on Object {
      return null;
    }
  }
}
