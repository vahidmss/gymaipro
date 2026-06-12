import 'dart:io';
import 'package:flutter/material.dart';

/// یک اسکنر برای بررسی خودکار overflow در کد
/// این کلاس فایل‌های Dart را اسکن می‌کند و مشکلات احتمالی overflow را پیدا می‌کند
class OverflowScanner {
  /// اسکن یک فایل برای مشکلات overflow
  static Future<List<OverflowWarning>> scanFile(String filePath) async {
    final warnings = <OverflowWarning>[];
    final file = File(filePath);

    if (!await file.exists()) {
      return warnings;
    }

    final content = await file.readAsString();
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      // بررسی Row بدون Flexible/Expanded
      if (line.contains('Row(') &&
          !line.contains('Flexible') &&
          !line.contains('Expanded') &&
          !line.contains('// ignore:') &&
          !line.contains('SafeRow')) {
        // بررسی خطوط بعدی برای Flexible/Expanded
        bool hasFlexible = false;
        for (int j = i + 1; j < lines.length && j < i + 10; j++) {
          if (lines[j].contains('Flexible') || lines[j].contains('Expanded')) {
            hasFlexible = true;
            break;
          }
          if (lines[j].contains(');') || lines[j].contains('],')) {
            break;
          }
        }

        if (!hasFlexible) {
          warnings.add(
            OverflowWarning(
              file: filePath,
              line: lineNumber,
              type: OverflowWarningType.rowWithoutFlexible,
              message: 'Row بدون Flexible/Expanded ممکن است overflow کند',
              code: line.trim(),
            ),
          );
        }
      }

      // بررسی Text بدون maxLines
      if (line.contains('Text(') &&
          !line.contains('maxLines') &&
          !line.contains('// ignore:') &&
          !line.contains('SafeText')) {
        warnings.add(
          OverflowWarning(
            file: filePath,
            line: lineNumber,
            type: OverflowWarningType.textWithoutMaxLines,
            message: 'Text بدون maxLines ممکن است overflow کند',
            code: line.trim(),
          ),
        );
      }

      // بررسی Container با عرض ثابت
      if (line.contains('Container(') &&
          line.contains('width:') &&
          !line.contains('.w') && // ScreenUtil
          !line.contains('MediaQuery') &&
          !line.contains('LayoutBuilder') &&
          !line.contains('// ignore:')) {
        warnings.add(
          OverflowWarning(
            file: filePath,
            line: lineNumber,
            type: OverflowWarningType.fixedWidthContainer,
            message: 'Container با عرض ثابت ممکن است overflow کند',
            code: line.trim(),
          ),
        );
      }

      // بررسی Column بدون SingleChildScrollView
      if (line.contains('Column(') &&
          !line.contains('SingleChildScrollView') &&
          !line.contains('SafeColumn') &&
          !line.contains('ListView') &&
          !line.contains('// ignore:')) {
        // بررسی خطوط قبلی برای SingleChildScrollView
        bool hasScrollView = false;
        for (int j = i - 1; j >= 0 && j > i - 5; j--) {
          if (lines[j].contains('SingleChildScrollView') ||
              lines[j].contains('SafeColumn')) {
            hasScrollView = true;
            break;
          }
        }

        if (!hasScrollView) {
          warnings.add(
            OverflowWarning(
              file: filePath,
              line: lineNumber,
              type: OverflowWarningType.columnWithoutScroll,
              message:
                  'Column بدون SingleChildScrollView ممکن است overflow کند',
              code: line.trim(),
            ),
          );
        }
      }
    }

    return warnings;
  }

  /// اسکن تمام فایل‌های Dart در یک دایرکتوری
  static Future<Map<String, List<OverflowWarning>>> scanDirectory(
    String directoryPath,
  ) async {
    final results = <String, List<OverflowWarning>>{};
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      return results;
    }

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // نادیده گرفتن فایل‌های test و generated
        if (entity.path.contains('test/') ||
            entity.path.contains('.g.dart') ||
            entity.path.contains('.freezed.dart')) {
          continue;
        }

        final warnings = await scanFile(entity.path);
        if (warnings.isNotEmpty) {
          results[entity.path] = warnings;
        }
      }
    }

    return results;
  }

  /// چاپ گزارش overflow
  static void printReport(Map<String, List<OverflowWarning>> results) {
    if (results.isEmpty) {
      debugPrint('✅ هیچ مشکل overflow پیدا نشد!');
      return;
    }

    debugPrint('⚠️ ${results.length} فایل با مشکل overflow پیدا شد:\n');

    for (final entry in results.entries) {
      debugPrint('📄 ${entry.key}:');
      for (final warning in entry.value) {
        debugPrint('  ⚠️ خط ${warning.line}: ${warning.message}');
        debugPrint('     کد: ${warning.code}');
      }
      debugPrint('');
    }
  }
}

/// نوع هشدار overflow
enum OverflowWarningType {
  rowWithoutFlexible,
  textWithoutMaxLines,
  fixedWidthContainer,
  columnWithoutScroll,
}

/// یک هشدار overflow
class OverflowWarning {

  OverflowWarning({
    required this.file,
    required this.line,
    required this.type,
    required this.message,
    required this.code,
  });
  final String file;
  final int line;
  final OverflowWarningType type;
  final String message;
  final String code;

  @override
  String toString() {
    return '$file:$line - $message\n  $code';
  }
}
