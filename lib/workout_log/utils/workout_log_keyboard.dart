import 'package:flutter/material.dart';

/// بستن مطمئن کیبورد بدون چندبار hide کردن IME (علت لگ روی اندروید).
abstract final class WorkoutLogKeyboard {
  /// فقط فوکوس فعال را آزاد می‌کند — یک درخواست hide به سیستم.
  static void dismiss(BuildContext context) {
    final scope = FocusScope.of(context);
    if (!scope.hasPrimaryFocus && !scope.hasFocus) return;

    if (scope.hasPrimaryFocus) {
      scope.unfocus();
      return;
    }

    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary.hasFocus) {
      primary.unfocus();
    }
  }

  /// بعد از settle شدن IME اجرا می‌شود (مثلاً قبل از bottom sheet).
  static void runAfterKeyboardDismissed(
    BuildContext context,
    VoidCallback action,
  ) {
    dismiss(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        action();
      });
    });
  }
}
