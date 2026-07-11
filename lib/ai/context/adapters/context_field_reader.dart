/// Minimal read-only field coercion for context adapters.
///
/// Adapters must not add business rules, NLP, or domain transformations.
class ContextFieldReader {
  const ContextFieldReader._();

  static List<String> stringList(Object? value) {
    if (value == null) return const <String>[];
    if (value is List<Object?>) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    final text = value.toString().trim();
    if (text.isEmpty) return const <String>[];
    return <String>[text];
  }

  static String? nonEmptyString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static Map<String, Object?> objectMap(Object? value) {
    if (value is Map<String, Object?>) {
      return Map<String, Object?>.from(value);
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, Object?>{};
  }

  static List<String> mergeUnique(Iterable<String> values) {
    final seen = <String>{};
    final merged = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      merged.add(normalized);
    }
    return List<String>.unmodifiable(merged);
  }
}
