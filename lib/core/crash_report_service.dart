import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/core/app_initializer.dart';
import 'package:gymaipro/services/app_version_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Queues client crashes locally and uploads them to the app backend.
///
/// Google Crashlytics is unreliable on filtered Iranian networks, so reports
/// go to Supabase (`client_crash_reports`) instead.
class CrashReportService {
  CrashReportService._();

  static final CrashReportService instance = CrashReportService._();

  static const _queueKey = 'client_crash_report_queue_v1';
  static const _maxQueue = 20;
  static const _maxStackChars = 4000;

  bool _flushing = false;

  Future<void> record(Object error, StackTrace stack) async {
    try {
      final message = error.toString();
      if (_shouldIgnore(message)) return;

      final stackText = stack.toString();
      final fingerprint = _fingerprint(message, stackText);
      await AppVersionService.instance.ensureLoaded();
      final version = AppVersionService.instance;

      final payload = <String, dynamic>{
        'error_message': message.length > 800
            ? message.substring(0, 800)
            : message,
        'stack_trace': stackText.length > _maxStackChars
            ? stackText.substring(0, _maxStackChars)
            : stackText,
        'fingerprint': fingerprint,
        'app_version': version.version,
        'build_number': version.buildNumber,
        'platform': defaultTargetPlatform.name,
      };

      final prefs = await SharedPreferences.getInstance();
      final queue = _readQueue(prefs);
      if (queue.any((item) => item['fingerprint'] == fingerprint)) {
        return;
      }
      queue.add(payload);
      while (queue.length > _maxQueue) {
        queue.removeAt(0);
      }
      await prefs.setString(_queueKey, jsonEncode(queue));
      unawaited(flush());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CrashReportService.record failed: $e');
      }
    }
  }

  Future<void> flush() async {
    if (_flushing) return;
    if (!AppInitializer.isSupabaseReady) return;
    _flushing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = _readQueue(prefs);
      if (queue.isEmpty) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      final remaining = <Map<String, dynamic>>[];

      for (final item in queue) {
        try {
          await Supabase.instance.client.from('client_crash_reports').insert({
            ...item,
            'user_id': userId,
          });
        } catch (e) {
          remaining.add(item);
          if (kDebugMode) {
            debugPrint('CrashReportService.flush item failed: $e');
          }
        }
      }

      if (remaining.isEmpty) {
        await prefs.remove(_queueKey);
      } else {
        await prefs.setString(_queueKey, jsonEncode(remaining));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CrashReportService.flush failed: $e');
      }
    } finally {
      _flushing = false;
    }
  }

  List<Map<String, dynamic>> _readQueue(SharedPreferences prefs) {
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return [
        for (final item in decoded)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  bool _shouldIgnore(String message) {
    final lower = message.toLowerCase();
    return lower.contains('authretryablefetchexception') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('renderflex overflowed');
  }

  String _fingerprint(String message, String stack) {
    final firstLines = stack.split('\n').take(4).join('|');
    return '${message.hashCode}:${firstLines.hashCode}';
  }
}
