import 'package:flutter/foundation.dart';

/// جلوگیری از استفادهٔ credentialهای سرور-محور در bundle کلاینت وب.
///
/// روی وب: SMS، OTP legacy، و API مستقیم درگاه (زرین‌پال) مجاز نیست.
/// OpenAI مستقیم از کلاینت — با محدودیت rate-limit — عمداً مجاز است
/// (به‌خاطر فیلترینگ سرور؛ کلید باید در OpenAI محدود شود).
class ClientSecretGuard {
  const ClientSecretGuard._();

  /// کلاینت وب — secretهای backend نباید در runtime استفاده شوند.
  static bool get isWebClient => kIsWeb;

  /// credential پیامک/OTP legacy فقط روی native و خارج از release وب.
  static bool get blocksClientSmsCredentials => kIsWeb;

  /// درخواست مستقیم API درگاه (غیر از proxy وردپرس) روی وب.
  static bool get blocksDirectPaymentGatewayApi => kIsWeb;
}
