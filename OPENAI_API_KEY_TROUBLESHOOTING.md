# راهنمای عیب‌یابی کلید OpenAI API

## مشکل: کلید API خوانده نمی‌شود

اگر خطای زیر را می‌بینید:
```
OpenAIException: کلید OPENAI_API_KEY تنظیم نشده است
```

## راه‌حل‌ها:

### 1. Hot Restart (نه Hot Reload) ⚠️

**مهم**: `String.fromEnvironment` فقط در زمان **compile** کار می‌کند، نه runtime!

- ❌ **Hot Reload (Ctrl+F5 یا r)**: کلید API خوانده نمی‌شود
- ✅ **Hot Restart (Ctrl+Shift+F5 یا R)**: کلید API خوانده می‌شود

**مراحل**:
1. اپلیکیشن را متوقف کنید (Stop)
2. دوباره اجرا کنید (Run) یا از VS Code استفاده کنید

### 2. بررسی launch.json

مطمئن شوید که فایل `.vscode/launch.json` وجود دارد و شامل کلید API است:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "gymaipro",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=OPENAI_API_KEY=sk-proj-..."
      ]
    }
  ]
}
```

### 3. اجرا از VS Code

1. در VS Code، به بخش "Run and Debug" بروید (Ctrl+Shift+D)
2. از dropdown، "gymaipro" را انتخاب کنید
3. روی دکمه Run کلیک کنید (F5)

### 4. اجرا از Terminal

اگر از terminal استفاده می‌کنید (به‌جای `sk-proj-...` کلید خود را بگذارید):

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-proj-YOUR_KEY_HERE
```

### 5. بررسی Debug Logs

در console، باید این لاگ را ببینید:
```
OpenAI: API Key check - isEmpty: false, length: 123
OpenAI: API Key starts with: sk-proj-...
```

اگر `isEmpty: true` باشد، یعنی کلید API خوانده نشده است.

## نکات مهم:

1. **Hot Reload کار نمی‌کند**: باید Hot Restart کنید
2. **کلید API در کد نیست**: از `--dart-define` استفاده می‌شود
3. **برای هر اجرای جدید**: باید `--dart-define` را پاس دهید

## تست:

بعد از Hot Restart، یک پیام در چت AI ارسال کنید. باید پاسخ دریافت کنید و لاگ‌های debug نشان دهند که کلید API خوانده شده است.

