import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the finished-session analysis for one calendar day.
///
/// Source of truth on disk is SharedPreferences (fast restore). The daily log
/// also embeds the same JSON so date navigation / other devices can recover it.
abstract final class SessionAnalysisStore {
  static const prefsPrefix = 'session_analysis_v1_';

  static String dateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String prefsKey({
    required String userId,
    required DateTime date,
  }) {
    return '$prefsPrefix${userId}_${dateKey(date)}';
  }

  static Future<void> save({
    required String userId,
    required DateTime date,
    required SessionAnalysisSnapshot snapshot,
    SharedPreferences? preferences,
  }) async {
    if (userId.isEmpty) return;
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      final envelope = <String, Object?>{
        'v': 1,
        'saved_at': DateTime.now().toIso8601String(),
        'log_date': dateKey(date),
        'program_id': snapshot.programId,
        'session_day': snapshot.sessionDay,
        'snapshot': snapshot.toJson(),
      };
      await prefs.setString(
        prefsKey(userId: userId, date: date),
        jsonEncode(envelope),
      );
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[SessionAnalysisStore] save failed: $error');
      }
    }
  }

  static Future<SessionAnalysisSnapshot?> load({
    required String userId,
    required DateTime date,
    String? programId,
    String? sessionDay,
    Object? embeddedJson,
    SharedPreferences? preferences,
  }) async {
    final fromLog = SessionAnalysisSnapshot.tryParse(embeddedJson);
    if (fromLog != null) return fromLog;

    if (userId.isEmpty) return null;
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey(userId: userId, date: date));
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final envelope = decoded.map((k, v) => MapEntry(k.toString(), v));
      final storedProgram = envelope['program_id']?.toString();
      if (!_idsMatch(storedProgram, programId)) {
        return null;
      }
      return SessionAnalysisSnapshot.tryParse(envelope['snapshot']);
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[SessionAnalysisStore] load failed: $error');
      }
      return null;
    }
  }

  /// Most recent saved session analysis for this user (prefs, last 21 days).
  static Future<SessionAnalysisSnapshot?> loadLatest({
    required String userId,
    DateTime? from,
    SharedPreferences? preferences,
  }) async {
    if (userId.isEmpty) return null;
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      final now = from ?? DateTime.now();
      for (var i = 0; i < 21; i++) {
        final date = DateTime(now.year, now.month, now.day).subtract(
          Duration(days: i),
        );
        final raw = prefs.getString(prefsKey(userId: userId, date: date));
        if (raw == null || raw.trim().isEmpty) continue;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final envelope = decoded.map((k, v) => MapEntry(k.toString(), v));
        final snap = SessionAnalysisSnapshot.tryParse(envelope['snapshot']);
        if (snap != null) return snap;
      }
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[SessionAnalysisStore] loadLatest failed: $error');
      }
    }
    return null;
  }

  static Future<void> clear({
    required String userId,
    required DateTime date,
    SharedPreferences? preferences,
  }) async {
    if (userId.isEmpty) return;
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      await prefs.remove(prefsKey(userId: userId, date: date));
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[SessionAnalysisStore] clear failed: $error');
      }
    }
  }

  /// Empty ids are treated as wildcard — one workout identity per calendar day.
  static bool _idsMatch(String? stored, String? current) {
    final a = stored?.trim() ?? '';
    final b = current?.trim() ?? '';
    if (a.isEmpty || b.isEmpty) return true;
    return a == b;
  }
}
