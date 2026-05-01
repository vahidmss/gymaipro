# راهنمای پوش نوتیفیکیشن

## تغییری که در کد اعمال شد

در **Edge Function** `send-notifications` این اصلاح انجام شد:

- **قبل:** کلاینت با `Authorization: Bearer <jwt>` ساخته می‌شد و `getUser()` بدون آرگومان صدا زده می‌شد. روی بعضی نسخه‌ها این باعث می‌شد کاربر تشخیص داده نشود و جواب **401 Unauthorized** برگردد.
- **بعد:** کلاینت فقط با **SERVICE_ROLE_KEY** ساخته می‌شود (بدون هدر JWT) و برای اعتبارسنجی کاربر از `getUser(jwt)` با همان JWT درخواست استفاده می‌شود. در نتیجه هم کاربر درست چک می‌شود هم دسترسی به جدول‌ها با service role انجام می‌شود و RLS مانع نمی‌شود.

---

## چک‌لیست وقتی دیتابیس عوض شده

### ۱) سوپابیس (دیتابیس)

- **جداول:** در پروژهٔ جدید باید این جدول‌ها وجود داشته باشند:
  - `device_tokens` — ذخیره توکن FCM هر کاربر
  - `notification_broadcast_requests` — صف/تاریخچه ارسال همگانی
  - ویو `inactive_users_7d` (یا جدول) برای ارسال به کاربران غیرفعال ۷ روز

  اگر اینها را در دیتابیس قبلی دستی ساخته بودی، در پروژهٔ جدید یا همان اسکریپت را اجرا کن یا از مایگریشن استفاده کن:
  - فایل: `supabase/migrations/20250601000000_push_notification_tables.sql`

- **ستون در `profiles`:** برای ویو `inactive_users_7d` به ستون `last_active_at` در جدول `profiles` نیاز است (در همان مایگریشن اضافه می‌شود اگر نباشد).

### ۲) سوپابیس Edge Function و Secrets

- نام تابع روی سرور باید دقیقاً **`send-notifications`** باشد (همان چیزی که اپ با `supabase.functions.invoke('send-notifications', ...)` صدا می‌زند).

- در **Supabase Dashboard** → Project Settings → Edge Functions → Secrets این دو را حتماً تنظیم کن:
  - **`FIREBASE_SERVICE_ACCOUNT_KEY`** — کلید سرویس (JSON کامل) از Firebase Console → Project Settings → Service accounts → Generate new private key.
  - **`FIREBASE_PROJECT_ID`** — همان Project ID پروژهٔ Firebase (مثلاً `gymai-9db69`). اگر ست نکنی، در کد پیش‌فرض `gymai-9db69` استفاده می‌شود؛ اگر پروژهٔ Firebase عوض شده، حتماً این را با پروژهٔ جدید یکی کن.

### ۳) فایربیس (همان پروژهٔ اپ)

- اپ (Flutter) با **همان پروژهٔ Firebase** که در اپ ثبت شده باید کار کند:
  - در اندروید: `google-services.json` همان پروژه باشد.
  - در iOS: `GoogleService-Info.plist` همان پروژه باشد.

- **Project ID** همان پروژه را در Edge Function (با `FIREBASE_PROJECT_ID`) بگذار تا FCM با همان پروژه توکن‌ها را بپذیرد.

- در Firebase Console:
  - Cloud Messaging (FCM) برای پروژه فعال باشد.
  - اگر پروژه را عوض کرده‌ای، حتماً در همان پروژهٔ جدید اپ اندروید/آی‌اواس را اضافه کن و فایل‌های بالا را از همین پروژه در اپ بگذار.

### ۴) اپ (Flutter)

- در `.env` (یا dart-define) اگر **Edge Functions** را خاموش کرده‌ای، پوش از طریق همین تابع کار نمی‌کند:
  - `SUPABASE_EDGE_FUNCTIONS_ENABLED=true` باشد (پیش‌فرض در کد `true` است؛ اگر جایی `false` گذاشته‌ای، برای پوش باید `true` باشد).

- بعد از لاگین، توکن FCM در `device_tokens` ذخیره می‌شود و کاربر روی تاپیک `all` (و زبان) subscribe می‌شود. اگر جدول `device_tokens` در پروژهٔ جدید نباشد یا RLS/SERVICE_ROLE درست نباشد، ذخیره توکن یا ارسال ممکن است شکست بخورد.

---

## جمع‌بندی

1. **کد Edge Function** با `getUser(jwt)` و استفاده از service key برای دیتابیس اصلاح شده است.
2. در **دیتابیس جدید** جدول‌ها و ویو را با مایگریشن یا اسکریپت قبلی بساز.
3. در **Supabase** نام تابع `send-notifications` و Secrets مربوط به Firebase را درست تنظیم کن.
4. در **Firebase** مطمئن شو پروژه و FCM همان پروژه‌ای است که اپ با آن (google-services / GoogleService-Info) کار می‌کند و در Edge Function همان `FIREBASE_PROJECT_ID` را استفاده می‌کنی.

اگر بعد از این هم پوش نیامد، در لاگ Edge Function (Supabase Dashboard → Edge Functions → send-notifications → Logs) خطای 401 یا 500 و جزئیات FCM را چک کن.
