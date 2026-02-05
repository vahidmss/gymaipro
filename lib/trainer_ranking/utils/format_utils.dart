/// Utility functions for formatting numbers and text in Persian
class FormatUtils {
  /// Convert English digits to Persian digits
  static String toPersianDigits(String input) {
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      final d = int.tryParse(ch);
      buffer.write(d == null ? ch : persian[d]);
    }
    return buffer.toString();
  }

  /// Format amount with thousand separators and Persian digits
  static String formatAmount(num value) {
    final s = value.toStringAsFixed(0);
    final rev = s.split('').reversed.toList();
    final out = StringBuffer();
    for (int i = 0; i < rev.length; i++) {
      if (i != 0 && i % 3 == 0) out.write(',');
      out.write(rev[i]);
    }
    final withSep = out.toString().split('').reversed.join();
    return toPersianDigits(withSep);
  }
}

