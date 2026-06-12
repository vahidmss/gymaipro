import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سرویس مدیریت onboarding
class OnboardingService extends ChangeNotifier {
  factory OnboardingService() => _instance;
  OnboardingService._internal();
  static final OnboardingService _instance = OnboardingService._internal();

  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyOnboardingDontShow = 'onboarding_dont_show';
  static const String _keyOnboardingVersion = 'onboarding_version';
  static const int _currentOnboardingVersion = 1;

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _onboardingCompleted = false;
  bool _dontShowAgain = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadOnboardingStatus();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing OnboardingService: $e');
    }
  }

  /// بارگذاری وضعیت onboarding
  Future<void> _loadOnboardingStatus() async {
    try {
      _dontShowAgain = _prefs?.getBool(_keyOnboardingDontShow) ?? false;
      _onboardingCompleted = _prefs?.getBool(_keyOnboardingCompleted) ?? false;

      // بررسی نسخه onboarding
      final savedVersion = _prefs?.getInt(_keyOnboardingVersion) ?? 0;
      if (savedVersion < _currentOnboardingVersion) {
        // نسخه جدید onboarding - دوباره نمایش بده
        _onboardingCompleted = false;
        _dontShowAgain = false;
      }
    } catch (e) {
      debugPrint('Error loading onboarding status: $e');
    }
  }

  /// آیا onboarding باید نمایش داده شود؟
  bool shouldShowOnboarding() {
    // اگر کاربر تایید کرده که دیگه نشون نده، نمایش نده
    if (_dontShowAgain) return false;
    // در غیر این صورت همیشه نمایش بده (حتی اگر قبلا کامل شده)
    return true;
  }

  /// تکمیل onboarding
  Future<void> completeOnboarding({bool dontShowAgain = false}) async {
    try {
      _onboardingCompleted = true;
      _dontShowAgain = dontShowAgain;
      await _prefs?.setBool(_keyOnboardingCompleted, true);
      await _prefs?.setBool(_keyOnboardingDontShow, dontShowAgain);
      await _prefs?.setInt(_keyOnboardingVersion, _currentOnboardingVersion);
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  /// ریست onboarding (برای نمایش مجدد)
  Future<void> resetOnboarding() async {
    try {
      _onboardingCompleted = false;
      _dontShowAgain = false;
      await _prefs?.setBool(_keyOnboardingCompleted, false);
      await _prefs?.setBool(_keyOnboardingDontShow, false);
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting onboarding: $e');
    }
  }

  /// Getters
  bool get isOnboardingCompleted => _onboardingCompleted;
  bool get isInitialized => _isInitialized;
  bool get dontShowAgain => _dontShowAgain;
}

