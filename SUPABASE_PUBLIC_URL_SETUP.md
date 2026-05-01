# راه‌اندازی دامنه عمومی برای Supabase (برای آپلود از dl.gymaipro.ir)

## مشکل
سرور `dl.gymaipro.ir` نمی‌تواند به `87.248.156.175:8000` وصل شود (فایروال / محدودیت شبکه).  
اسکریپت‌های آپلود (کاور، موزیک، ویدیو) روی dl باید Supabase را چک کنند → بدون اتصال، همیشه 401 می‌گیرند.

## راه‌حل
Supabase را از طریق **دامنه عمومی روی HTTPS (پورت ۴۴۳)** در دسترس کن. اکثر هاست‌ها اجازه اتصال به پورت ۴۴۳ را می‌دهند.

---

## مراحل

### ۱. ساخت subdomain برای Supabase
یک subdomain مثل `api.gymaipro.ir` بساز و آن را به IP سرور Supabase (`87.248.156.175`) نشانه‌گیری کن (A record).

### ۲. نصب SSL (اختیاری ولی توصیه می‌شود)
با Let's Encrypt یا سرویس هاست، برای `api.gymaipro.ir` گواهی SSL بگیر.

### ۳. پیکربندی Nginx روی سرور Supabase
روی سرور `87.248.156.175` یک بلوک `server` برای `api.gymaipro.ir` اضافه کن که به Kong:8000 پراکسی کند:

```nginx
server {
    listen 80;
    server_name api.gymaipro.ir;
    # اختیاری: ریدایرکت به HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name api.gymaipro.ir;

    ssl_certificate /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

بعد از اعمال تنظیمات، `nginx -t` و `systemctl reload nginx` (یا معادل آن) را اجرا کن.

### ۴. تست دسترسی
از مرورگر یا curl تست کن:

```bash
curl -s https://api.gymaipro.ir/auth/v1/health
```

باید یک پاسخ JSON (مثلاً `{"status":"ok"}`) برگردد.

### ۵. تنظیم upload_config.php
فایل `upload_config.php` را کنار اسکریپت‌های آپلود روی dl قرار بده:

```php
<?php
return [
    'supabase_url' => 'https://api.gymaipro.ir',
    'supabase_anon_key' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
];
```

### ۶. آپلود فایل‌ها روی dl
این فایل‌ها را در همان پوشه‌ای که `upload-cover.php` و `upload-music.php` قرار دارند آپلود کن:
- `upload_config.php`

### ۷. تست مجدد
`test-supabase.php` را اجرا کن. باید `"success": true` و `"http_code": 200` ببینی. بعد آن را حذف کن.

---

## نکته
اپ موبایل همچنان می‌تواند از `http://87.248.156.175:8000` استفاده کند؛ تغییر فقط برای اسکریپت‌های PHP روی dl است که از داخل شبکه هاست اجرا می‌شوند.
