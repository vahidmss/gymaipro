# راهنمای دریافت API Key زیبال

## 🔑 **مراحل دریافت API Key صحیح:**

### **مرحله 1: ثبت‌نام در زیبال**
1. به سایت [zibal.ir](https://zibal.ir) بروید
2. روی "ثبت‌نام" کلیک کنید
3. اطلاعات خود را وارد کنید
4. ایمیل خود را تایید کنید

### **مرحله 2: تکمیل احراز هویت**
1. وارد پنل کاربری شوید
2. بخش "احراز هویت" را تکمیل کنید
3. مدارک مورد نیاز را آپلود کنید:
   - کارت ملی
   - شناسنامه
   - سند مالکیت یا اجاره نامه

### **مرحله 3: درخواست درگاه پرداخت**
1. در پنل کاربری، بخش "درگاه پرداخت" را انتخاب کنید
2. "درخواست درگاه جدید" را کلیک کنید
3. اطلاعات کسب و کار را وارد کنید:
   - نام کسب و کار
   - نوع فعالیت
   - آدرس وب‌سایت
   - شماره تماس

### **مرحله 4: دریافت Merchant ID**
1. پس از تایید درخواست، Merchant ID دریافت خواهید کرد
2. این کد در بخش "تنظیمات" → "API" نمایش داده می‌شود

## 🧪 **حالت تست:**

### **برای تست اولیه:**
- از Merchant ID تست استفاده کنید
- مبالغ کم (10,000 تومان) تست کنید
- در محیط development کار کنید

### **Merchant ID تست زیبال:**
```
تست: zibal_test_merchant
```

## ⚙️ **تنظیم در اپلیکیشن:**

### **1. به‌روزرسانی AppConfig:**
```dart
// در فایل lib/config/app_config.dart
static const String zibalMerchantId = 'MERCHANT_ID_جدید_شما';
```

### **2. تست اتصال:**
```dart
// تست مستقیم
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

## 🔧 **مراحل عیب‌یابی:**

### **1. بررسی Merchant ID:**
```bash
# در console اپلیکیشن
print('Current Merchant ID: ${AppConfig.zibalMerchantId}');
```

### **2. تست API:**
```bash
curl -X POST https://gateway.zibal.ir/v1/request \
  -H "Content-Type: application/json" \
  -d '{
    "merchant": "YOUR_MERCHANT_ID",
    "amount": 100000,
    "callbackUrl": "https://your-app.com/callback"
  }'
```

### **3. بررسی پاسخ:**
- **کد 100:** موفق
- **کد 104:** Merchant نامعتبر
- **کد 102:** Merchant یافت نشد

## 📞 **پشتیبانی زیبال:**

- **ایمیل:** support@zibal.ir
- **تلفن:** 021-91001234
- **تلگرام:** @zibal_support
- **سایت:** [zibal.ir](https://zibal.ir)

## ⚠️ **نکات مهم:**

1. **همیشه از Merchant ID واقعی استفاده کنید**
2. **در محیط production، از API key اصلی استفاده کنید**
3. **مبالغ تست را کم نگه دارید**
4. **لاگ‌ها را بررسی کنید**
5. **قبل از production، تمام تست‌ها را انجام دهید**

## 🎯 **مراحل بعدی:**

1. **دریافت Merchant ID صحیح**
2. **به‌روزرسانی AppConfig**
3. **تست مجدد اپلیکیشن**
4. **تایید اتصال موفق**

---

**نکته:** اگر مشکل حل نشد، با پشتیبانی زیبال تماس بگیرید و Merchant ID خود را بررسی کنید.
