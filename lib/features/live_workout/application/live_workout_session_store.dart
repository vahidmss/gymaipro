import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_rest_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local draft storage for resume/offline live workout sessions.
class LiveWorkoutSessionStore {
  LiveWorkoutSessionStore({SharedPreferences? preferences})
    : _preferences = preferences;

  SharedPreferences? _preferences;

  static String draftKey(String userId) => 'live_workout_draft_$userId';

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<LiveWorkoutDraft?> loadDraft(String userId) async {
    final prefs = await _prefs();
    final raw = prefs.getString(draftKey(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      return LiveWorkoutDraft.fromJson(decoded);
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[LiveWorkoutSessionStore] failed to decode draft: $error');
      }
      return null;
    }
  }

  Future<void> saveDraft(LiveWorkoutDraft draft) async {
    final prefs = await _prefs();
    await prefs.setString(
      draftKey(draft.userId),
      jsonEncode(draft.toJson()),
    );
  }

  Future<void> clearDraft(String userId) async {
    final prefs = await _prefs();
    await prefs.remove(draftKey(userId));
  }
}

class LiveWorkoutDraft {
  const LiveWorkoutDraft({
    required this.userId,
    required this.session,
    required this.coachTips,
    required this.explainability,
    required this.rest,
    required this.updatedAt,
    this.pendingSync = false,
  });

  final String userId;
  final WorkoutSession session;
  final List<String> coachTips;
  final List<String> explainability;
  final LiveWorkoutRestState rest;
  final DateTime updatedAt;
  final bool pendingSync;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'userId': userId,
      'session': session.toJson(),
      'coachTips': coachTips,
      'explainability': explainability,
      'rest': rest.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
      'pendingSync': pendingSync,
    };
  }

  factory LiveWorkoutDraft.fromJson(Map<String, Object?> json) {
    final sessionJson = json['session'];
    return LiveWorkoutDraft(
      userId: json['userId']?.toString() ?? '',
      session: sessionJson is Map<String, Object?>
          ? WorkoutSession.fromJson(sessionJson)
          : WorkoutSession(
              id: '',
              title: '',
              focus: '',
              estimatedMinutes: 0,
              exercises: const [],
              startedAt: DateTime.now(),
            ),
      coachTips: (json['coachTips'] as List<Object?>?)
              ?.map((item) => item.toString())
              .toList(growable: false) ??
          const <String>[],
      explainability: (json['explainability'] as List<Object?>?)
              ?.map((item) => item.toString())
              .toList(growable: false) ??
          const <String>[],
      rest: json['rest'] is Map<String, Object?>
          ? LiveWorkoutRestState.fromJson(json['rest'] as Map<String, Object?>)
          : const LiveWorkoutRestState.idle(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      pendingSync: json['pendingSync'] == true,
    );
  }

  LiveWorkoutDraft copyWith({
    WorkoutSession? session,
    LiveWorkoutRestState? rest,
    bool? pendingSync,
  }) {
    return LiveWorkoutDraft(
      userId: userId,
      session: session ?? this.session,
      coachTips: coachTips,
      explainability: explainability,
      rest: rest ?? this.rest,
      updatedAt: DateTime.now(),
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
