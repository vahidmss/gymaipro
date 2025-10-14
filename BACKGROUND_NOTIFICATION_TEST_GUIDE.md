# راهنمای تست نوتیفیکیشن‌های Background

## 🎯 هدف
تست کردن ارسال نوتیفیکیشن پیام وقتی اپ گیرنده بسته است.

## 📱 مراحل تست

### 1. آماده‌سازی
- **دو دستگاه یا دو اکانت** داشته باشید
- **هر دو دستگاه** باید اپ را نصب کرده باشند
- **هر دو دستگاه** باید لاگین کرده باشند

### 2. بررسی تنظیمات
1. **به تنظیمات بروید** → "تست نوتیفیکیشن Background"
2. **"بررسی Device Tokens"** را بزنید
3. مطمئن شوید که device tokens ثبت شده‌اند
4. **"بررسی حضور"** را بزنید تا ببینید آیا در چت فعال هستید یا نه

### 3. تست ارسال پیام
1. **ID کاربر گیرنده** را وارد کنید
2. **پیام تست** بنویسید
3. **"ارسال پیام تست"** را بزنید
4. **اپ را کاملاً ببندید** (نه minimize)
5. **منتظر نوتیفیکیشن باشید**

## 🔍 بررسی‌های مهم

### Device Tokens
- باید `is_push_enabled: true` باشد
- باید `platform` درست باشد (android/ios)
- باید `last_seen` به‌روز باشد

### Chat Presence
- اگر در چت فعال باشید، نوتیفیکیشن ارسال نمی‌شود
- باید `is_active: false` باشد یا اصلاً حضور نداشته باشید

### Firebase Setup
- پروژه Firebase باید فعال باشد
- Service Account Key باید در Supabase تنظیم شده باشد
- FCM باید درست کار کند

## 🚨 مشکلات رایج

### 1. نوتیفیکیشن نمی‌آید
**بررسی کنید:**
- آیا device tokens ثبت شده‌اند؟
- آیا کاربر در چت فعال است؟
- آیا Firebase درست تنظیم شده؟
- آیا internet connection دارید؟

### 2. نوتیفیکیشن فقط وقتی اپ باز است می‌آید
**مشکل:** Background notification درست کار نمی‌کند
**راه حل:** بررسی Firebase Console و Edge Function logs

### 3. نوتیفیکیشن نمی‌آید حتی وقتی اپ بسته است
**بررسی کنید:**
- آیا Edge Function درست کار می‌کند؟
- آیا FCM tokens معتبر هستند؟
- آیا notification permissions داده شده؟

## 📊 Log های مهم

### Flutter Logs
```
=== CHAT SERVICE: Sending notification via Edge Function ===
=== CHAT SERVICE: Chat notification sent successfully ===
```

### Supabase Logs
```
Chat notification sent to X devices for user Y
FCM V1 token sent successfully
```

### Firebase Console
- Messages tab را بررسی کنید
- Delivery reports را چک کنید

## 🛠️ Debug Steps

### 1. بررسی Edge Function
```bash
# در Supabase Dashboard
Functions → send-chat-notification → Logs
```

### 2. بررسی Database
```sql
-- بررسی device tokens
SELECT * FROM device_tokens WHERE user_id = 'USER_ID';

-- بررسی chat presence
SELECT * FROM chat_presence WHERE user_id = 'USER_ID';
```

### 3. بررسی Firebase Console
- Project Settings → Service Accounts
- Cloud Messaging → Reports

## ✅ موفقیت
اگر نوتیفیکیشن وقتی اپ بسته است می‌آید، سیستم درست کار می‌کند!

## 🔧 تنظیمات اضافی

### Android
- `android/app/src/main/AndroidManifest.xml` باید درست باشد
- `google-services.json` باید درست باشد

### iOS
- `ios/Runner/Info.plist` باید درست باشد
- `GoogleService-Info.plist` باید درست باشد

## 📞 پشتیبانی
اگر مشکلی داشتید، log ها را بررسی کنید و مشکل را گزارش دهید.
