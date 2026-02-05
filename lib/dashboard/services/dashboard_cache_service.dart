import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/food.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس کشینگ حرفه‌ای برای داشبورد
/// از الگوهای حرفه‌ای استفاده می‌کند:
/// - Memory cache برای performance
/// - TTL (Time To Live) برای هر نوع داده
/// - Invalidation با تغییرات دیتابیس
/// - Type-safe
class DashboardCacheService {
  // Singleton pattern
  factory DashboardCacheService() => _instance;
  DashboardCacheService._internal();
  static final DashboardCacheService _instance =
      DashboardCacheService._internal();

  // Cache entries با TTL
  final Map<String, _CacheEntry> _cache = {};

  // Realtime subscriptions برای invalidation
  RealtimeChannel? _exercisesChannel;
  RealtimeChannel? _foodsChannel;
  RealtimeChannel? _articlesChannel;
  RealtimeChannel? _weightsChannel;
  bool _isInitialized = false;

  // TTL برای هر نوع داده (می‌تواند بر اساس نوع داده متفاوت باشد)
  static const Duration _exercisesTTL = Duration(minutes: 10);
  static const Duration _foodsTTL = Duration(minutes: 10);
  static const Duration _articlesTTL = Duration(minutes: 15);
  static const Duration _weightDataTTL = Duration(minutes: 5);
  static const Duration _profileDataTTL = Duration(minutes: 30);

  // Cache keys
  static const String _keyExercises = 'dashboard_exercises';
  static const String _keyFoods = 'dashboard_foods';
  static const String _keyArticles = 'dashboard_articles';
  static const String _keyWeightData = 'dashboard_weight_data';
  static const String _keyProfileData = 'dashboard_profile_data';
  static const String _keyLatestWeight = 'dashboard_latest_weight';

  /// اولیه‌سازی سرویس و راه‌اندازی Realtime subscriptions
  Future<void> initialize() async {
    if (_isInitialized) {
      return; // جلوگیری از initialize مکرر
    }
    await _setupRealtimeSubscriptions();
    _isInitialized = true;
  }

  /// راه‌اندازی Realtime subscriptions برای invalidation خودکار
  Future<void> _setupRealtimeSubscriptions() async {
    final client = Supabase.instance.client;

    try {
      // پاک کردن subscription های قبلی اگر وجود داشته باشند
      await _cleanupSubscriptions();

      // Subscribe به تغییرات exercises
      _exercisesChannel = client.channel('dashboard_exercises_changes')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'exercise_likes',
          callback: (payload) {
            invalidate(_keyExercises);
          },
        )
        ..subscribe();

      // Subscribe به تغییرات foods
      _foodsChannel = client.channel('dashboard_foods_changes')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'food_likes',
          callback: (payload) {
            invalidate(_keyFoods);
          },
        )
        ..subscribe();

      // Subscribe به تغییرات articles
      _articlesChannel = client.channel('dashboard_articles_changes')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'article_likes',
          callback: (payload) {
            invalidate(_keyArticles);
          },
        )
        ..subscribe();

      // Subscribe به تغییرات وزن
      final user = client.auth.currentUser;
      if (user != null) {
        _weightsChannel = client.channel('dashboard_weights_changes')
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'weekly_weights',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) {
              invalidate(_keyWeightData);
              invalidate(_keyLatestWeight);
            },
          )
          ..subscribe();
      }
    } catch (e) {
      // اگر Realtime در دسترس نبود، فقط log کن
      // در production می‌توان این را debugPrint کرد یا حذف کرد
    }
  }

  /// پاک کردن subscription های قبلی
  Future<void> _cleanupSubscriptions() async {
    try {
      await _exercisesChannel?.unsubscribe();
      await _foodsChannel?.unsubscribe();
      await _articlesChannel?.unsubscribe();
      await _weightsChannel?.unsubscribe();
      _exercisesChannel = null;
      _foodsChannel = null;
      _articlesChannel = null;
      _weightsChannel = null;
    } catch (e) {
      // Ignore errors during cleanup
    }
  }

  /// دریافت تمرینات از کش یا null
  List<Exercise>? getExercises() {
    return _get<List<Exercise>>(_keyExercises);
  }

  /// ذخیره تمرینات در کش
  void setExercises(List<Exercise> exercises) {
    _set(_keyExercises, exercises, _exercisesTTL);
  }

  /// دریافت غذاها از کش یا null
  List<Food>? getFoods() {
    return _get<List<Food>>(_keyFoods);
  }

  /// ذخیره غذاها در کش
  void setFoods(List<Food> foods) {
    _set(_keyFoods, foods, _foodsTTL);
  }

  /// دریافت مقالات از کش یا null
  List<Article>? getArticles() {
    return _get<List<Article>>(_keyArticles);
  }

  /// ذخیره مقالات در کش
  void setArticles(List<Article> articles) {
    _set(_keyArticles, articles, _articlesTTL);
  }

  /// دریافت داده‌های وزن از کش یا null
  Map<String, dynamic>? getWeightData() {
    return _get<Map<String, dynamic>>(_keyWeightData);
  }

  /// ذخیره داده‌های وزن در کش
  void setWeightData(Map<String, dynamic> data) {
    _set(_keyWeightData, data, _weightDataTTL);
  }

  /// دریافت آخرین وزن از کش یا null
  double? getLatestWeight() {
    return _get<double>(_keyLatestWeight);
  }

  /// ذخیره آخرین وزن در کش
  void setLatestWeight(double weight) {
    _set(_keyLatestWeight, weight, _weightDataTTL);
  }

  /// دریافت داده‌های پروفایل از کش یا null
  Map<String, dynamic>? getProfileData() {
    return _get<Map<String, dynamic>>(_keyProfileData);
  }

  /// ذخیره داده‌های پروفایل در کش
  void setProfileData(Map<String, dynamic> data) {
    _set(_keyProfileData, data, _profileDataTTL);
  }

  /// دریافت generic از کش
  T? _get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // بررسی TTL
    if (DateTime.now().difference(entry.timestamp) > entry.ttl) {
      _cache.remove(key);
      return null;
    }

    try {
      return entry.data as T;
    } catch (e) {
      // Type mismatch - remove invalid entry
      _cache.remove(key);
      return null;
    }
  }

  /// ذخیره generic در کش
  void _set<T>(String key, T data, Duration ttl) {
    _cache[key] = _CacheEntry(data: data, timestamp: DateTime.now(), ttl: ttl);
  }

  /// Invalidate یک کلید خاص
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Invalidate همه کش
  void invalidateAll() {
    _cache.clear();
  }

  /// Invalidate همه داده‌های داشبورد
  void invalidateDashboard() {
    invalidate(_keyExercises);
    invalidate(_keyFoods);
    invalidate(_keyArticles);
    invalidate(_keyWeightData);
    invalidate(_keyLatestWeight);
    invalidate(_keyProfileData);
  }

  /// بررسی اینکه آیا یک کلید در کش معتبر است
  bool isValid(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    return DateTime.now().difference(entry.timestamp) < entry.ttl;
  }

  /// Cleanup - حذف subscription‌ها
  Future<void> dispose() async {
    await _cleanupSubscriptions();
    _cache.clear();
    _isInitialized = false;
  }
}

/// کلاس داخلی برای نگهداری entry های کش
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;

  _CacheEntry({required this.data, required this.timestamp, required this.ttl});
}
