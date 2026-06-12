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

  /// رنگ گرادیان هیت — سبک اپ‌های فیتنس (کم → زیاد)
  static Color heatColor(int intensity, {required bool isDark}) {
    final t = (intensity.clamp(0, 100)) / 100.0;
    if (t <= 0.05) {
      return isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE8E0D4);
    }
    if (t < 0.45) {
      return Color.lerp(
        isDark ? const Color(0xFF1E3A5F) : const Color(0xFF90CAF9),
        isDark ? const Color(0xFF2E6B8A) : const Color(0xFF4DB6AC),
        (t - 0.05) / 0.4,
      )!;
    }
    if (t < 0.75) {
      return Color.lerp(
        const Color(0xFFE7B628),
        const Color(0xFFD4AF37),
        (t - 0.45) / 0.3,
      )!;
    }
    return Color.lerp(
      const Color(0xFFE65100),
      const Color(0xFFB71C1C),
      (t - 0.75) / 0.25,
    )!;
  }

  static String intensityLabel(int value) {
    if (value >= 85) return 'اصلی';
    if (value >= 60) return 'فعال';
    if (value >= 35) return 'فرعی';
    return 'کم';
  }

  /// نمای پیش‌فرض بر اساس مجموع شدت عضلات جلو / پشت
  static BodyView preferredView(Map<String, int> targets) {
    var frontScore = 0;
    var backScore = 0;
    for (final e in targets.entries) {
      if (e.value <= 0) continue;
      switch (viewByKey[e.key]) {
        case BodyView.front:
          frontScore += e.value;
        case BodyView.back:
          backScore += e.value;
        case BodyView.both:
          frontScore += e.value ~/ 2;
          backScore += e.value ~/ 2;
        case null:
          break;
      }
    }
    return backScore > frontScore ? BodyView.back : BodyView.front;
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
