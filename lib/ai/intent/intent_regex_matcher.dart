/// Regex matcher for data-driven intent rules.
class IntentRegexMatcher {
  const IntentRegexMatcher();

  /// Returns the first matched token for [pattern] in [message].
  String? firstMatch({
    required String message,
    required String pattern,
    bool caseInsensitive = true,
  }) {
    final regex = _compile(pattern, caseInsensitive: caseInsensitive);
    final match = regex.firstMatch(message);
    if (match == null) return null;
    return match.group(0);
  }

  /// Whether [pattern] matches [message].
  bool matches({
    required String message,
    required String pattern,
    bool caseInsensitive = true,
  }) {
    return firstMatch(
          message: message,
          pattern: pattern,
          caseInsensitive: caseInsensitive,
        ) !=
        null;
  }

  RegExp _compile(String pattern, {required bool caseInsensitive}) {
    return RegExp(pattern, caseSensitive: !caseInsensitive, unicode: true);
  }
}

/// Normalizes user text before rule evaluation.
class IntentMessageNormalizer {
  const IntentMessageNormalizer();

  String normalize(String message) {
    return message.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }
}
