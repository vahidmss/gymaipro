/// ثابت‌های سیستم پرداخت
class PaymentConstants {
  // درگاه‌های پرداخت
  static const String zibalBaseUrl = 'https://gateway.zibal.ir';
  static const String zarinpalBaseUrl =
      'https://api.zarinpal.com/pg/v4/payment';

  // URL های کامل
  static String get zibalRequestUrl => '$zibalBaseUrl$zibalRequestEndpoint';
  static String get zarinpalRequestUrl =>
      '$zarinpalBaseUrl$zarinpalRequestEndpoint';

  // اندپوینت‌های زیبال
  static const String zibalRequestEndpoint = '/v1/request';
  static const String zibalVerifyEndpoint = '/v1/verify';
  static const String zibalInquiryEndpoint = '/v1/inquiry';

  // اندپوینت‌های زرین‌پال
  static const String zarinpalRequestEndpoint = '/request.json';
  static const String zarinpalVerifyEndpoint = '/verify.json';

  // حداقل و حداکثر مبالغ (ریال)
  static const int minPaymentAmount = 10000; // 1000 تومان
  static const int maxPaymentAmount = 500000000; // 50 میلیون تومان
  static const int minWalletCharge = 10000; // 1000 تومان
  static const int maxWalletCharge = 100000000; // 10 میلیون تومان

  // تنظیمات کیف پول
  static const int defaultWalletMaxBalance = 100000000; // 10 میلیون تومان
  static const int defaultWalletMinBalance = 10000; // 1000 تومان

  // مدت زمان انقضای تراکنش (دقیقه)
  static const int transactionExpiryMinutes = 15;

  // کدهای وضعیت زیبال
  static const Map<int, String> zibalStatusCodes = {
    -2: 'خطای داخلی',
    -1: 'در انتظار پردازش',
    1: 'پرداخت شده - تاییدشده',
    2: 'پرداخت شده - تاییدنشده',
    3: 'لغوشده توسط کاربر',
    4: 'شماره کارت نامعتبر می‌باشد',
    5: 'موجودی حساب کافی نمی‌باشد',
    6: 'رمز واردشده اشتباه می‌باشد',
    7: 'تعداد درخواست‌ها بیش از حد مجاز می‌باشد',
    8: 'تعداد پرداخت روزانه بیش از حد مجاز می‌باشد',
    9: 'مبلغ پرداخت روزانه بیش از حد مجاز می‌باشد',
    10: 'صادرکننده کارت نامعتبر می‌باشد',
    11: 'خطای سوییچ',
    12: 'کارت قابل دسترسی نمی‌باشد',
    100: 'با موفقیت تایید شد',
    102: 'merchant یافت نشد',
    103: 'merchant غیرفعال',
    104: 'merchant نامعتبر',
    201: 'قبلا تایید شده',
    105: 'amount بایستی بزرگتر از 1,000 ریال باشد',
    106: 'callbackUrl نامعتبر می‌باشد. (شروع با http و یا https)',
    113: 'amount مبلغ تراکنش از سقف میزان تراکنش بیشتر است.',
  };

  // کدهای وضعیت زرین‌پال
  static const Map<int, String> zarinpalStatusCodes = {
    100: 'تراکنش موفق',
    101: 'عمل پرداخت موفق بوده و قبلا تایید شده',
    -9: 'خطای اعتبارسنجی',
    -10: 'ای پی و یا مرچنت کد پذیرنده صحیح نیست',
    -11: 'مرچنت کد فعال نیست، لطفا با تیم پشتیبانی تماس بگیرید',
    -12: 'تلاش بیش از حد در یک بازه زمانی کوتاه',
    -15: 'ترمینال شما به حالت تعلیق در آمده، با تیم پشتیبانی تماس بگیرید',
    -16: 'سطح تایید پذیرنده پایین تر از سطح نقره‌ای است',
    -17: 'محدودیت پذیرنده در سطح آبی',
    -30: 'اجازه دسترسی به تسویه اشتراکی شناور ندارید',
    -31: 'حساب بانکی تسویه را به پنل اضافه کنید',
    -32: 'مبلغ وارد شده از مبلغ کل تراکنش بیشتر است',
    -33: 'درصدهای وارد شده صحیح نیست',
    -34: 'مبلغ از کمترین مقدار قابل تسویه کمتر است',
    -35: 'تعداد افراد دریافت کننده تسهیم بیش از حد مجاز است',
    -40: 'پارامترهای اضافی نامعتبر، شیء‌های پارامتر اضافی نمی‌تواند خالی باشد',
    -50: 'مبلغ پرداخت شده با مقدار مبلغ ارسالی در متد وریفای متفاوت است',
    -51: 'پرداخت ناموفق',
    -52: 'خطای غیرمنتظره با پشتیبانی تماس بگیرید',
    -53: 'اتوریتی برای این مرچنت کد نیست',
    -54: 'اتوریتی نامعتبر است',
  };

  // پیام‌های خطا
  static const String networkError = 'خطا در اتصال به اینترنت';
  static const String serverError = 'خطا در سرور پرداخت';
  static const String invalidAmount = 'مبلغ وارد شده نامعتبر است';
  static const String paymentCancelled = 'پرداخت توسط کاربر لغو شد';
  static const String paymentFailed = 'پرداخت ناموفق بود';
  static const String insufficientBalance = 'موجودی کیف پول کافی نیست';
  static const String walletNotFound = 'کیف پول یافت نشد';
  static const String transactionNotFound = 'تراکنش یافت نشد';
  static const String invalidDiscountCode = 'کد تخفیف نامعتبر است';
  static const String expiredDiscountCode = 'کد تخفیف منقضی شده است';
  static const String usedDiscountCode = 'کد تخفیف قبلاً استفاده شده است';

  // پیام‌های موفقیت
  static const String paymentSuccess = 'پرداخت با موفقیت انجام شد';
  static const String walletCharged = 'کیف پول با موفقیت شارژ شد';
  static const String subscriptionActivated = 'اشتراک شما فعال شد';
  static const String refundProcessed = 'بازپرداخت با موفقیت انجام شد';

  // رنگ‌های وضعیت
  static const String successColor = '#4CAF50';
  static const String errorColor = '#F44336';
  static const String warningColor = '#FF9800';
  static const String infoColor = '#2196F3';
  static const String pendingColor = '#FFC107';

  // آیکون‌های وضعیت
  static const String successIcon = '✅';
  static const String errorIcon = '❌';
  static const String warningIcon = '⚠️';
  static const String infoIcon = 'ℹ️';
  static const String pendingIcon = '⏳';
  static const String walletIcon = '💰';
  static const String cardIcon = '💳';
  static const String discountIcon = '🎫';

  // فرمت‌های تاریخ
  static const String dateFormat = 'yyyy/MM/dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy/MM/dd HH:mm';

  // تنظیمات کش
  static const Duration cacheExpiry = Duration(minutes: 5);
  static const int maxCacheSize = 100;

  // تنظیمات retry
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // تنظیمات timeout
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // کلیدهای shared preferences
  static const String walletBalanceKey = 'wallet_balance';
  static const String lastSyncKey = 'last_sync';
  static const String paymentMethodKey = 'preferred_payment_method';
  static const String autoChargeKey = 'auto_charge_enabled';

  // تنظیمات نوتیفیکیشن
  static const String paymentChannelId = 'payment_notifications';
  static const String paymentChannelName = 'اعلان‌های پرداخت';
  static const String paymentChannelDescription =
      'اعلان‌های مربوط به پرداخت و تراکنش‌ها';

  // تنظیمات امنیتی
  static const String encryptionKey = 'payment_encryption_key';
  static const int tokenExpiryHours = 24;

  // محدودیت‌های عمومی
  static const int maxTransactionsPerDay = 50;
  static const int maxPaymentAmountPerDay = 1000000000; // 100 میلیون تومان
  static const int maxWalletTransactionsPerHour = 10;

  // کدهای خطای سفارشی
  static const int customErrorInsufficientBalance = 1001;
  static const int customErrorWalletNotFound = 1002;
  static const int customErrorInvalidDiscountCode = 1003;
  static const int customErrorExpiredDiscountCode = 1004;
  static const int customErrorUsedDiscountCode = 1005;
  static const int customErrorTransactionNotFound = 1006;
  static const int customErrorPaymentGatewayError = 1007;
  static const int customErrorNetworkError = 1008;
  static const int customErrorServerError = 1009;
  static const int customErrorInvalidAmount = 1010;

  // متدهای کمکی
  static String formatAmount(int amount) {
    // amount در ریال است، باید به تومان تبدیل شود (تقسیم بر 10)
    final amountInToman = (amount / 10).round();
    return '${amountInToman.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} تومان';
  }

  static String getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'در انتظار پردازش';
      case 'processing':
        return 'در حال پردازش';
      case 'completed':
        return 'تکمیل شده';
      case 'failed':
        return 'ناموفق';
      case 'cancelled':
        return 'لغو شده';
      case 'refunded':
        return 'بازپرداخت شده';
      default:
        return 'نامشخص';
    }
  }

  static String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return successColor;
      case 'failed':
      case 'cancelled':
        return errorColor;
      case 'pending':
      case 'processing':
        return pendingColor;
      case 'refunded':
        return infoColor;
      default:
        return warningColor;
    }
  }

  static String getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return successIcon;
      case 'failed':
      case 'cancelled':
        return errorIcon;
      case 'pending':
      case 'processing':
        return pendingIcon;
      case 'refunded':
        return infoIcon;
      default:
        return warningIcon;
    }
  }

  static bool isValidAmount(int amount) {
    return amount >= minPaymentAmount && amount <= maxPaymentAmount;
  }

  static bool isValidWalletChargeAmount(int amount) {
    return amount >= minWalletCharge && amount <= maxWalletCharge;
  }

  static String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN_${timestamp}_$random';
  }

  static DateTime getTransactionExpiry() {
    return DateTime.now().add(
      const Duration(minutes: transactionExpiryMinutes),
    );
  }
}

/// کلاس کمکی برای مدیریت خطاهای پرداخت
class PaymentError {
  const PaymentError({
    required this.code,
    required this.message,
    required this.timestamp,
    this.details,
  });

  factory PaymentError.insufficientBalance() {
    return PaymentError(
      code: PaymentConstants.customErrorInsufficientBalance,
      message: PaymentConstants.insufficientBalance,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentError.walletNotFound() {
    return PaymentError(
      code: PaymentConstants.customErrorWalletNotFound,
      message: PaymentConstants.walletNotFound,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentError.invalidDiscountCode() {
    return PaymentError(
      code: PaymentConstants.customErrorInvalidDiscountCode,
      message: PaymentConstants.invalidDiscountCode,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentError.networkError() {
    return PaymentError(
      code: PaymentConstants.customErrorNetworkError,
      message: PaymentConstants.networkError,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentError.serverError() {
    return PaymentError(
      code: PaymentConstants.customErrorServerError,
      message: PaymentConstants.serverError,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentError.invalidAmount() {
    return PaymentError(
      code: PaymentConstants.customErrorInvalidAmount,
      message: PaymentConstants.invalidAmount,
      timestamp: DateTime.now(),
    );
  }
  final int code;
  final String message;
  final String? details;
  final DateTime timestamp;

  @override
  String toString() {
    return 'PaymentError{code: $code, message: $message}';
  }
}
