import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _tsSuffix = '__updated_at';

  static Future<void> setJson(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
    await prefs.setString('$key$_tsSuffix', DateTime.now().toIso8601String());
  }

  static Future<Map<String, dynamic>?> getJsonMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<dynamic>?> getJsonList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List<dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<DateTime?> getUpdatedAt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('$key$_tsSuffix');
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    await prefs.remove('$key$_tsSuffix');
  }
}
