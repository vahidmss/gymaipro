import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';

/// تست مسیر حیاتی: منطق پول (فرمت مبلغ و اعتبارسنجی)
/// هر اشتباهی این‌جا مستقیماً روی نمایش/پرداخت پول اثر می‌گذارد.
void main() {
  group('PaymentConstants.formatAmount', () {
    test('ریال را به تومان تبدیل می‌کند (تقسیم بر 10)', () {
      expect(PaymentConstants.formatAmount(10000), '1,000 تومان');
    });

    test('جداکننده هزارگان را درست می‌گذارد', () {
      expect(PaymentConstants.formatAmount(5000000), '500,000 تومان');
      expect(PaymentConstants.formatAmount(12345670), '1,234,567 تومان');
    });

    test('صفر را درست نمایش می‌دهد', () {
      expect(PaymentConstants.formatAmount(0), '0 تومان');
    });

    test('مبالغ کوچک بدون جداکننده', () {
      expect(PaymentConstants.formatAmount(5000), '500 تومان');
    });

    test('گرد کردن هنگام تبدیل ریال به تومان', () {
      // 15 ریال => 1.5 تومان => round => 2
      expect(PaymentConstants.formatAmount(15), '2 تومان');
    });
  });

  group('PaymentConstants.isValidAmount', () {
    test('مبلغ داخل بازه مجاز', () {
      expect(PaymentConstants.isValidAmount(PaymentConstants.minPaymentAmount),
          isTrue);
      expect(PaymentConstants.isValidAmount(PaymentConstants.maxPaymentAmount),
          isTrue);
      expect(PaymentConstants.isValidAmount(1000000), isTrue);
    });

    test('مبلغ کمتر از حداقل رد می‌شود', () {
      expect(
        PaymentConstants.isValidAmount(PaymentConstants.minPaymentAmount - 1),
        isFalse,
      );
      expect(PaymentConstants.isValidAmount(0), isFalse);
    });

    test('مبلغ بیشتر از حداکثر رد می‌شود', () {
      expect(
        PaymentConstants.isValidAmount(PaymentConstants.maxPaymentAmount + 1),
        isFalse,
      );
    });
  });

  group('PaymentConstants.isValidWalletChargeAmount', () {
    test('مرزهای شارژ کیف پول', () {
      expect(
        PaymentConstants.isValidWalletChargeAmount(
          PaymentConstants.minWalletCharge,
        ),
        isTrue,
      );
      expect(
        PaymentConstants.isValidWalletChargeAmount(
          PaymentConstants.maxWalletCharge,
        ),
        isTrue,
      );
      expect(
        PaymentConstants.isValidWalletChargeAmount(
          PaymentConstants.maxWalletCharge + 1,
        ),
        isFalse,
      );
    });
  });

  group('PaymentConstants.getStatusMessage', () {
    test('نگاشت وضعیت‌های شناخته‌شده', () {
      expect(PaymentConstants.getStatusMessage('completed'), 'تکمیل شده');
      expect(PaymentConstants.getStatusMessage('failed'), 'ناموفق');
      expect(PaymentConstants.getStatusMessage('pending'), 'در انتظار پردازش');
      expect(PaymentConstants.getStatusMessage('refunded'), 'بازپرداخت شده');
    });

    test('بدون حساسیت به بزرگی/کوچکی حروف', () {
      expect(PaymentConstants.getStatusMessage('COMPLETED'), 'تکمیل شده');
      expect(PaymentConstants.getStatusMessage('Failed'), 'ناموفق');
    });

    test('وضعیت ناشناخته => نامشخص', () {
      expect(PaymentConstants.getStatusMessage('whatever'), 'نامشخص');
    });
  });

  group('PaymentConstants.generateTransactionId', () {
    test('شناسه با پیشوند TXN_ ساخته می‌شود', () {
      final id = PaymentConstants.generateTransactionId();
      expect(id.startsWith('TXN_'), isTrue);
    });
  });
}
