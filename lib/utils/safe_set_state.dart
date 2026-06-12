import 'package:flutter/material.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart' show WidgetSafetyUtils;

/// Utility class for safe setState calls
/// 
/// This is a legacy class. For new code, prefer using [WidgetSafetyUtils] 
/// which provides more comprehensive safety checks.
/// 
/// Example:
/// ```dart
/// await someAsyncOperation();
/// SafeSetState.call(this, () {
///   _someValue = newValue;
/// });
/// ```
class SafeSetState {
  /// Safely calls setState if the widget is still mounted
  static void call(State state, VoidCallback fn) {
    if (state.mounted) {
      // ignore: invalid_use_of_protected_member
      state.setState(fn);
    }
  }

  /// Safely calls setState with a simple assignment if the widget is still mounted
  static void assign<T>(State state, T Function() getter, void Function(T) setter) {
    if (state.mounted) {
      // ignore: invalid_use_of_protected_member
      state.setState(() => setter(getter()));
    }
  }
} 