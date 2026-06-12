/// Semantic version helpers used for remote update checks.
class VersionUtils {
  VersionUtils._();

  /// Returns negative if [current] < [target], zero if equal, positive if greater.
  static int compare(String current, String target) {
    final currentParts = _parseParts(current);
    final targetParts = _parseParts(target);
    final maxLength = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;

    for (var i = 0; i < maxLength; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final t = i < targetParts.length ? targetParts[i] : 0;
      if (c < t) return -1;
      if (c > t) return 1;
    }
    return 0;
  }

  static bool isLessThan(String current, String target) =>
      compare(current, target) < 0;

  static bool isGreaterThan(String current, String target) =>
      compare(current, target) > 0;

  static List<int> _parseParts(String raw) {
    final normalized = raw.trim().split('+').first;
    return normalized
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }
}
