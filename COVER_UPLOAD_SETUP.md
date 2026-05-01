# راه‌اندازی آپلود تصویر کاور موزیک

## فایل PHP

فایل `lib/services/coach_cover_upload_standalone.php` باید روی سرور دانلود (`dl.gymaipro.ir`) قرار بگیرد.

## ⚠️ مهم: اتصال به Supabase

سرور dl.gymaipro.ir معمولاً به IP:8000 دسترسی ندارد. باید:
1. دامنه عمومی برای Supabase راه اندازی کنی (مثلاً `api.gymaipro.ir`) — راهنما: [`SUPABASE_PUBLIC_URL_SETUP.md`](./SUPABASE_PUBLIC_URL_SETUP.md)
2. فایل `upload_config.php` را کنار `upload-cover.php` قرار بدهی و URL دامنه را در آن تنظیم کنی

## مراحل نصب

### 1. آپلود فایل

فایل `coach_cover_upload_standalone.php` را به نام `upload-cover.php` روی سرور آپلود کنید:

**مسیر:** `/domains/dl.gymaipro.ir/public_html/upload-cover.php`

### 2. ساخت پوشه کاور

پوشه `coaches_music_covers` را در `public_html` ایجاد کنید:

```bash
mkdir -p /domains/dl.gymaipro.ir/public_html/coaches_music_covers
chmod 755 /domains/dl.gymaipro.ir/public_html/coaches_music_covers
```

### 3. تنظیم مجوزها

مطمئن شوید که PHP می‌تواند در پوشه `coaches_music_covers` فایل بنویسد:

```bash
chown -R www-data:www-data /domains/dl.gymaipro.ir/public_html/coaches_music_covers
chmod -R 755 /domains/dl.gymaipro.ir/public_html/coaches_music_covers
```

### 4. تست

برای تست، می‌توانید با curl درخواست بفرستید:

```bash
curl -X POST https://dl.gymaipro.ir/upload-cover.php \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "cover=@/path/to/test.jpg"
```

## ساختار پوشه‌ها

```
public_html/
├── upload-cover.php
├── coaches_music_covers/
│   ├── {username_1}/
│   │   ├── cover_1234567890.jpg
│   │   └── cover_1234567891.png
│   ├── {username_2}/
│   │   └── cover_1234567892.jpg
│   └── ...
```

**نکته:** فولدرها با `username` مربی ساخته می‌شوند (نه user_id)

## ویژگی‌ها

- ✅ احراز هویت با JWT Token از Supabase
- ✅ بررسی role (فقط admin و trainer)
- ✅ بررسی نوع فایل (JPG, JPEG, PNG, WEBP)
- ✅ بررسی حجم فایل (حداکثر 5MB)
- ✅ ذخیره در فولدر اختصاصی هر مربی (با username)
- ✅ CORS support برای درخواست‌های cross-origin
- ✅ مدیریت خطاهای مختلف

## پاسخ موفق

```json
{
  "success": true,
  "cover_url": "https://dl.gymaipro.ir/coaches_music_covers/{username}/cover_xxx.jpg",
  "image_url": "https://dl.gymaipro.ir/coaches_music_covers/{username}/cover_xxx.jpg",
  "url": "https://dl.gymaipro.ir/coaches_music_covers/{username}/cover_xxx.jpg",
  "file_name": "cover_xxx.jpg",
  "file_size": 245678,
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
- حجم فایل بیش از 5MB است

### 500 - Internal Server Error
- خطا در ساخت پوشه
- خطا در انتقال فایل

