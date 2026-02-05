import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Helper برای encryption و masking شماره کارت
class CardEncryptionHelper {
  /// Hash کردن شماره کارت (برای ذخیره امن)
  /// فقط 4 رقم آخر رو نگه می‌داره و بقیه رو hash می‌کنه
  static String hashCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;
    
    final last4 = cardNumber.substring(cardNumber.length - 4);
    final rest = cardNumber.substring(0, cardNumber.length - 4);
    
    // Hash کردن قسمت اول
    final bytes = utf8.encode(rest);
    final digest = sha256.convert(bytes);
    final hash = digest.toString().substring(0, 16); // 16 کاراکتر اول hash
    
    return '$hash$last4';
  }

  /// Mask کردن شماره کارت برای نمایش (فقط 4 رقم آخر)
  static String maskCardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    return '****${cardNumber.substring(cardNumber.length - 4)}';
  }

  /// بررسی اعتبار شماره کارت (Luhn algorithm)
  static bool isValidCardNumber(String cardNumber) {
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return false;
    }

    // حذف فاصله‌ها
    final cleanCard = cardNumber.replaceAll(RegExp(r'\s+'), '');
    
    if (!RegExp(r'^\d+$').hasMatch(cleanCard)) {
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleanCard.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanCard[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }

  /// فرمت کردن شماره کارت با فاصله (مثل: 1234 5678 9012 3456)
  static String formatCardNumber(String cardNumber) {
    final cleanCard = cardNumber.replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < cleanCard.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanCard[i]);
    }
    
    return buffer.toString();
  }
}

