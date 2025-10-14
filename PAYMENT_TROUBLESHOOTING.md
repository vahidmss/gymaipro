# راهنمای حل مشکلات سیستم پرداخت

## 🔍 **مشکلات رایج و راه‌حل‌ها**

### 1. **❌ خطای "invalid merchant" از زیبال**

#### **علت:**
- API key زیبال معتبر نیست
- Merchant در حالت تست قرار دارد
- Merchant غیرفعال است

#### **راه‌حل:**
1. **ورود به پنل زیبال:**
   - به سایت [zibal.ir](https://zibal.ir) بروید
   - وارد پنل کاربری شوید

2. **دریافت API Key صحیح:**
   - در بخش "تنظیمات" → "API"
   - Merchant ID صحیح را کپی کنید

3. **به‌روزرسانی AppConfig:**
   ```dart
   // در فایل lib/config/app_config.dart
   static const String zibalMerchantId = 'MERCHANT_ID_جدید_شما';
   ```

4. **تست مجدد:**
   - اپلیکیشن را restart کنید
   - تست سریع را انجام دهید

### 2. **❌ خطای "مبلغ وارد شده نامعتبر است"**

#### **علت:**
- مبلغ کمتر از حداقل مجاز است
- فرمت مبلغ اشتباه است

#### **راه‌حل:**
- **حداقل مبلغ زیبال:** 10,000 تومان (100,000 ریال)
- **حداقل مبلغ زرین‌پال:** 1,000 تومان (10,000 ریال)

### 3. **❌ خطای اتصال به پایگاه داده**

#### **علت:**
- جداول پرداخت ایجاد نشده‌اند
- RLS policies تنظیم نشده‌اند

#### **راه‌حل:**
1. **اجرای SQL Script:**
   ```sql
   -- فایل create_payment_tables.sql را در Supabase اجرا کنید
   ```

2. **بررسی جداول:**
   - `payment_transactions`
   - `subscriptions`
   - `wallets`
   - `discount_codes`

### 4. **❌ خطای RLS (Row Level Security)**

#### **علت:**
- Policies تنظیم نشده‌اند
- کاربر دسترسی ندارد

#### **راه‌حل:**
1. **بررسی Policies:**
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'payment_transactions';
   ```

2. **ایجاد Policy:**
   ```sql
   CREATE POLICY "Users can view their own transactions" 
   ON payment_transactions FOR SELECT 
   USING (auth.uid() = user_id);
   ```

### 5. **❌ خطای "کد تخفیف نامعتبر"**

#### **علت:**
- کد تخفیف وجود ندارد
- کد منقضی شده است
- کد قبلاً استفاده شده است

#### **راه‌حل:**
1. **بررسی کدهای فعال:**
   ```sql
   SELECT * FROM discount_codes WHERE is_active = true;
   ```

2. **ایجاد کد تست:**
   ```sql
   INSERT INTO discount_codes (code, type, value, is_active) 
   VALUES ('TEST20', 'percentage', 20, true);
   ```

## 🛠️ **مراحل عیب‌یابی**

### **مرحله 1: بررسی تنظیمات**
```dart
// در AppConfig بررسی کنید:
print('Zibal Merchant ID: ${AppConfig.zibalMerchantId}');
print('Zarinpal Merchant ID: ${AppConfig.zarinpalMerchantId}');
```

### **مرحله 2: تست اتصال**
```dart
// تست مستقیم API
final response = await http.post(
  Uri.parse('https://gateway.zibal.ir/v1/request'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'merchant': 'YOUR_MERCHANT_ID',
    'amount': 100000, // 10,000 Toman
    'callbackUrl': 'https://your-app.com/callback',
  }),
);
```

### **مرحله 3: بررسی پایگاه داده**
```sql
-- بررسی وجود جداول
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'payment%';

-- بررسی RLS
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'payment_transactions';
```

## 📞 **پشتیبانی**

### **زیبال:**
- 📧 ایمیل: support@zibal.ir
- 📞 تلفن: 021-91001234
- 🌐 وب‌سایت: [zibal.ir](https://zibal.ir)

### **زرین‌پال:**
- 📧 ایمیل: support@zarinpal.com
- 📞 تلفن: 021-88665544
- 🌐 وب‌سایت: [zarinpal.com](https://zarinpal.com)

## 🔧 **نکات مهم**

1. **همیشه در حالت تست شروع کنید**
2. **API keys را در فایل‌های امن نگهداری کنید**
3. **قبل از production، تمام تست‌ها را انجام دهید**
4. **لاگ‌ها را بررسی کنید**
5. **Backup پایگاه داده داشته باشید**

## ✅ **چک‌لیست نهایی**

- [ ] API keys صحیح هستند
- [ ] جداول پایگاه داده ایجاد شده‌اند
- [ ] RLS policies تنظیم شده‌اند
- [ ] تست اتصال موفق است
- [ ] تست پرداخت موفق است
- [ ] تست کیف پول موفق است
- [ ] تست اشتراک موفق است
- [ ] تست کد تخفیف موفق است

---

**نکته:** اگر مشکل حل نشد، لاگ‌های کامل را بررسی کنید و با تیم پشتیبانی تماس بگیرید.
