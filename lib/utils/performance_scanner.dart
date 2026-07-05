import 'dart:io';

/// Static scan for high-confidence UI performance / keyboard risk patterns.
///
/// Designed for CI and `dart run test/run_ui_health_audit.dart` — low noise,
/// only flags patterns that commonly cause jank, scroll lag, or keyboard overlap.
class PerformanceScanner {
  static final _screenPathPattern = RegExp(r'[\\/](screens|widgets)[\\/]');

  /// Scan one Dart file.
  static Future<List<PerformanceWarning>> scanFile(String filePath) async {
    final warnings = <PerformanceWarning>[];
    final file = File(filePath);
    if (!await file.exists()) return warnings;

    final content = await file.readAsString();
    if (_shouldSkipFile(filePath, content)) return warnings;

    final lines = content.split('\n');
    final hasTextInput = _hasTextInput(content);
    final hasKeyboardInsetDisabled = content.contains(
      'resizeToAvoidBottomInset: false',
    );

    if (hasTextInput && hasKeyboardInsetDisabled) {
      final lineIndex = _firstMatchingLineIndex(lines, 'resizeToAvoidBottomInset: false');
      if (!_hasScannerException(lines, lineIndex, 'keyboard-inset-ok')) {
        warnings.add(
          PerformanceWarning(
            file: filePath,
            line: lineIndex + 1,
            severity: PerformanceSeverity.high,
            type: PerformanceWarningType.keyboardInsetDisabled,
            message:
                'Scaffold با resizeToAvoidBottomInset: false در کنار فیلد متنی — '
                'احتمال پوشیده شدن توسط کیبورد '
                '(اگر عمدی است: // ui-health: keyboard-inset-ok)',
          ),
        );
      }
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      if (_isShrinkWrapList(line)) {
        warnings.add(
          PerformanceWarning(
            file: filePath,
            line: lineNumber,
            severity: PerformanceSeverity.medium,
            type: PerformanceWarningType.shrinkWrapList,
            message:
                'ListView/GridView با shrinkWrap: true — معمولاً باعث لگ scroll '
                'و layout سنگین می‌شود',
            code: line.trim(),
          ),
        );
      }

      if (_isEagerListViewStart(line)) {
        final block = _readUntilClosing(lines, i);
        if (_isEagerListBody(block)) {
          warnings.add(
            PerformanceWarning(
              file: filePath,
              line: lineNumber,
              severity: _screenPathPattern.hasMatch(filePath)
                  ? PerformanceSeverity.medium
                  : PerformanceSeverity.low,
              type: PerformanceWarningType.eagerListView,
              message:
                  'ListView با children ثابت (نه builder) — برای لیست بلند '
                  'ListView.builder/separated ترجیح داده می‌شود',
              code: line.trim(),
            ),
          );
        }
      }

      if (line.contains('Image.network(') &&
          !content.contains('cached_network_image')) {
        warnings.add(
          PerformanceWarning(
            file: filePath,
            line: lineNumber,
            severity: PerformanceSeverity.low,
            type: PerformanceWarningType.uncachedNetworkImage,
            message:
                'Image.network بدون cache — برای تصاویر شبکه CachedNetworkImage '
                'بهتر است',
            code: line.trim(),
          ),
        );
        break; // one per file is enough
      }
    }

    return warnings;
  }

  static Future<Map<String, List<PerformanceWarning>>> scanDirectory(
    String directoryPath,
  ) async {
    final results = <String, List<PerformanceWarning>>{};
    final directory = Directory(directoryPath);
    if (!await directory.exists()) return results;

    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.contains('/test/') ||
          path.contains('.g.dart') ||
          path.contains('.freezed.dart') ||
          path.contains('/generated/')) {
        continue;
      }

      final warnings = await scanFile(entity.path);
      if (warnings.isNotEmpty) {
        results[entity.path] = warnings;
      }
    }

    return results;
  }

  static void printReport(Map<String, List<PerformanceWarning>> results) {
    if (results.isEmpty) {
      // ignore: avoid_print
      print('✅ PerformanceScanner: no high-confidence issues found.');
      return;
    }

    final all = results.values.expand((w) => w).toList();
    final high = all.where((w) => w.severity == PerformanceSeverity.high).length;
    final medium =
        all.where((w) => w.severity == PerformanceSeverity.medium).length;
    final low = all.where((w) => w.severity == PerformanceSeverity.low).length;

    // ignore: avoid_print
    print(
      '⚠️ PerformanceScanner: ${results.length} files, '
      '$high high / $medium medium / $low low',
    );

    final sortedEntries = results.entries.toList()
      ..sort((a, b) {
        final aMax = _maxSeverity(a.value);
        final bMax = _maxSeverity(b.value);
        return bMax.index.compareTo(aMax.index);
      });

    for (final entry in sortedEntries) {
      // ignore: avoid_print
      print('\n📄 ${entry.key}');
      for (final warning in entry.value) {
        // ignore: avoid_print
        print('  ${warning.severity.label} L${warning.line}: ${warning.message}');
        if (warning.code != null) {
          // ignore: avoid_print
          print('     ${warning.code}');
        }
      }
    }
  }

  static int countAtOrAbove(
    Map<String, List<PerformanceWarning>> results,
    PerformanceSeverity minimum,
  ) {
    return results.values
        .expand((w) => w)
        .where((w) => w.severity.index >= minimum.index)
        .length;
  }

  static bool _shouldSkipFile(String path, String content) {
    if (path.contains('performance_scanner.dart') ||
        path.contains('overflow_scanner.dart')) {
      return true;
    }
    // Generated / test harness
    if (path.contains('/test/')) return true;
    return false;
  }

  static bool _hasTextInput(String content) {
    return content.contains('TextField(') ||
        content.contains('TextFormField(') ||
        content.contains('TextEditingController') ||
        content.contains('PinCodeTextField') ||
        content.contains('PinFieldAutoFill') ||
        content.contains('pin_code_fields');
  }

  static int _firstMatchingLineIndex(List<String> lines, String needle) {
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains(needle)) return i;
    }
    return 0;
  }

  static bool _hasScannerException(
    List<String> lines,
    int lineIndex,
    String tag,
  ) {
    final marker = 'ui-health: $tag';
    for (var i = lineIndex; i >= 0 && i > lineIndex - 10; i--) {
      if (lines[i].contains(marker)) return true;
    }
    for (var i = lineIndex; i < lines.length && i < lineIndex + 10; i++) {
      if (lines[i].contains(marker)) return true;
    }
    return false;
  }

  static bool _isShrinkWrapList(String line) {
    return (line.contains('ListView') || line.contains('GridView')) &&
        line.contains('shrinkWrap: true');
  }

  static bool _isEagerListViewStart(String line) {
    if (!line.contains('ListView(')) return false;
    if (line.contains('.builder') ||
        line.contains('.separated') ||
        line.contains('CustomScrollView')) {
      return false;
    }
    return true;
  }

  static bool _isEagerListBody(String block) {
    if (block.contains('itemBuilder:') || block.contains('itemCount:')) {
      return false;
    }
    if (!block.contains('children:')) return false;
    return block.contains('List.generate(') ||
        block.contains('...') ||
        block.contains('.map(');
  }

  static String _readUntilClosing(List<String> lines, int start) {
    final buffer = StringBuffer();
    var depth = 0;
    for (var i = start; i < lines.length && i < start + 40; i++) {
      final line = lines[i];
      buffer.writeln(line);
      depth += '('.allMatches(line).length;
      depth -= ')'.allMatches(line).length;
      if (i > start && depth <= 0 && line.contains(')')) break;
    }
    return buffer.toString();
  }

  static PerformanceSeverity _maxSeverity(List<PerformanceWarning> warnings) {
    return warnings
        .map((w) => w.severity)
        .reduce((a, b) => a.index >= b.index ? a : b);
  }
}

enum PerformanceSeverity {
  low,
  medium,
  high;

  String get label => switch (this) {
        PerformanceSeverity.high => '🔴 HIGH',
        PerformanceSeverity.medium => '🟡 MED',
        PerformanceSeverity.low => '🔵 LOW',
      };
}

enum PerformanceWarningType {
  keyboardInsetDisabled,
  shrinkWrapList,
  eagerListView,
  uncachedNetworkImage,
}

class PerformanceWarning {
  PerformanceWarning({
    required this.file,
    required this.line,
    required this.severity,
    required this.type,
    required this.message,
    this.code,
  });

  final String file;
  final int line;
  final PerformanceSeverity severity;
  final PerformanceWarningType type;
  final String message;
  final String? code;
}
