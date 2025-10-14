# راهنمای راه‌اندازی سیستم پرداخت GymAI Pro

## مراحل راه‌اندازی

### 1. اجرای SQL Script
ابتدا فایل `create_payment_tables.sql` را در Supabase اجرا کنید:

```sql
-- فایل create_payment_tables.sql را در Supabase SQL Editor اجرا کنید
```

### 2. تست سیستم پرداخت
برای تست سیستم پرداخت، به آدرس زیر بروید:
```
/payment-test
```

### 3. استفاده از سیستم پرداخت

#### الف) پرداخت مستقیم
```dart
import 'package:gymaipro/payment/index.dart';

// ایجاد یک برنامه پرداخت
final plan = PaymentPlan(
  id: 'plan-1',
  name: 'اشتراک ماهانه',
  description: 'دسترسی کامل به تمام ویژگی‌ها',
  type: PaymentPlanType.subscription,
  price: 50000,
  durationDays: 31,
  accessLevel: PlanAccessLevel.premium,
  features: {
    'ai_programs': true,
    'trainer_services': true,
  },
);

// هدایت به صفحه پرداخت
Navigator.pushNamed(
  context,
  '/payment',
  arguments: plan,
);
```

#### ب) استفاده از کیف پول
```dart
import 'package:gymaipro/payment/index.dart';

final walletService = WalletService();

// دریافت موجودی کیف پول
final wallet = await walletService.getUserWallet(userId);

// شارژ کیف پول
await walletService.chargeWallet(
  userId: userId,
  amount: 100000,
  description: 'شارژ کیف پول',
);

// پرداخت از کیف پول
await walletService.payFromWallet(
  userId: userId,
  amount: 50000,
  description: 'پرداخت اشتراک',
);
```

#### ج) استفاده از کد تخفیف
```dart
import 'package:gymaipro/payment/index.dart';

final discountService = DiscountService();

// اعتبارسنجی کد تخفیف
final isValid = await discountService.validateDiscountCode(
  code: 'WELCOME20',
  userId: userId,
  amount: 100000,
);

if (isValid) {
  // اعمال کد تخفیف
  final discount = await discountService.applyDiscountCode(
    code: 'WELCOME20',
    userId: userId,
    amount: 100000,
  );
}
```

### 4. مدیریت اشتراک‌ها

```dart
import 'package:gymaipro/payment/index.dart';

final subscriptionService = SubscriptionService();

// دریافت اشتراک‌های فعال
final subscriptions = await subscriptionService.getUserSubscriptions(userId);

// ایجاد اشتراک جدید
await subscriptionService.createSubscription(
  userId: userId,
  planId: 'plan-1',
  type: SubscriptionType.monthly,
  durationDays: 31,
);

// بررسی دسترسی به ویژگی‌ها
final hasAccess = await subscriptionService.hasFeatureAccess(
  userId: userId,
  feature: 'ai_programs',
);
```

### 5. یکپارچه‌سازی با صفحات موجود

#### الف) صفحه برنامه‌های AI
```dart
// در صفحه AI Programs
import 'package:gymaipro/payment/index.dart';

class AIProgramsScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PaymentIntegrationHelper.hasAIAccess(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return AIProgramsContent();
        } else {
          return PaymentRequiredWidget(
            onPay: () => PaymentIntegrationHelper.showAIProgramPayment(context),
          );
        }
      },
    );
  }
}
```

#### ب) صفحه خدمات مربی
```dart
// در صفحه Trainer Services
import 'package:gymaipro/payment/index.dart';

class TrainerServicesScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PaymentIntegrationHelper.hasTrainerAccess(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return TrainerServicesContent();
        } else {
          return PaymentRequiredWidget(
            onPay: () => PaymentIntegrationHelper.showTrainerPayment(context),
          );
        }
      },
    );
  }
}
```

### 6. تنظیمات پیشرفته

#### الف) ایجاد کد تخفیف جدید
```dart
final discountService = DiscountService();

await discountService.createDiscountCode(
  code: 'NEWYEAR50',
  type: DiscountType.percentage,
  value: 50,
  maxUsage: 100,
  minAmount: 50000,
  description: 'تخفیف سال نو - 50%',
  isNewUserOnly: false,
  expiryDate: DateTime.now().add(Duration(days: 30)),
);
```

#### ب) ایجاد برنامه پرداخت جدید
```dart
final plan = PaymentPlan(
  id: 'premium-plan',
  name: 'پلن پریمیوم',
  description: 'دسترسی کامل به تمام ویژگی‌ها',
  type: PaymentPlanType.subscription,
  price: 100000,
  durationDays: 31,
  accessLevel: PlanAccessLevel.premium,
  features: {
    'ai_programs': true,
    'trainer_services': true,
    'premium_features': true,
  },
);
```

### 7. مانیتورینگ و گزارش‌گیری

#### الف) تاریخچه پرداخت‌ها
```dart
// دریافت تاریخچه پرداخت‌ها
final history = await PaymentGatewayService().getPaymentHistory(userId);
```

#### ب) گزارش مالی
```dart
// دریافت آمار پرداخت‌ها
final stats = await PaymentGatewayService().getPaymentStatistics();
```

### 8. نکات مهم

1. **امنیت**: تمام پرداخت‌ها از طریق HTTPS انجام می‌شود
2. **لاگ‌گیری**: تمام تراکنش‌ها در پایگاه داده ثبت می‌شوند
3. **بازپرداخت**: امکان بازپرداخت از طریق کیف پول وجود دارد
4. **اعتبارسنجی**: تمام کدهای تخفیف قبل از اعمال اعتبارسنجی می‌شوند
5. **انقضا**: اشتراک‌ها بعد از 31 روز منقضی می‌شوند

### 9. عیب‌یابی

#### مشکلات رایج:
1. **خطای اتصال به درگاه**: بررسی کنید که API key صحیح باشد
2. **خطای پایگاه داده**: مطمئن شوید که جداول ایجاد شده‌اند
3. **خطای RLS**: بررسی کنید که policies صحیح تنظیم شده‌اند

#### تست سیستم:
- از صفحه `/payment-test` برای تست اتصال استفاده کنید
- تمام سرویس‌ها را تست کنید
- پرداخت نمونه انجام دهید

### 10. پشتیبانی

برای پشتیبانی فنی:
- بررسی لاگ‌های سیستم
- تست اتصال به درگاه‌ها
- بررسی وضعیت پایگاه داده
- تماس با تیم فنی

---

**نکته**: این سیستم پرداخت کاملاً یکپارچه با اپلیکیشن GymAI Pro طراحی شده و تمام ویژگی‌های مورد نیاز را پوشش می‌دهد.
