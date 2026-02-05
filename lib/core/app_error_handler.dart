import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global error handler for the application
/// Handles and suppresses Supabase network errors and overflow errors to prevent crashes
class AppErrorHandler {
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      final error = details.exception;
      final errorString = error.toString();

      // Suppress Supabase auth network errors
      if (_isSupabaseNetworkError(errorString)) {
        if (kDebugMode) {
          debugPrint(
            '=== GLOBAL ERROR HANDLER: Suppressed Supabase network error ===',
          );
          debugPrint('Error: $error');
        }
        return;
      }

      // Handle overflow errors - log them in debug mode but don't crash
      if (_isOverflowError(errorString)) {
        if (kDebugMode) {
          // نمایش واضح overflow error
          debugPrint('');
          debugPrint(
            '╔═══════════════════════════════════════════════════════════╗',
          );
          debugPrint(
            '║  ⚠️  OVERFLOW ERROR DETECTED! ⚠️                        ║',
          );
          debugPrint(
            '╠═══════════════════════════════════════════════════════════╣',
          );
          debugPrint('║ Error: $error');
          debugPrint('║');
          debugPrint('║ Stack Trace:');
          if (details.stack != null) {
            final stackLines = details.stack.toString().split('\n');
            for (var i = 0; i < stackLines.length && i < 10; i++) {
              debugPrint('║   ${stackLines[i]}');
            }
            if (stackLines.length > 10) {
              debugPrint('║   ... (${stackLines.length - 10} more lines)');
            }
          }
          debugPrint('║');
          debugPrint(
            '║ 💡 Fix: Use SafeRow, SafeColumn, or wrap Text in Flexible',
          );
          debugPrint('║ 📖 See: OVERFLOW_PREVENTION_GUIDE.md');
          debugPrint(
            '╚═══════════════════════════════════════════════════════════╝',
          );
          debugPrint('');

          // Also show in console with FlutterError.presentError for better visibility
          FlutterError.presentError(details);
        }
        // Don't crash the app - errors are handled gracefully by safe widgets
        return;
      }

      // Let other errors be handled normally
      FlutterError.presentError(details);
    };
  }

  static bool _isSupabaseNetworkError(String errorString) {
    return errorString.contains('AuthRetryableFetchException') ||
        errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('No address associated with hostname') ||
        errorString.contains('ClientException');
  }

  static bool _isOverflowError(String errorString) {
    return errorString.contains('RenderFlex overflowed') ||
        errorString.contains('A RenderFlex overflowed') ||
        errorString.contains('overflowed by') ||
        errorString.contains('pixels') && errorString.contains('overflow') ||
        errorString.contains('RenderBox') && errorString.contains('overflow');
  }
}
