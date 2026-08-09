import 'package:shared_preferences/shared_preferences.dart';

/// ثبت آب روزانه — فعلاً لوکال (SharedPreferences)، هم‌راستا با لاگ غذا.
class WaterLogService {
  WaterLogService();

  static const int glassMl = 250;
  static const int defaultTargetMl = 2500;
  static const int minTargetMl = 1500;
  static const int maxTargetMl = 4500;

  String _key(String? userId, DateTime date) {
    final d = date.toIso8601String().substring(0, 10);
    final uid = (userId == null || userId.isEmpty) ? 'local' : userId;
    return 'water_log_${uid}_$d';
  }

  Future<int> getMl({required DateTime date, String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(userId, date)) ?? 0;
  }

  Future<void> setMl({
    required DateTime date,
    required int ml,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = ml < 0 ? 0 : ml;
    await prefs.setInt(_key(userId, date), clamped);
  }

  Future<int> addGlass({
    required DateTime date,
    String? userId,
    int glasses = 1,
  }) async {
    final current = await getMl(date: date, userId: userId);
    final next = current + (glassMl * glasses);
    await setMl(date: date, ml: next, userId: userId);
    return next;
  }

  Future<int> removeGlass({
    required DateTime date,
    String? userId,
    int glasses = 1,
  }) async {
    final current = await getMl(date: date, userId: userId);
    final next = (current - glassMl * glasses).clamp(0, 1 << 30);
    await setMl(date: date, ml: next, userId: userId);
    return next;
  }

  /// هدف تقریبی از وزن پروفایل (۳۵ ml/kg؛ فعال‌تر = بیشتر).
  static int targetMlFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return defaultTargetMl;
    final weight = _readWeight(profile);
    if (weight == null || weight <= 0) return defaultTargetMl;

    var mlPerKg = 35.0;
    final activity = (profile['activity_level'] ??
            profile['experience_level'] ??
            '')
        .toString()
        .toLowerCase();
    if (activity.contains('very') ||
        activity.contains('extra') ||
        activity.contains('خیلی')) {
      mlPerKg = 45;
    } else if (activity.contains('moderate') ||
        activity.contains('متوسط') ||
        activity.contains('active')) {
      mlPerKg = 40;
    }

    final target = (weight * mlPerKg).round();
    return target.clamp(minTargetMl, maxTargetMl);
  }

  static double? _readWeight(Map<String, dynamic> profile) {
    final raw = profile['weight'];
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.replaceAll(',', '.'));
    return null;
  }

  static int glassCountForTarget(int targetMl) {
    final n = (targetMl / glassMl).ceil();
    return n.clamp(4, 10);
  }
}
