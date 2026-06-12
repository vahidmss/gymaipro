import 'package:shared_preferences/shared_preferences.dart';

/// تاریخچه حرکات برنامه‌های اخیر — برای کم‌کردن تکرار بین دو بار «ساخت برنامه».
class RuleBasedProgramVarietyStore {
  static const _key = 'rule_based_recent_exercise_ids_v1';

  static Future<Set<int>> loadRecentExerciseIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      return raw.map(int.tryParse).whereType<int>().toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> rememberProgramExercises(Set<int> ids) async {
    if (ids.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final previous = prefs.getStringList(_key) ?? [];
      final merged = <int>{
        ...ids,
        ...previous.map(int.tryParse).whereType<int>(),
      }.take(48).toList();
      await prefs.setStringList(
        _key,
        merged.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }
}
