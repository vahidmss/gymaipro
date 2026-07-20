/// Shared muscle-tag matching for LLM workout validate + sanitize.
/// Keep these rules identical so engines never disagree.
abstract final class LlmWorkoutMuscleTags {
  const LlmWorkoutMuscleTags._();

  static bool isChest(String m) {
    final t = m.toLowerCase();
    return t.contains('chest') || t.contains('سینه');
  }

  static bool isShoulder(String m) {
    final t = m.toLowerCase();
    return t.contains('shoulder') ||
        t.contains('شانه') ||
        t.contains('سرشانه') ||
        t.contains('دلtoid') ||
        t.contains('delt');
  }

  static bool isTricep(String m) {
    final t = m.toLowerCase();
    return t.contains('tricep') ||
        t.contains('پشت‌بازو') ||
        RegExp(r'پشت\s*بازو').hasMatch(t);
  }

  static bool isBicep(String m) {
    final t = m.toLowerCase();
    // Do NOT match bare «جلو» — that hits «جلو سرشانه».
    if (isShoulder(t) || isChest(t) || isTricep(t)) return false;
    return t.contains('bicep') ||
        t.contains('جلوبازو') ||
        RegExp(r'جلو\s*بازو').hasMatch(t);
  }

  static bool isBack(String m) {
    final t = m.toLowerCase();
    // «lat» inside shoulder_lateral must not count as back/lats.
    if (isShoulder(t) || isChest(t) || isTricep(t) || isBicep(t)) {
      return false;
    }
    if (t.contains('lateral') && !t.contains('lat_') && !t.contains('back')) {
      return false;
    }
    return t.contains('back') ||
        t.contains('زیربغل') ||
        t.contains('trap') ||
        t.contains('rhomboid') ||
        t.contains('کول') ||
        (t.contains('lat') && !t.contains('lateral')) ||
        t.contains('کمر');
  }

  static bool isQuad(String m) {
    final t = m.toLowerCase();
    return t.contains('quad') || t.contains('چهار');
  }

  static bool isHamstring(String m) {
    final t = m.toLowerCase();
    return t.contains('ham') || t.contains('پشت پا');
  }

  static bool isGlute(String m) {
    final t = m.toLowerCase();
    return t.contains('glute') || t.contains('باسن');
  }

  static bool isCalf(String m) {
    final t = m.toLowerCase();
    return t.contains('calf') || t.contains('ساق');
  }

  static bool isLeg(String m) {
    final t = m.toLowerCase();
    if (isTricep(t) || isBack(t)) return false;
    return isQuad(t) ||
        isHamstring(t) ||
        isGlute(t) ||
        isCalf(t) ||
        (t.contains('پا') && !RegExp(r'پشت\s*بازو').hasMatch(t));
  }

  static bool isCore(String m) {
    final t = m.toLowerCase();
    return t.contains('abs') ||
        t.contains('oblique') ||
        t.contains('core') ||
        t.contains('شکم') ||
        t.contains('مورب');
  }

  static bool isPushOk(String m) =>
      isChest(m) || isShoulder(m) || isTricep(m) || isCore(m);

  static bool isPushForeign(String m) =>
      !isPushOk(m) && (isBack(m) || isBicep(m) || isLeg(m));

  static bool isPullOk(String m) =>
      isBack(m) ||
      isBicep(m) ||
      isCore(m) ||
      m.toLowerCase().contains('posterior') ||
      m.contains('خلف');

  static bool isPullForeign(String m) {
    final t = m.toLowerCase();
    if (isPullOk(t)) return false;
    return isChest(t) ||
        isTricep(t) ||
        isLeg(t) ||
        (isShoulder(t) && !t.contains('posterior') && !t.contains('خلف'));
  }

  static bool isLegDayOk(String m) => isLeg(m) || isCore(m);

  static bool isLegDayForeign(String m) {
    final t = m.toLowerCase();
    if (isLegDayOk(t)) return false;
    return isChest(t) ||
        isBack(t) ||
        isBicep(t) ||
        isTricep(t) ||
        (isShoulder(t) && !t.contains('posterior'));
  }
}
