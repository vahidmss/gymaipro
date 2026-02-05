# راه‌اندازی آپلود موزیک مربی

## فایل PHP

فایل `lib/services/coach_music_upload_standalone.php` باید روی سرور دانلود (`dl.gymaipro.ir`) قرار بگیرد.

## مراحل نصب

### 1. آپلود فایل

فایل `coach_music_upload_standalone.php` را به نام `upload-music.php` روی سرور آپلود کنید:

**مسیر:** `/domains/dl.gymaipro.ir/public_html/upload-music.php`

### 2. ساخت پوشه موزیک

پوشه `coaches_music` را در `public_html` ایجاد کنید:

```bash
mkdir -p /domains/dl.gymaipro.ir/public_html/coaches_music
chmod 755 /domains/dl.gymaipro.ir/public_html/coaches_music
```

### 3. تنظیم مجوزها

مطمئن شوید که PHP می‌تواند در پوشه `coaches_music` فایل بنویسد:

```bash
chown -R www-data:www-data /domains/dl.gymaipro.ir/public_html/coaches_music
chmod -R 755 /domains/dl.gymaipro.ir/public_html/coaches_music
```

### 4. تست

برای تست، می‌توانید با curl درخواست بفرستید:

```bash
curl -X POST https://dl.gymaipro.ir/upload-music.php \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-User-Id: YOUR_USER_ID" \
  -F "audio=@/path/to/test.mp3"
```

## ساختار پوشه‌ها

```
public_html/
├── upload-music.php
├── coaches_music/
│   ├── {username_1}/
│   │   ├── music_1234567890.mp3
│   │   └── music_1234567891.mp3
│   ├── {username_2}/
│   │   └── music_1234567892.mp3
│   └── ...
```

**نکته:** فولدرها با `username` مربی ساخته می‌شوند (نه user_id)

## ویژگی‌ها

- ✅ احراز هویت با JWT Token از Supabase
- ✅ بررسی role (فقط admin و trainer)
- ✅ بررسی نوع فایل (MP3, WAV, M4A, OGG, FLAC, AAC)
- ✅ بررسی حجم فایل (حداکثر 50MB)
- ✅ ذخیره در فولدر اختصاصی هر مربی (با user_id)
- ✅ CORS support برای درخواست‌های cross-origin
- ✅ مدیریت خطاهای مختلف

## پاسخ موفق

```json
{
  "success": true,
  "music_url": "https://dl.gymaipro.ir/coaches_music/{username}/music_xxx.mp3",
  "audio_url": "https://dl.gymaipro.ir/coaches_music/{username}/music_xxx.mp3",
  "url": "https://dl.gymaipro.ir/coaches_music/{username}/music_xxx.mp3",
  "file_name": "music_xxx.mp3",
  "file_size": 5879948,
  "trainer_id": "{user_id}",
  "trainer_username": "{username}",
  "uploaded_at": "2025-12-30 20:34:04"
}
```

## خطاهای ممکن

### 401 - Unauthorized
- Token نامعتبر یا منقضی شده
- Token در header موجود نیست

### 403 - Forbidden
- کاربر role مناسب ندارد (باید admin یا trainer باشد)
- پروفایل کاربر پیدا نشد

### 400 - Bad Request
- فایل ارسال نشده
- نوع فایل مجاز نیست
- حجم فایل بیش از 50MB است

### 500 - Internal Server Error
- خطا در ساخت پوشه
- خطا در انتقال فایل

