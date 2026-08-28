import 'package:flutter/services.dart';

/// نتیجهٔ دکمهٔ بازگشت وسط ثبت تمرین (لایه‌ای، نه دیالوگ خروج).
enum WorkoutBackResult {
  /// نام‌پد / تایمر استراحت بسته شد — صفحه نرو.
  consumed,

  /// لایهٔ بازی نبود — صفحه را pop کن.
  shouldPop,
}

/// بک لایه‌ای: اول overlay (نام‌پد، تایمر)، بعد خروج از صفحه.
abstract final class WorkoutBackLayer {
  static WorkoutBackResult handle({
    required bool numpadOpen,
    required bool restActive,
    required void Function() closeNumpad,
    required void Function() dismissRest,
  }) {
    if (numpadOpen) {
      HapticFeedback.selectionClick();
      closeNumpad();
      return WorkoutBackResult.consumed;
    }
    if (restActive) {
      HapticFeedback.selectionClick();
      dismissRest();
      return WorkoutBackResult.consumed;
    }
    return WorkoutBackResult.shouldPop;
  }
}
