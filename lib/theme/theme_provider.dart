import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Provider برای مدیریت تم اپلیکیشن
/// 
/// این کلاس از SharedPreferences برای ذخیره تنظیمات تم استفاده می‌کند
/// که روش استاندارد Flutter برای ذخیره تنظیمات محلی کاربر است.
/// 
/// **نکته مهم**: تنظیمات تم در دیتابیس ذخیره نمی‌شود و فقط در حافظه محلی
/// دستگاه (SharedPreferences) نگهداری می‌شود. این روش استاندارد و بهینه است
/// زیرا:
/// - تنظیمات تم یک ترجیح محلی کاربر است
/// - نیازی به همگام‌سازی با سرور ندارد
/// - سریع و کارآمد است
/// - در همه دستگاه‌های کاربر یکسان عمل می‌کند
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themeModeKey = 'theme_mode';
  bool _isLoading = true;

  ThemeProvider() {
    _loadTheme();
  }

  /// وضعیت بارگذاری تم
  bool get isLoading => _isLoading;

  /// حالت فعلی تم
  ThemeMode get themeMode => _themeMode;

  /// آیا تم تاریک فعال است؟
  /// 
  /// **نکته**: اگر themeMode روی system باشد، این متد false برمی‌گرداند
  /// و MaterialApp خودش بر اساس تنظیمات سیستم تصمیم می‌گیرد.
  /// برای تشخیص دقیق در حالت system، از `Theme.of(context).brightness` استفاده کنید.
  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  /// تم فعلی برای استفاده در MaterialApp
  ThemeData get currentTheme {
    switch (_themeMode) {
      case ThemeMode.dark:
        return AppTheme.darkTheme;
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.system:
        // MaterialApp خودش این را مدیریت می‌کند
        return AppTheme.lightTheme;
    }
  }

  /// بارگذاری تنظیمات تم از SharedPreferences
  Future<void> _loadTheme() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);

      if (savedMode != null) {
        switch (savedMode) {
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'system':
            _themeMode = ThemeMode.system;
            break;
          default:
            _themeMode = ThemeMode.light;
        }
      } else {
        // پیش‌فرض: تم روشن
        _themeMode = ThemeMode.light;
      }
    } catch (e) {
      debugPrint('خطا در بارگذاری تم: $e');
      // در صورت خطا، از تم روشن به عنوان پیش‌فرض استفاده می‌کنیم
      _themeMode = ThemeMode.light;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تغییر تم (toggle بین light و dark)
  /// اگر در حالت system باشد، به light تغییر می‌دهد
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      // اگر system بود، به light تغییر می‌دهد
      await setThemeMode(ThemeMode.light);
    }
  }

  /// تنظیم تم به صورت مستقیم (برای سازگاری با کد قدیمی)
  Future<void> setTheme(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  /// تنظیم حالت تم
  /// 
  /// [mode]: حالت تم مورد نظر (light, dark, یا system)
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    await _saveTheme();
  }

  /// ذخیره تنظیمات تم در SharedPreferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeString;
      switch (_themeMode) {
        case ThemeMode.dark:
          modeString = 'dark';
          break;
        case ThemeMode.light:
          modeString = 'light';
          break;
        case ThemeMode.system:
          modeString = 'system';
          break;
      }
      await prefs.setString(_themeModeKey, modeString);
    } catch (e) {
      debugPrint('خطا در ذخیره تم: $e');
      // در صورت خطا، فقط لاگ می‌کنیم و ادامه می‌دهیم
      // چون این یک تنظیم غیرحیاتی است
    }
  }
}

