/// Display labels for workout programs (title + creator line).
class ProgramDisplayLabels {
  const ProgramDisplayLabels({
    required this.title,
    this.creatorLine,
  });

  final String title;
  final String? creatorLine;

  static ProgramDisplayLabels resolve({
    required String rawName,
    required String creatorName,
  }) {
    final creator = _normalizeCreator(creatorName);
    final cleaned = _cleanProgramName(rawName);

    if (cleaned.isEmpty || _isGenericProgramLabel(cleaned)) {
      return ProgramDisplayLabels(title: creator);
    }
    if (_isSameLabel(cleaned, creator)) {
      return ProgramDisplayLabels(title: creator);
    }
    return ProgramDisplayLabels(title: cleaned, creatorLine: creator);
  }

  static String _normalizeCreator(String name) {
    final trimmed = name.trim().replaceFirst(RegExp(r'^مربی:\s*'), '');
    if (trimmed.isEmpty || trimmed == '—') return 'آزمایشی';
    return trimmed;
  }

  static bool _isGenericProgramLabel(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized == 'برنامه تمرینی' ||
        normalized == 'برنامه تمرین' ||
        normalized == 'برنامه';
  }

  static bool _isSameLabel(String a, String b) {
    return a.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase() ==
        b.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  static String _cleanProgramName(String raw) {
    return raw
        .replaceAll(RegExp(r'^برنامه(?:\s+تمرینی|\s+تمرین)?\s*'), '')
        .trim();
  }
}
