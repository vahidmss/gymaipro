import 'dart:ui' show TextDirection;

import 'package:flutter/material.dart' show TextAlign;

/// تشخیص جهت متن برای نمایش شبیه تلگرام
class TrainerChannelTextUtils {
  TrainerChannelTextUtils._();

  static final RegExp _rtlChar = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );
  static final RegExp _ltrChar = RegExp('[A-Za-z]');

  static bool isRtlText(String? text) {
    if (text == null || text.trim().isEmpty) return true;
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (_rtlChar.hasMatch(ch)) return true;
      if (_ltrChar.hasMatch(ch)) return false;
    }
    return true;
  }

  static TextDirection textDirectionFor(String? text) =>
      isRtlText(text) ? TextDirection.rtl : TextDirection.ltr;

  static TextAlign textAlignFor(String? text) =>
      isRtlText(text) ? TextAlign.right : TextAlign.left;
}
