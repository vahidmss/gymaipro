import 'package:flutter/material.dart';

/// Utility functions for safe widget operations
/// Prevents "widget unmounted" errors by checking mounted state before operations
class WidgetSafetyUtils {
  /// Safely calls setState if the widget is still mounted
  static void safeSetState(State state, VoidCallback fn) {
    if (state.mounted) {
      // ignore: invalid_use_of_protected_member
      state.setState(fn);
    }
  }

  /// Safely calls setState with a value assignment
  static void safeSetStateValue<T>(
    State state,
    T Function() getter,
    void Function(T) setter,
  ) {
    if (state.mounted) {
      // ignore: invalid_use_of_protected_member
      state.setState(() => setter(getter()));
    }
  }

  /// Safely navigates if context is still valid
  static void safeNavigate(BuildContext? context, Widget Function() builder) {
    if (context != null && context.mounted) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => builder()),
      );
    }
  }

  /// Safely navigates and replaces current route
  static void safeNavigateReplacement(
    BuildContext? context,
    Widget Function() builder,
  ) {
    if (context != null && context.mounted) {
      Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(builder: (_) => builder()),
      );
    }
  }

  /// Safely navigates using named route and removes routes until predicate
  static void safePushNamedAndRemoveUntil(
    BuildContext? context,
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) {
    if (context != null && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        routeName,
        predicate,
        arguments: arguments,
      );
    }
  }

  /// Safely navigates using named route and replaces current route
  static void safePushReplacementNamed(
    BuildContext? context,
    String routeName, {
    Object? arguments,
    Object? result,
  }) {
    if (context != null && context.mounted) {
      Navigator.pushReplacementNamed(
        context,
        routeName,
        arguments: arguments,
        result: result,
      );
    }
  }

  /// Safely pops navigation
  static void safePop(BuildContext? context, [dynamic result]) {
    if (context != null && context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  /// Safely shows a SnackBar
  static void safeShowSnackBar(
    BuildContext? context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
  }) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration ?? const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Safely shows a dialog
  static Future<T?> safeShowDialog<T>({
    required BuildContext? context,
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
  }) {
    if (context != null && context.mounted) {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: builder,
      );
    }
    return Future<T?>.value();
  }

  /// Safely shows a modal bottom sheet
  static Future<T?> safeShowModalBottomSheet<T>({
    required BuildContext? context,
    required Widget Function(BuildContext) builder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
    Color? backgroundColor,
    Color? barrierColor,
    bool useSafeArea = false,
  }) {
    if (context != null && context.mounted) {
      return showModalBottomSheet<T>(
        context: context,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        isScrollControlled: isScrollControlled,
        backgroundColor: backgroundColor,
        barrierColor: barrierColor,
        useSafeArea: useSafeArea,
        builder: builder,
      );
    }
    return Future<T?>.value();
  }

  /// Safely executes a callback if context is still valid
  static void safeExecute(BuildContext? context, VoidCallback callback) {
    if (context != null && context.mounted) {
      callback();
    }
  }

  /// Safely executes an async callback if context is still valid
  static Future<void> safeExecuteAsync(
    BuildContext? context,
    Future<void> Function() callback,
  ) async {
    if (context != null && context.mounted) {
      await callback();
    }
  }

  /// Safely gets ScaffoldMessenger
  static ScaffoldMessengerState? safeGetScaffoldMessenger(
    BuildContext? context,
  ) {
    if (context != null && context.mounted) {
      try {
        return ScaffoldMessenger.of(context);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Safely gets Navigator
  static NavigatorState? safeGetNavigator(BuildContext? context) {
    if (context != null && context.mounted) {
      try {
        return Navigator.of(context);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Safely unfocuses keyboard
  static void safeUnfocus(BuildContext? context) {
    if (context != null && context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  /// Safely requests focus
  static void safeRequestFocus(BuildContext? context, FocusNode focusNode) {
    if (context != null && context.mounted) {
      FocusScope.of(context).requestFocus(focusNode);
    }
  }

  /// Safely checks if state is mounted before async operations
  /// Returns true if mounted, false otherwise
  /// Use this at the start of async methods to prevent operations on disposed widgets
  /// 
  /// Example:
  /// ```dart
  /// Future<void> _load() async {
  ///   if (!WidgetSafetyUtils.isMounted(this)) return;
  ///   // ... rest of async code
  /// }
  /// ```
  static bool isMounted(State state) {
    return state.mounted;
  }
}
