import 'package:flutter/foundation.dart';
import 'package:gymaipro/guide/models/guide_sequence.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سرویس مدیریت راهنما و feature tour
class GuideService extends ChangeNotifier {
  static final GuideService _instance = GuideService._internal();
  factory GuideService() => _instance;
  GuideService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // راهنماهای فعال
  final Map<String, GuideSequence> _guides = {};

  // وضعیت نمایش راهنماها
  final Map<String, bool> _completedGuides = {};
  final Map<String, bool> _dontShowGuides = {}; // راهنماهایی که کاربر تایید کرده دیگه نشون نده
  final Map<String, int> _guideViewCounts = {};

  // راهنمای در حال نمایش
  GuideSequence? _activeGuide;
  int _currentStepIndex = 0;

  String? _pendingForcedGuideId;
  bool _pendingOpenDrawer = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCompletedGuides();
      await _loadViewCounts();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing GuideService: $e');
    }
  }

  /// بارگذاری راهنماهای تکمیل شده از حافظه
  Future<void> _loadCompletedGuides() async {
    try {
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith('guide_completed_')) {
          final guideId = key.replaceFirst('guide_completed_', '');
          _completedGuides[guideId] = _prefs?.getBool(key) ?? false;
        }
        if (key.startsWith('guide_dont_show_')) {
          final guideId = key.replaceFirst('guide_dont_show_', '');
          _dontShowGuides[guideId] = _prefs?.getBool(key) ?? false;
        }
      }
    } catch (e) {
      debugPrint('Error loading completed guides: $e');
    }
  }

  /// بارگذاری تعداد نمایش راهنماها
  Future<void> _loadViewCounts() async {
    try {
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith('guide_view_count_')) {
          final guideId = key.replaceFirst('guide_view_count_', '');
          _guideViewCounts[guideId] = _prefs?.getInt(key) ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading view counts: $e');
    }
  }

  /// ثبت یک راهنما
  void registerGuide(GuideSequence guide) {
    _guides[guide.id] = guide;
    notifyListeners();
  }

  GuideSequence? getGuide(String guideId) => _guides[guideId];

  void setPendingForcedGuide(String guideId, {bool openDrawer = false}) {
    _pendingForcedGuideId = guideId;
    _pendingOpenDrawer = openDrawer;
    notifyListeners();
  }

  String? peekPendingForcedGuide() => _pendingForcedGuideId;

  bool get pendingOpenDrawer => _pendingOpenDrawer;

  (String, bool)? consumePendingForcedGuide() {
    final id = _pendingForcedGuideId;
    if (id == null) return null;
    final openDrawer = _pendingOpenDrawer;
    _pendingForcedGuideId = null;
    _pendingOpenDrawer = false;
    notifyListeners();
    return (id, openDrawer);
  }

  /// بدون شروع تور: دیگر این راهنما را خودکار پیشنهاد نکن
  Future<void> suppressGuide(String guideId) async {
    _dontShowGuides[guideId] = true;
    await _prefs?.setBool('guide_dont_show_$guideId', true);
    notifyListeners();
  }

  /// حذف ثبت یک راهنما
  void unregisterGuide(String guideId) {
    _guides.remove(guideId);
    notifyListeners();
  }

  /// آیا راهنمایی باید نمایش داده شود؟
  bool shouldShowGuide(String guideId) {
    final guide = _guides[guideId];
    if (guide == null) return false;

    // اگر کاربر تایید کرده که دیگه نشون نده، نمایش نده
    if (_dontShowGuides[guideId] == true) {
      return false;
    }

    // بررسی پیش‌نیاز
    if (guide.prerequisiteId != null) {
      if (!isGuideCompleted(guide.prerequisiteId!)) {
        return false;
      }
    }

    // تورهای یک‌بار مصرف بعد از اتمام دیگر خودکار پیشنهاد نمی‌شوند
    if (guide.showOnce && isGuideCompleted(guideId)) {
      return false;
    }

    return true;
  }

  /// آیا راهنما تکمیل شده؟
  bool isGuideCompleted(String guideId) {
    return _completedGuides[guideId] ?? false;
  }

  /// تعداد دفعات نمایش راهنما
  int getViewCount(String guideId) {
    return _guideViewCounts[guideId] ?? 0;
  }

  /// شروع یک راهنما
  Future<void> startGuide(String guideId) async {
    final guide = _guides[guideId];
    if (guide == null) return;

    _activeGuide = guide;
    _currentStepIndex = 0;

    // افزایش تعداد نمایش
    final currentCount = getViewCount(guideId);
    _guideViewCounts[guideId] = currentCount + 1;
    await _prefs?.setInt('guide_view_count_$guideId', currentCount + 1);

    notifyListeners();
  }

  /// رفتن به مرحله بعدی
  bool nextStep() {
    if (_activeGuide == null) return false;

    if (_currentStepIndex < _activeGuide!.stepCount - 1) {
      _currentStepIndex++;
      notifyListeners();
      return true;
    }

    return false;
  }

  /// برگشت به مرحله قبلی
  bool previousStep() {
    if (_activeGuide == null) return false;

    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
      return true;
    }

    return false;
  }

  /// رفتن به مرحله خاص
  bool goToStep(int index) {
    if (_activeGuide == null) return false;

    if (index >= 0 && index < _activeGuide!.stepCount) {
      _currentStepIndex = index;
      notifyListeners();
      return true;
    }

    return false;
  }

  /// اتمام راهنما
  Future<void> completeGuide({bool dontShowAgain = false}) async {
    if (_activeGuide == null) return;

    final guideId = _activeGuide!.id;
    _completedGuides[guideId] = true;
    _dontShowGuides[guideId] = dontShowAgain;
    await _prefs?.setBool('guide_completed_$guideId', true);
    await _prefs?.setBool('guide_dont_show_$guideId', dontShowAgain);

    _activeGuide = null;
    _currentStepIndex = 0;

    notifyListeners();
  }

  /// لغو راهنما (بدون ثبت complete)
  void cancelGuide() {
    _activeGuide = null;
    _currentStepIndex = 0;
    notifyListeners();
  }

  /// رد کردن راهنما (ثبت به عنوان completed)
  Future<void> skipGuide({bool dontShowAgain = false}) async {
    await completeGuide(dontShowAgain: dontShowAgain);
  }

  /// ریست کردن یک راهنما (برای نمایش مجدد)
  Future<void> resetGuide(String guideId) async {
    _completedGuides[guideId] = false;
    _dontShowGuides[guideId] = false;
    await _prefs?.setBool('guide_completed_$guideId', false);
    await _prefs?.setBool('guide_dont_show_$guideId', false);

    _guideViewCounts[guideId] = 0;
    await _prefs?.setInt('guide_view_count_$guideId', 0);

    notifyListeners();
  }

  /// ریست کردن تمام راهنماها
  Future<void> resetAllGuides() async {
    for (final guideId in _guides.keys) {
      await resetGuide(guideId);
    }
    notifyListeners();
  }

  /// Getters
  GuideSequence? get activeGuide => _activeGuide;
  int get currentStepIndex => _currentStepIndex;
  bool get hasActiveGuide => _activeGuide != null;
  bool get isFirstStep => _currentStepIndex == 0;
  bool get isLastStep =>
      _activeGuide != null &&
      _currentStepIndex == _activeGuide!.stepCount - 1;

  int get totalSteps => _activeGuide?.stepCount ?? 0;

  double get progress {
    if (_activeGuide == null || _activeGuide!.stepCount == 0) return 0;
    return (_currentStepIndex + 1) / _activeGuide!.stepCount;
  }
}

