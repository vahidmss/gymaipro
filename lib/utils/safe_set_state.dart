import 'package:flutter/material.dart';

/// Utility class for safe setState calls
class SafeSetState {
  /// Safely calls setState if the widget is still mounted
  static void call(State state, VoidCallback fn) {
    if (state.mounted) {
      state.setState(fn);
    }
  }

  /// Safely calls setState with a simple assignment if the widget is still mounted
  static void assign<T>(State state, T Function() getter, void Function(T) setter) {
    if (state.mounted) {
      state.setState(() => setter(getter()));
    }
  }
} 