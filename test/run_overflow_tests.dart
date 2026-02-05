import 'dart:io';
import 'package:gymaipro/utils/overflow_scanner.dart';

/// اسکریپت برای اجرای تست‌های overflow و اسکن کد
/// این فایل می‌تواند به صورت مستقیم اجرا شود
void main() async {
  print('🔍 شروع بررسی overflow در پروژه...\n');

  // اسکن دایرکتوری lib
  print('📂 اسکن فایل‌های Dart در lib/...');
  final results = await OverflowScanner.scanDirectory('lib');

  // چاپ گزارش
  OverflowScanner.printReport(results);

  // خلاصه
  final totalWarnings = results.values.fold<int>(
    0,
    (sum, warnings) => sum + warnings.length,
  );

  if (totalWarnings == 0) {
    print('✅ هیچ مشکل overflow پیدا نشد!');
    exit(0);
  } else {
    print('⚠️ مجموعاً $totalWarnings هشدار overflow پیدا شد.');
    print('لطفاً فایل‌های بالا را بررسی و رفع کنید.');
    exit(1);
  }
}
