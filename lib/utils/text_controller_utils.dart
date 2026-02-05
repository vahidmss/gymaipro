import 'package:flutter/material.dart';

/// Extension برای فراخوانی ایمن متدهای TextEditingController
/// جلوگیری از خطای "TextEditingController was used after being disposed"
extension SafeTextEditingController on TextEditingController {
  /// بررسی اینکه controller هنوز dispose نشده
  /// با استفاده از try-catch برای بررسی خطای assertion
  bool get _isDisposed {
    try {
      // تلاش برای دسترسی به text - اگر dispose شده باشد خطا می‌دهد
      final _ = text;
      // بررسی اینکه value null نیست
      final _ = value;
      return false;
    } catch (e) {
      // اگر خطای assertion یا هر خطای دیگری رخ داد، controller dispose شده
      return true;
    }
  }

  /// دسترسی ایمن به text
  String get safeText {
    if (_isDisposed) return '';
    try {
      return text;
    } catch (e) {
      return '';
    }
  }

  /// تنظیم ایمن text
  void safeSetText(String value) {
    if (_isDisposed) return;
    try {
      text = value;
    } catch (e) {
      // ignore - controller already disposed
    }
  }

  /// پاک کردن ایمن text
  void safeClear() {
    if (_isDisposed) return;
    try {
      clear();
    } catch (e) {
      // ignore - controller already disposed
    }
  }

  /// تنظیم ایمن selection
  void safeSetSelection(TextSelection selection) {
    if (_isDisposed) return;
    try {
      this.selection = selection;
    } catch (e) {
      // ignore - controller already disposed
    }
  }

  /// بررسی اینکه controller هنوز valid است
  bool get isSafe {
    return !_isDisposed;
  }
}
