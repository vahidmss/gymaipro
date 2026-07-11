import 'package:flutter/foundation.dart';
import 'package:sms_autofill/sms_autofill.dart' as sms;

/// کمک‌کنندهٔ autofill کد OTP (Android SMS Retriever + iOS oneTimeCode).
class OtpAutofillHelper {
  OtpAutofillHelper._();

  static const int codeLength = 6;
  static const String smsCodeRegexPattern = r'\d{6}';

  /// متن ارسالی به Payamak وقتی bodyId (الگو) فعال است.
  /// مقدار باید شامل خط جداگانهٔ hash در انتها باشد تا SMS Retriever کار کند.
  static String payamakPatternText(String code, String? appSignature) {
    if (appSignature != null && appSignature.isNotEmpty) {
      return '$code\n$appSignature';
    }
    return code;
  }

  /// متن آزاد وقتی bodyId غیرفعال است.
  static String freeTextMessage(String code, String? appSignature) {
    if (appSignature != null && appSignature.isNotEmpty) {
      return '<#> کد تایید جیم‌آی: $code\n$appSignature';
    }
    return 'کد تایید شما: $code\nGymAI Pro';
  }

  static Future<String?> fetchAppSignature() async {
    if (kIsWeb) return null;
    try {
      final signature = await sms.SmsAutoFill().getAppSignature;
      if (signature.isEmpty) return null;
      debugPrint('📱 OTP app signature: $signature');
      return signature;
    } catch (e) {
      debugPrint('⚠️ OTP app signature error: $e');
      return null;
    }
  }

  static String? extractDigits(String? raw, {int length = codeLength}) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp('\\d{$length}').firstMatch(raw);
    if (match != null) return match.group(0);
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= length ? digitsOnly.substring(0, length) : null;
  }

  static Future<void> primeNativeListener() async {
    if (kIsWeb) return;
    try {
      await fetchAppSignature();
      await sms.SmsAutoFill().listenForCode(
        smsCodeRegexPattern: smsCodeRegexPattern,
      );
    } catch (e) {
      debugPrint('⚠️ OTP prime listener error: $e');
    }
  }

  static Future<void> restartNativeListener(
    Future<void> Function() cancelSubscription,
    void Function({String? smsCodeRegexPattern}) startListening,
  ) async {
    if (kIsWeb) return;
    try {
      await cancelSubscription();
      await sms.SmsAutoFill().unregisterListener();
      startListening(smsCodeRegexPattern: smsCodeRegexPattern);
    } catch (e) {
      debugPrint('⚠️ OTP listener restart error: $e');
    }
  }
}
