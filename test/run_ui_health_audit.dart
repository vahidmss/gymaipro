import 'dart:io';

import 'package:gymaipro/utils/overflow_scanner.dart';
import 'package:gymaipro/utils/performance_scanner.dart';

/// One-command UI health audit (static analysis).
///
/// Usage:
///   dart run test/run_ui_health_audit.dart          # report only
///   dart run test/run_ui_health_audit.dart --gate  # fail on HIGH (CI)
///   dart run test/run_ui_health_audit.dart --strict # fail on MED+ (CI)
///   dart run test/run_ui_health_audit.dart --advisory
Future<void> main(List<String> args) async {
  final includeOverflow = args.contains('--advisory');
  final strict = args.contains('--strict');
  final gate = args.contains('--gate') || strict;

  stdout.writeln('═══════════════════════════════════════════');
  stdout.writeln('  GymaiPro UI Health Audit');
  stdout.writeln('═══════════════════════════════════════════\n');

  stdout.writeln('🔍 Performance scan (lib/)...');
  final perfResults = await PerformanceScanner.scanDirectory('lib');
  PerformanceScanner.printReport(perfResults);

  final highCount = PerformanceScanner.countAtOrAbove(
    perfResults,
    PerformanceSeverity.high,
  );
  final mediumCount = PerformanceScanner.countAtOrAbove(
    perfResults,
    PerformanceSeverity.medium,
  );

  var overflowWarnings = 0;
  if (includeOverflow) {
    stdout.writeln('\n🔍 Overflow advisory scan (lib/)...');
    stdout.writeln('   (noisy — Text/Row heuristics; use --advisory only)\n');
    final overflowResults = await OverflowScanner.scanDirectory('lib');
    OverflowScanner.printReport(overflowResults);
    overflowWarnings = overflowResults.values.fold<int>(
      0,
      (sum, w) => sum + w.length,
    );
  } else {
    stdout.writeln(
      '\nℹ️  Overflow scan skipped (very noisy). '
      'Pass --advisory to include.',
    );
  }

  stdout.writeln('\n───────────────────────────────────────────');
  stdout.writeln('Summary');
  stdout.writeln('  Performance HIGH:   $highCount');
  stdout.writeln('  Performance MED+:   $mediumCount');
  if (includeOverflow) {
    stdout.writeln('  Overflow advisory:  $overflowWarnings');
  }
  stdout.writeln('───────────────────────────────────────────');
  stdout.writeln(
    'Runtime jank: run debug build — PerformanceMonitor logs every 30s.',
  );
  stdout.writeln(
    'Widget smoke:   flutter test test/ui_health_smoke_test.dart',
  );

  final failOnHigh = gate && highCount > 0;
  final failOnStrict = strict && mediumCount > 0;

  if (!gate && highCount > 0) {
    stdout.writeln(
      '\nℹ️  $highCount HIGH issue(s) reported (not blocking). '
      'Use --gate for CI.',
    );
  }

  if (failOnHigh || failOnStrict) {
    stdout.writeln('\n❌ UI health audit failed.');
    exit(1);
  }

  stdout.writeln('\n✅ UI health audit passed (no blocking issues).');
  exit(0);
}
