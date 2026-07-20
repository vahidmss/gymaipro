/// Picks a free workout program name against an existing name set.
///
/// Same-day regenerations get `(M/D)`, then `(M/D #2)`, `(M/D #3)`, …
String ensureUniqueWorkoutProgramName(
  String base,
  Iterable<String> existingNames, {
  DateTime? now,
}) {
  final names = existingNames.toSet();
  final trimmed = base.trim();
  if (trimmed.isEmpty) {
    final stamp = now ?? DateTime.now();
    return 'برنامه ${stamp.millisecondsSinceEpoch}';
  }
  if (!names.contains(trimmed)) return trimmed;

  final stamp = now ?? DateTime.now();
  final dated = '$trimmed (${stamp.month}/${stamp.day})';
  if (!names.contains(dated)) return dated;

  for (var i = 2; i <= 99; i++) {
    final candidate = '$trimmed (${stamp.month}/${stamp.day} #$i)';
    if (!names.contains(candidate)) return candidate;
  }
  return '$trimmed (${stamp.millisecondsSinceEpoch})';
}
