import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase persistence for [CoachMemory] rows.
class CoachMemoryRemoteStore {
  CoachMemoryRemoteStore({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;
  static const _table = 'coach_memories';

  SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return Supabase.instance.client;
    } on Object {
      return null;
    }
  }

  String? get _userId => _client?.auth.currentUser?.id;

  Future<List<CoachMemory>> fetchMemories(String userId) async {
    if (_client == null || _userId == null || _userId != userId) {
      return const <CoachMemory>[];
    }

    final rows = await _client!
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return (rows as List<Object?>)
        .map(_memoryFromRow)
        .whereType<CoachMemory>()
        .toList(growable: false);
  }

  Future<void> upsertMemories(
    String userId,
    List<CoachMemory> memories,
  ) async {
    if (_client == null || _userId == null || _userId != userId || memories.isEmpty) {
      return;
    }

    final payload = memories.map((memory) => _memoryToRow(userId, memory)).toList();
    await _client!.from(_table).upsert(payload, onConflict: 'user_id,memory_key');
  }

  Future<void> deleteMemory(String userId, String key) async {
    if (_client == null || _userId == null || _userId != userId) return;

    await _client!
        .from(_table)
        .delete()
        .eq('user_id', userId)
        .eq('memory_key', key);
  }

  Map<String, Object?> _memoryToRow(String userId, CoachMemory memory) {
    return <String, Object?>{
      'user_id': userId,
      'memory_key': memory.key,
      'value': memory.value,
      'category': memory.category.name,
      'confidence': memory.confidence,
      'importance': memory.importance.name,
      'source': memory.source.name,
      'expires_at': memory.expiresAt?.toIso8601String(),
      'editable': memory.editable,
      'user_editable': memory.userEditable,
      'ai_generated': memory.aiGenerated,
      'created_at': memory.createdAt.toIso8601String(),
      'updated_at': memory.updatedAt.toIso8601String(),
    };
  }

  CoachMemory? _memoryFromRow(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    return CoachMemory.fromJson(<String, Object?>{
      'key': map['memory_key'],
      'value': map['value'],
      'category': map['category'],
      'confidence': map['confidence'],
      'importance': map['importance'],
      'source': map['source'],
      'expiresAt': map['expires_at'],
      'editable': map['editable'],
      'userEditable': map['user_editable'],
      'aiGenerated': map['ai_generated'],
      'createdAt': map['created_at'],
      'updatedAt': map['updated_at'],
    });
  }
}
