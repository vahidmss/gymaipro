# راهنمای تنظیم OTP/SMS

## ✅ تنظیمات امنیتی

تمام کلیدهای API از کد حذف شده و به environment variables منتقل شده‌اند.

## روش‌های تنظیم

### روش 1: استفاده از فایل `.env` (پیشنهادی)

1. فایل `.env.example` را کپی کنید و نام آن را به `.env` تغییر دهید:
   ```bash
   cp .env.example .env
   ```

2. فایل `.env` را باز کنید و مقادیر واقعی را وارد کنید:
   ```env
   SMS_API_BASE_URL=https://rest.payamak-panel.com/api/SendSMS/BaseServiceNumber
   SMS_API_USERNAME=1990557589
   SMS_API_PASSWORD=08918b92-394d-4d42-a2a5-8828112ded71
   SMS_API_BODY_ID=your-sms-body-id
   ```
   
   **نکته:** مقادیر بالا نمونه هستند. مقادیر واقعی را از پنل پیامک پنل دریافت کنید.

3. فایل `.env` در `.gitignore` قرار دارد و commit نمی‌شود.

### روش 2: استفاده از `--dart-define` (برای Terminal)

```bash
flutter run --dart-define=SMS_API_USERNAME=your-username --dart-define=SMS_API_PASSWORD=your-password --dart-define=SMS_API_BODY_ID=your-body-id
```

### روش 3: استفاده از VS Code

فایل `.vscode/launch.json` را باز کنید و اضافه کنید:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "gymaipro",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=SMS_API_USERNAME=your-username",
        "--dart-define=SMS_API_PASSWORD=your-password",
        "--dart-define=SMS_API_BODY_ID=your-body-id"
      ]
    }
  ]
}
```

## دریافت اطلاعات API پیامک پنل

1. به [panel.payamak-panel.com](https://panel.payamak-panel.com) بروید
2. وارد حساب کاربری شوید
3. به بخش "API" یا "Webservice" بروید
4. اطلاعات زیر را کپی کنید:
   - **Username**: نام کاربری API (احتمالاً: `1990557589`)
   - **Password**: رمز عبور API یا API ID (مثال: `08918b92-394d-4d42-a2a5-8828112ded71`)
   - **Body ID**: شناسه متن پیامک از پیش تعریف شده (از بخش "متن‌های از پیش تعریف شده" در پنل)
   
**نکته مهم:** 
- Base URL برای REST API: `https://rest.payamak-panel.com/api/SendSMS/BaseServiceNumber`
- Base URL برای SOAP API: `https://api.payamak-panel.com/post/send.asmx` (این پروژه از REST استفاده می‌کند)

## نکات مهم

⚠️ **امنیت**:
- هرگز کلیدهای API را در کد commit نکنید
- فایل `.env` در `.gitignore` قرار دارد
- برای production از secure storage استفاده کنید

📱 **فرمت شماره تلفن**:
- شماره تلفن به صورت خودکار به فرمت بین‌المللی تبدیل می‌شود
- مثال: `09123456789` → `989123456789`

🔧 **عیب‌یابی**:
- اگر پیامک ارسال نشد، لاگ‌های console را بررسی کنید
- مطمئن شوید که Body ID در پنل پیامک پنل تایید شده است
- بررسی کنید که اعتبار حساب کافی باشد

## تست

بعد از تنظیم، اپلیکیشن را **Hot Restart** کنید (نه Hot Reload) و یک OTP ارسال کنید.

در console باید این لاگ‌ها را ببینید:
```
📱 Sending SMS to: 989123456789
📝 Message: کد تایید شما: 123456
GymAI Pro
📡 SMS API Response: 200
✅ SMS sent successfully
```

## ساختار کد

- `lib/config/app_config.dart`: تنظیمات از environment variables
- `lib/services/otp_service.dart`: سرویس ارسال و تایید OTP
- `.env.example`: الگوی فایل environment variables
