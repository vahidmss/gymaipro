# راهنمای رفع مشکل پوش نوتیفیکیشن

## خلاصه مشکل
- اپ Edge Function `send-notifications` را صدا می‌زند.
- کد فقط از `FIREBASE_SERVICE_ACCOUNT_KEY` (رشته JSON از env) استفاده می‌کرد.
- الان تغییر داده شد: اول env را چک می‌کند، اگر خالی بود از **فایل** `GOOGLE_APPLICATION_CREDENTIALS` می‌خواند.

## چک‌لیست سکرت‌ها

| سکرت | وضعیت در docker-compose | توضیح |
|------|-------------------------|-------|
| SUPABASE_URL | ✅ از قبل هست | http://kong:8000 |
| SUPABASE_SERVICE_ROLE_KEY | ✅ از قبل هست | از .env |
| SUPABASE_DB_URL | ✅ از قبل هست | - |
| FIREBASE_PROJECT_ID | ✅ اضافه شده | خالی باشه → از فایل project_id خوانده می‌شود |
| FIREBASE_SERVICE_ACCOUNT_KEY | اختیاری | اگر خالی باشه از فایل خوانده می‌شود |
| GYM_TOPUP_SECRET | ✅ برای wallet-topup | - |
| GOOGLE_APPLICATION_CREDENTIALS | ✅ مسیر فایل | /secrets/firebase-service-account.json |

## مراحل انجام کار روی سرور

### ۱. آپدیت کد Edge Functions (فایل‌های اصلاح‌شده)
کد `send-notifications` و `send-chat-notification` اصلاح شده‌اند. باید روی سرور کپی شوند:

```bash
# از ویندوز (در مسیر پروژه gymaipro):
scp -P 9011 supabase/functions/send-notifications/index.ts root@87.248.156.175:/root/supabase/docker/volumes/functions/send-notifications/
scp -P 9011 supabase/functions/send-chat-notification/index.ts root@87.248.156.175:/root/supabase/docker/volumes/functions/send-chat-notification/
```

### ۲. اجرای تست اتصال Firebase
```bash
# روی سرور:
cd ~/supabase/docker
bash ~/test-firebase-connectivity.sh   # یا مسیر اسکریپت
```

اگر `❌ oauth2.googleapis.com قابل دسترسی نیست` دیدی: **سرور به Google دسترسی ندارد** (مثلاً به‌خاطر محدودیت در ایران). باید VPN/پروکسی روی سرور یا سرور در دیتاسنتر خارج داشته باشی.

### ۳. ریستارت functions
```bash
docker-compose restart functions
```

### ۴. تست مجدد اپ
یک خرید اشتراک مربی یا عملی که نوتیفیکیشن می‌فرستد را انجام بده.

### ۵. اگر باز کار نکرد، لاگ ببین
```bash
docker logs supabase-edge-functions -f --tail 100
```

لاگ خطاهایی مثل `FIREBASE_SERVICE_ACCOUNT_KEY not set` یا `Cannot read Firebase creds` یا خطای شبکه را نشان می‌دهد.
