# راهنمای تنظیم کلید OpenAI API

## ✅ کلید API تنظیم شده است!

کلید API در فایل `.vscode/launch.json` تنظیم شده است و هنگام اجرا از VS Code به صورت خودکار استفاده می‌شود.

## مشکل
اگر خطای زیر را می‌بینید:
```
OpenAIException: کلید OPENAI_API_KEY تنظیم نشده است
```

این یعنی کلید API تنظیم نشده است.

## راه‌حل: تنظیم کلید API

### ✅ روش 1: استفاده از VS Code (تنظیم شده)
فایل `.vscode/launch.json` ایجاد شده و کلید API در آن تنظیم شده است. فقط از VS Code اجرا کنید.

### روش 2: استفاده از --dart-define (برای Terminal)

#### برای اجرای اپلیکیشن:
```bash
flutter run --dart-define=OPENAI_API_KEY=your-api-key-here
```

#### برای Build:
```bash
# Android
flutter build apk --dart-define=OPENAI_API_KEY=your-api-key-here

# iOS
flutter build ios --dart-define=OPENAI_API_KEY=your-api-key-here
```

### روش 2: استفاده از VS Code/Android Studio

#### در VS Code:
1. فایل `.vscode/launch.json` را باز کنید (یا ایجاد کنید)
2. اضافه کنید:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "gymaipro",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=OPENAI_API_KEY=your-api-key-here"
      ]
    }
  ]
}
```

#### در Android Studio:
1. Run > Edit Configurations
2. در قسمت "Additional run args" اضافه کنید:
```
--dart-define=OPENAI_API_KEY=your-api-key-here
```

### روش 3: استفاده از فایل .env (نیاز به پکیج flutter_dotenv)

اگر می‌خواهید از فایل `.env` استفاده کنید:

1. نصب پکیج:
```bash
flutter pub add flutter_dotenv
```

2. ایجاد فایل `.env` در root پروژه:
```
OPENAI_API_KEY=your-api-key-here
```

3. اضافه کردن `.env` به `pubspec.yaml`:
```yaml
flutter:
  assets:
    - .env
```

4. تغییر کد برای استفاده از dotenv (نیاز به تغییر در `app_config.dart`)

## دریافت کلید OpenAI API

1. به [platform.openai.com](https://platform.openai.com) بروید
2. وارد حساب کاربری شوید یا ثبت‌نام کنید
3. به بخش API Keys بروید
4. روی "Create new secret key" کلیک کنید
5. کلید را کپی کنید (فقط یک بار نمایش داده می‌شود)

## نکات امنیتی

⚠️ **مهم**: هرگز کلید API را در کد commit نکنید!

1. فایل `.env` را به `.gitignore` اضافه کنید
2. از environment variables استفاده کنید
3. برای production از secure storage استفاده کنید

## تست

بعد از تنظیم کلید، اپلیکیشن را اجرا کنید و یک پیام در چت AI ارسال کنید. باید پاسخ دریافت کنید.

