/// Utility functions for formatting numbers and other values
class FormatUtils {
  FormatUtils._();

  /// Format number with thousand separators (e.g., 1234 -> "1,234")
  static String formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
