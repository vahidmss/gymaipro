import 'dart:convert';
import 'dart:ui';

/// کلیدهای استاندارد هیت‌مپ (همان متاباکس وردپرس / Supabase).
class MuscleTargets {
  MuscleTargets._();

  static const List<String> allKeys = [
    'chest_upper',
    'chest_middle',
    'chest_lower',
    'shoulder_anterior',
    'shoulder_lateral',
    'shoulder_posterior',
    'triceps',
    'biceps',
    'forearms',
    'back_lat',
    'back_trap',
    'lower_back',
    'quads',
    'hamstrings',
    'glutes',
    'calf',
    'abs',
  ];

  static const Map<String, String> persianLabels = {
    'chest_upper': 'سینه بالایی',
    'chest_middle': 'سینه میانی',
    'chest_lower': 'سینه پایینی',
    'shoulder_anterior': 'سرشانه قدامی',
    'shoulder_lateral': 'سرشانه جانبی',
    'shoulder_posterior': 'سرشانه خلفی',
    'triceps': 'پشت‌بازو',
    'biceps': 'جلوبازو',
    'forearms': 'ساعد',
    'back_lat': 'زیربغل',
    'back_trap': 'ذوزنقه',
    'lower_back': 'کمر',
    'quads': 'چهارسر ران',
    'hamstrings': 'همسترینگ',
    'glutes': 'باسن',
    'calf': 'ساق پا',
    'abs': 'شکم',
  };

  /// نمای جلو / پشت برای هر کلید
  static const Map<String, BodyView> viewByKey = {
    'chest_upper': BodyView.front,
    'chest_middle': BodyView.front,
    'chest_lower': BodyView.front,
    'shoulder_anterior': BodyView.front,
    'shoulder_lateral': BodyView.front,
    'shoulder_posterior': BodyView.back,
    'triceps': BodyView.back,
    'biceps': BodyView.front,
    'forearms': BodyView.front,
    'back_lat': BodyView.back,
    'back_trap': BodyView.back,
    'lower_back': BodyView.back,
    'quads': BodyView.front,
    'hamstrings': BodyView.back,
    'glutes': BodyView.back,
    'calf': BodyView.both,
    'abs': BodyView.front,
  };

  static String label(String key) =>
      persianLabels[key] ?? key.replaceAll('_', ' ');

  /// Resolves a free-form primary-muscle tag (Persian/English) to a heatmap key.
  static String? keyForTag(String? raw) {
    final tag = (raw ?? '').trim().toLowerCase();
    if (tag.isEmpty) return null;

    for (final entry in persianLabels.entries) {
      if (entry.value == raw?.trim()) return entry.key;
      if (tag.contains(entry.value)) return entry.key;
    }

    const aliases = <String, String>{
      'سینه': 'chest_middle',
      'chest': 'chest_middle',
      'pec': 'chest_middle',
      'شانه': 'shoulder_lateral',
      'سرشانه': 'shoulder_lateral',
      'shoulder': 'shoulder_lateral',
      'پشت': 'back_lat',
      'زیربغل': 'back_lat',
      'back': 'back_lat',
      'lat': 'back_lat',
      'پا': 'quads',
      'ران': 'quads',
      'leg': 'quads',
      'quad': 'quads',
      'همسترینگ': 'hamstrings',
      'hamstring': 'hamstrings',
      'باسن': 'glutes',
      'glute': 'glutes',
      'ساق': 'calf',
      'calf': 'calf',
      'شکم': 'abs',
      'core': 'abs',
      'abs': 'abs',
      'جلوبازو': 'biceps',
      'بازو': 'biceps',
      'bicep': 'biceps',
      'پشت‌بازو': 'triceps',
      'پشت بازو': 'triceps',
      'tricep': 'triceps',
      'ساعد': 'forearms',
      'کمر': 'lower_back',
    };
    for (final entry in aliases.entries) {
      if (tag.contains(entry.key.toLowerCase())) return entry.value;
    }
    return null;
  }

  /// پارس از meta وردپرس، jsonb سوپابیس، یا رشته JSON
  static Map<String, int> parse(dynamic raw) {
    if (raw == null) return {};
    Map<String, dynamic>? map;
    if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          map = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return {};
      }
    }
    if (map == null || map.isEmpty) return {};

    final out = <String, int>{};
    for (final entry in map.entries) {
      final key = entry.key;
      if (!allKeys.contains(key)) continue;
      final v = entry.value;
      final n = v is num ? v.round() : int.tryParse(v.toString()) ?? 0;
      if (n > 0) out[key] = n.clamp(0, 100);
    }
    return out;
  }

  static bool hasData(Map<String, int> targets) =>
      targets.values.any((v) => v > 0);

  /// مرتب‌سازی بر اساس شدت (برای لیست و برچسب‌ها)
  static List<MapEntry<String, int>> sortedEntries(Map<String, int> targets) {
    final entries = targets.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// رنگ گرادیان هیت — طیفی تمیز (خنک→گرم)، بدون طلای برند.
  static Color heatColor(int intensity, {required bool isDark}) {
    final t = (intensity.clamp(0, 100)) / 100.0;
    if (t <= 0.08) {
      return isDark ? const Color(0xFF3A4450) : const Color(0xFFB0BEC5);
    }
    if (t < 0.40) {
      return Color.lerp(
        const Color(0xFF5B8DEF),
        const Color(0xFF26C6DA),
        (t - 0.08) / 0.32,
      )!;
    }
    if (t < 0.70) {
      return Color.lerp(
        const Color(0xFF26C6DA),
        const Color(0xFFFFB74D),
        (t - 0.40) / 0.30,
      )!;
    }
    return Color.lerp(
      const Color(0xFFFF8A65),
      const Color(0xFFE53935),
      (t - 0.70) / 0.30,
    )!;
  }

  static String intensityLabel(int value) {
    // نسبت به داغ‌ترین عضلهٔ همان بازه — نه درصد فیزیولوژیک مطلق.
    if (value >= 85) return 'اصلی';
    if (value >= 60) return 'فعال';
    if (value >= 35) return 'فرعی';
    return 'کم';
  }

  /// نمای پیش‌فرض همیشه جلو است؛ اگر داده فقط پشت باشد،
  /// ویجت با overlay پیشنهاد چرخش می‌دهد.
  static BodyView preferredView(Map<String, int> targets) {
    return BodyView.front;
  }

  /// کلیدهایی که روی نقشهٔ یک نما رسم می‌شوند
  static Set<String> mapVisibleKeys(
    Map<String, int> targets, {
    required BodyView view,
    int minIntensity = 35,
  }) {
    final out = <String>{};
    for (final e in targets.entries) {
      if (e.value < minIntensity) continue;
      final side = viewByKey[e.key];
      if (side == view || side == BodyView.both) out.add(e.key);
    }
    return out;
  }
}

enum BodyView { front, back, both }
