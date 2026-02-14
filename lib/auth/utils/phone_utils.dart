/// Utility functions for phone number validation and normalization
class PhoneUtils {
  /// Normalize phone number to standard format (09xxxxxxxxx)
  static String normalize(String phoneNumber) {
    String normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    normalized = normalized.replaceAll(RegExp(r'[^\d]'), '');

    if (normalized.startsWith('+98')) {
      normalized = '0${normalized.substring(3)}';
    } else if (normalized.startsWith('98')) {
      normalized = '0${normalized.substring(2)}';
    } else if (!normalized.startsWith('0')) {
      normalized = '0$normalized';
    }

    return normalized;
  }

  /// Validate Iranian phone number format (09xxxxxxxxx)
  static bool isValid(String phone) {
    final RegExp phoneRegex = RegExp(r'^09[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }
}
