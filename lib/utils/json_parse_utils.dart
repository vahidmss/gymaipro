/// Lightweight, null-safe JSON parsing. No duplicate logic, no throw on bad data.
class JsonParse {
  JsonParse._();

  static String string(Map<String, dynamic>? json, String key, [String fallback = '']) {
    if (json == null) return fallback;
    final v = json[key];
    if (v == null) return fallback;
    return v.toString().trim();
  }

  static String? stringOrNull(Map<String, dynamic>? json, String key) {
    if (json == null) return null;
    final v = json[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int integer(Map<String, dynamic>? json, String key, [int fallback = 0]) {
    if (json == null) return fallback;
    final v = json[key];
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  static int? integerOrNull(Map<String, dynamic>? json, String key) {
    if (json == null) return null;
    final v = json[key];
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double doubleVal(Map<String, dynamic>? json, String key, [double fallback = 0]) {
    if (json == null) return fallback;
    final v = json[key];
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static double? doubleOrNull(Map<String, dynamic>? json, String key) {
    if (json == null) return null;
    final v = json[key];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static bool boolean(Map<String, dynamic>? json, String key, [bool fallback = false]) {
    if (json == null) return fallback;
    final v = json[key];
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v.toString().toLowerCase() == 'true';
  }

  static DateTime dateTime(Map<String, dynamic>? json, String key, [DateTime? fallback]) {
    final f = fallback ?? DateTime.now();
    if (json == null) return f;
    final v = json[key];
    if (v == null) return f;
    if (v is DateTime) return v;
    final parsed = DateTime.tryParse(v.toString());
    return parsed ?? f;
  }

  static DateTime? dateTimeOrNull(Map<String, dynamic>? json, String key) {
    if (json == null) return null;
    final v = json[key];
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static List<String> listOfStrings(Map<String, dynamic>? json, String key) {
    if (json == null) return const [];
    final v = json[key];
    if (v is! List) return const [];
    final out = <String>[];
    for (final e in v) {
      final s = e?.toString().trim();
      if (s != null && s.isNotEmpty) out.add(s);
    }
    return out;
  }

  /// Parse any value to int (for WordPress/mixed JSON).
  static int fromInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  /// Parse any value to int? (for WordPress/mixed JSON).
  static int? fromIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  /// Parse any value to non-null String (for WordPress/mixed JSON).
  static String fromStr(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString().trim();
  }

  /// Parse any value to String? (empty string becomes null).
  static String? fromStrOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
