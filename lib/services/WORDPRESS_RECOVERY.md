# بازیابی سایت بعد از خطای بحرانی وردپرس

## فوری — غیرفعال کردن snippet

### روش 1: پلاگین Code Snippets
1. اگر به پیشخوان دسترسی داری: **Snippets** → snippet مربوط به GymAI را **غیرفعال** کن
2. اگر پیشخوان باز نمی‌شود: FTP/cPanel →  
   `wp-content/plugins/code-snippets/`  
   پوشه را موقتاً rename کن به `code-snippets-OFF`

### روش 2: wp-config
در `wp-config.php` قبل از `/* That's all */` اضافه کن:
```php
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
```
لاگ: `wp-content/debug.log`

---

## نصب مجدد (نسخه امن)

### Snippet A — REST (همه جا)
فایل: `CODE_SNIPPET_0_REST_META.php`  
محل اجرا: **Run everywhere**

### Snippet B — Seed (فقط مدیریت)
فایل: `CODE_SNIPPET_1_SEED.php` (نسخه امن جدید)  
محل اجرا: **Only administration area**  
سپس: **ابزارها → GymAI Seed → Run Seed Now**

> نسخه قبلی Seed خودکار در `admin_init` باعث timeout یا تداخل با پلاگین GYMAI Seeder می‌شد — حذف شد.

---

## علت‌های محتمل خطا

1. ثبت دوباره `register_post_meta` (تداخل با GYMAI Exercises Seeder)
2. Seed خودکار روی هر بار لود پیشخوان + `wp_update_post`
3. Syntax `??` روی PHP قدیمی‌تر از 7
4. Snippet 2 متاباکس خراب (براکت کم)

Snippet 2 را تا زمانی که Seed موفق نشد **فعال نکن**.
