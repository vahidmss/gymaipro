import 'package:flutter/services.dart';

/// کلاس اعتبارسنجی نام کاربری با استانداردهای حرفه‌ای
///
/// قوانین اعتبارسنجی:
/// - فقط حروف انگلیسی (a-z, A-Z)
/// - فقط اعداد (0-9)
/// - فقط کاراکترهای خاص مجاز: underscore (_) و hyphen (-)
/// - حداقل 3 کاراکتر
/// - حداکثر 30 کاراکتر
/// - نباید با عدد یا کاراکتر خاص شروع شود
/// - نباید با کاراکتر خاص تمام شود
/// - ممنوعیت کامل کاراکترهای فارسی
/// - ممنوعیت کامل فاصله (space)
class UsernameValidator {
  // الگوی مجاز: حروف انگلیسی، اعداد، underscore و hyphen
  // نباید با عدد یا کاراکتر خاص شروع شود
  // نباید با کاراکتر خاص تمام شود
  static final RegExp _validUsernamePattern = RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_-]{1,28}[a-zA-Z0-9]$',
  );

  // الگوی تشخیص کاراکترهای فارسی (Unicode range برای فارسی)
  static final RegExp _persianPattern = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  // الگوی تشخیص فاصله و کاراکترهای whitespace
  static final RegExp _whitespacePattern = RegExp(r'\s');

  // کاراکترهای غیرمجاز (به جز underscore و hyphen که مجاز هستند)
  static final RegExp _invalidSpecialCharsPattern = RegExp(r'[^a-zA-Z0-9_-]');

  /// بررسی اعتبار نام کاربری
  ///
  /// Returns:
  /// - null اگر نام کاربری معتبر باشد
  /// - پیام خطا اگر نام کاربری نامعتبر باشد
  static String? validate(String? username) {
    if (username == null || username.isEmpty) {
      return 'لطفاً نام کاربری را وارد کنید';
    }

    // بررسی طول
    if (username.length < 3) {
      return 'نام کاربری باید حداقل 3 کاراکتر باشد';
    }

    if (username.length > 30) {
      return 'نام کاربری نباید بیشتر از 30 کاراکتر باشد';
    }

    // بررسی کاراکترهای فارسی
    if (_persianPattern.hasMatch(username)) {
      return 'نام کاربری نمی‌تواند شامل حروف فارسی باشد';
    }

    // بررسی فاصله
    if (_whitespacePattern.hasMatch(username)) {
      return 'نام کاربری نمی‌تواند شامل فاصله باشد';
    }

    // بررسی کاراکترهای غیرمجاز
    if (_invalidSpecialCharsPattern.hasMatch(username)) {
      return 'نام کاربری فقط می‌تواند شامل حروف انگلیسی، اعداد، خط تیره (-) و زیرخط (_) باشد';
    }

    // بررسی الگوی کلی
    if (!_validUsernamePattern.hasMatch(username)) {
      // بررسی دقیق‌تر برای پیام خطای بهتر
      if (RegExp(r'^[0-9_-]').hasMatch(username)) {
        return 'نام کاربری باید با حرف انگلیسی شروع شود';
      }
      if (RegExp(r'[_-]$').hasMatch(username)) {
        return 'نام کاربری نمی‌تواند با خط تیره یا زیرخط  تمام شود';
      }
      return 'فرمت نام کاربری معتبر نیست';
    }

    return null;
  }

  /// بررسی اینکه آیا نام کاربری فقط شامل کاراکترهای مجاز است یا نه
  /// (برای استفاده در InputFormatter)
  static bool containsOnlyValidChars(String text) {
    // حذف کاراکترهای غیرمجاز
    final cleaned = text.replaceAll(_invalidSpecialCharsPattern, '');
    return cleaned == text;
  }

  /// فیلتر کردن کاراکترهای غیرمجاز از متن
  static String filterInvalidChars(String text) {
    // حذف کاراکترهای فارسی
    text = text.replaceAll(_persianPattern, '');
    // حذف فاصله‌ها
    text = text.replaceAll(_whitespacePattern, '');
    // حذف کاراکترهای خاص غیرمجاز (به جز _ و -)
    text = text.replaceAll(_invalidSpecialCharsPattern, '');
    return text;
  }

  /// بررسی اینکه آیا کاراکتر ورودی مجاز است یا نه
  static bool isValidChar(String char) {
    if (char.isEmpty) return true;
    // بررسی کاراکترهای فارسی
    if (_persianPattern.hasMatch(char)) return false;
    // بررسی فاصله
    if (_whitespacePattern.hasMatch(char)) return false;
    // بررسی کاراکترهای غیرمجاز
    if (_invalidSpecialCharsPattern.hasMatch(char)) return false;
    return true;
  }
}

/// InputFormatter برای اعمال قوانین نام کاربری در زمان تایپ
///
/// این formatter:
/// - از ورود کاراکترهای فارسی جلوگیری می‌کند
/// - از ورود فاصله جلوگیری می‌کند
/// - از ورود کاراکترهای غیرمجاز جلوگیری می‌کند
/// - فقط حروف انگلیسی، اعداد، underscore و hyphen را مجاز می‌داند
class UsernameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // اگر متن جدید خالی است، اجازه بده
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // فیلتر کردن کاراکترهای غیرمجاز
    final filteredText = UsernameValidator.filterInvalidChars(newValue.text);

    // اگر متن فیلتر شده با متن جدید متفاوت است، باید آن را اعمال کنیم
    if (filteredText != newValue.text) {
      // محاسبه موقعیت جدید cursor
      final int selectionIndex = newValue.selection.end;
      final int filteredLength = filteredText.length;
      final int originalLength = newValue.text.length;

      // محاسبه موقعیت cursor بعد از فیلتر
      int newSelectionIndex = selectionIndex;
      if (filteredLength < originalLength) {
        // اگر کاراکترهایی حذف شدند، موقعیت cursor را تنظیم کن
        final removedChars = originalLength - filteredLength;
        newSelectionIndex = (selectionIndex - removedChars).clamp(
          0,
          filteredLength,
        );
      } else {
        newSelectionIndex = selectionIndex.clamp(0, filteredLength);
      }

      return TextEditingValue(
        text: filteredText,
        selection: TextSelection.collapsed(offset: newSelectionIndex),
      );
    }

    return newValue;
  }
}
