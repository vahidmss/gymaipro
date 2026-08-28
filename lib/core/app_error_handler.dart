import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/core/crash_report_service.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Global error handler for the application.
///
/// In release, framework/async errors must never kill the process or leave a
/// grey/blank screen. Users always get a Persian recovery UI instead.
class AppErrorHandler {
  static void initialize() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kDebugMode) {
        return ErrorWidget(details.exception);
      }
      return const ReleaseErrorWidget();
    };

    PlatformDispatcher.instance.onError = handleUncaughtError;

    FlutterError.onError = (FlutterErrorDetails details) {
      final error = details.exception;
      final errorString = error.toString();

      if (_isSupabaseNetworkError(errorString)) {
        if (kDebugMode) {
          debugPrint(
            '=== GLOBAL ERROR HANDLER: Suppressed Supabase network error ===',
          );
          debugPrint('Error: $error');
        }
        return;
      }

      if (_isOverflowError(errorString)) {
        if (kDebugMode) {
          final match = RegExp(
            'overflowed by ([0-9.]+) pixels',
          ).firstMatch(errorString);
          if (match != null) {
            final value = double.tryParse(match.group(1) ?? '');
            if (value != null && value < 4.0) {
              FlutterError.presentError(details);
              return;
            }
          }

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
          debugPrint(
            '╚═══════════════════════════════════════════════════════════╝',
          );
          debugPrint('');
          FlutterError.presentError(details);
        }
        return;
      }

      if (kDebugMode) {
        FlutterError.presentError(details);
      } else {
        unawaited(
          CrashReportService.instance.record(
            error,
            details.stack ?? StackTrace.empty,
          ),
        );
      }
    };
  }

  /// Zone / async guard — returns true when the error was handled (swallowed).
  ///
  /// In release, always return true so an uncaught async error cannot terminate
  /// the isolate. Network/auth noise is swallowed in every mode.
  static bool handleUncaughtError(Object error, StackTrace stack) {
    final errorString = error.toString();
    if (_isSupabaseNetworkError(errorString)) {
      if (kDebugMode) {
        debugPrint(
          '=== ZONE ERROR HANDLER: Suppressed Supabase network error ===',
        );
        debugPrint('Error: $error');
      }
      return true;
    }
    if (kDebugMode) {
      debugPrint('Uncaught async error: $error');
      debugPrint('$stack');
      return false;
    }
    unawaited(CrashReportService.instance.record(error, stack));
    return true;
  }

  static bool _isSupabaseNetworkError(String errorString) {
    return errorString.contains('AuthRetryableFetchException') ||
        errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('No address associated with hostname') ||
        errorString.contains('name resolution failed') ||
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

/// User-facing fallback when a widget fails to build in release.
class ReleaseErrorWidget extends StatelessWidget {
  const ReleaseErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.maybeOf(context);
    final canPop = navigator?.canPop() ?? false;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: AppTheme.darkBackgroundColor,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppTheme.goldColor.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'مشکلی پیش آمد',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'این بخش موقتاً نمایش داده نمی‌شود. برگردید و دوباره تلاش کنید.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.5,
                    ),
                  ),
                  if (canPop) ...[
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => navigator?.pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: AppTheme.onGoldColor,
                      ),
                      child: const Text(
                        'بازگشت',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
