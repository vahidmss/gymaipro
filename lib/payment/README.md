# Payment System 💳

سیستم پرداخت کامل و حرفه‌ای GymAI Pro با پشتیبانی از زیبال/زرین‌پال

## ساختار

```
payment/
├── README.md                    # این فایل
├── models/                      # مدل‌های پرداخت
│   ├── payment_transaction.dart # تراکنش پرداخت
│   ├── subscription.dart        # اشتراک
│   ├── wallet.dart             # کیف پول
│   ├── discount_code.dart      # کد تخفیف
│   └── payment_plan.dart       # طرح‌های پرداخت
├── services/                    # سرویس‌های پرداخت
│   ├── payment_gateway_service.dart    # درگاه پرداخت
│   ├── subscription_service.dart       # مدیریت اشتراک
│   ├── wallet_service.dart             # مدیریت کیف پول
│   ├── discount_service.dart           # مدیریت کد تخفیف
│   └── payment_history_service.dart    # تاریخچه پرداخت
├── screens/                     # صفحات پرداخت
│   ├── payment_screen.dart      # صفحه اصلی پرداخت
│   ├── wallet_screen.dart       # صفحه کیف پول
│   ├── subscription_screen.dart # صفحه اشتراک
│   ├── payment_history_screen.dart # تاریخچه پرداخت
│   └── payment_success_screen.dart # صفحه موفقیت پرداخت
├── widgets/                     # ویجت‌های پرداخت
│   ├── payment_method_card.dart # کارت روش پرداخت
│   ├── subscription_card.dart   # کارت اشتراک
│   ├── wallet_balance_card.dart # کارت موجودی کیف پول
│   ├── discount_input.dart      # ورودی کد تخفیف
│   └── payment_summary.dart     # خلاصه پرداخت
└── utils/                       # ابزارهای پرداخت
    ├── payment_constants.dart   # ثابت‌های پرداخت
    ├── payment_validator.dart   # اعتبارسنجی پرداخت
    └── payment_formatter.dart   # فرمت‌کننده‌های پرداخت
```

## ویژگی‌های کلیدی

### 💰 سیستم کیف پول
- شارژ کیف پول از طریق درگاه پرداخت
- پرداخت از موجودی کیف پول
- تاریخچه تراکنش‌های کیف پول
- اعتبار موجودی

### 📱 پرداخت مستقیم
- پرداخت فوری از طریق زیبال/زرین‌پال
- پرداخت برای برنامه‌های AI
- پرداخت برای خدمات مربی‌ها
- پرداخت اشتراک‌ها

### 🎫 اشتراک‌های 31 روزه
- اشتراک ماهانه (31 روز)
- تمدید خودکار
- مدیریت انقضای اشتراک
- محدودیت دسترسی بعد از انقضا

### 🎁 کدهای تخفیف
- کد تخفیف درصدی
- کد تخفیف مبلغی ثابت
- محدودیت زمانی
- محدودیت تعداد استفاده

### 📊 مدیریت مالی
- تاریخچه کامل تراکنش‌ها
- گزارش‌های مالی
- آمار درآمد و هزینه
- صدور فاکتور

## نحوه استفاده

```dart
import 'package:gymaipro/payment/index.dart';

// پرداخت مستقیم
final paymentService = PaymentGatewayService();
final result = await paymentService.processPayment(
  amount: 50000,
  description: 'خرید برنامه تمرینی AI',
  paymentMethod: PaymentMethod.direct,
);

// استفاده از کیف پول
final walletService = WalletService();
final walletResult = await walletService.payFromWallet(
  amount: 30000,
  description: 'پرداخت اشتراک ماهانه',
);

// اعمال کد تخفیف
final discountService = DiscountService();
final discount = await discountService.applyDiscountCode('SAVE20');
```

## پیکربندی درگاه پرداخت

در فایل `lib/config/app_config.dart` تنظیمات زیر را اضافه کنید:

```dart
// تنظیمات زیبال
static const String zibalMerchantId = 'YOUR_MERCHANT_ID';
static const String zibalApiKey = 'YOUR_API_KEY';

// تنظیمات زرین‌پال (اختیاری)
static const String zarinpalMerchantId = 'YOUR_MERCHANT_ID';
```

## امنیت

- رمزنگاری تمام اطلاعات حساس
- اعتبارسنجی سمت سرور
- لاگ امنیتی تراکنش‌ها
- محافظت در برابر تقلب

## پشتیبانی

این سیستم از درگاه‌های پرداخت زیر پشتیبانی می‌کند:
- ✅ زیبال (Zibal)
- ✅ زرین‌پال (ZarinPal) - اختیاری
- 🔄 سایر درگاه‌ها قابل اضافه‌سازی
