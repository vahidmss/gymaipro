# سایت down شد — بازیابی فوری

## الان (بدون پیشخوان)

این کارها را **به ترتیب** در File Manager / FTP انجام بده:

### ۱. خاموش کردن snippet
در `wp-config.php` قبل از `/* That's all */` اضافه کن:

```php
define('CODE_SNIPPETS_SAFE_MODE', true);
```

### ۲. خاموش کردن پلاگین GymAI 20
پوشه را rename کن:

`wp-content/plugins/gymai-popular-20-seed` → `gymai-popular-20-seed-OFF`

### ۳. اگر هنوز down است — همه پلاگین‌ها
phpMyAdmin → جدول `wp_options` (prefix خودت را بگذار):

```sql
UPDATE wp_options SET option_value = 'a:0:{}' WHERE option_name = 'active_plugins';
```

سایت باید بالا بیاید. بعد فقط پلاگین‌های لازم را دوباره فعال کن.

---

## علت crash

معمولاً **هر دو** با هم فعال بوده‌اند:

| مشکل | نتیجه |
|------|--------|
| پلاگین + snippet همزمان | تداخل / لود دوباره |
| پلاگین قدیمی (v1.0.0) | فایل ۱۰۰۰خطی روی **هر** بازدید سایت لود می‌شد |
| snippet قدیمی ۱۰۰۰خطی هنوز فعال | fatal error |

---

## نصب درست (فقط پلاگین v1.0.2 — بدون snippet)

1. snippet مربوط به GymAI 20 را **غیرفعال** کن
2. پوشه `lib/services/gymai-popular-20-seed/` را ZIP کن
3. آپلود به `wp-content/plugins/gymai-popular-20-seed/`
4. داخل پوشه **هر دو فایل** باشد:
   - `gymai-popular-20-seed.php` (~۳ کیلوبایت — **نه** ۱۰۰۰ خط)
   - `add_exercises_popular_20.php` (~۱۵۰+ کیلوبایت)
5. **قبل از فعال‌سازی** باز کن:
   `https://gymaipro.ir/wp-content/plugins/gymai-popular-20-seed/verify-install.php`
   - اگر «فایل اصلی خیلی بزرگ» → فایل اشتباه چسبانده شده
6. افزونه‌ها → **GymAI Popular 20 Exercises** → فعال
7. ابزارها → **GymAI 20 Exercises** → اجرای batch

### اگر با فعال‌سازی پلاگین سایت قط می‌شود

**روش بدون فعال‌سازی پلاگین:**

1. پوشه را آپلود کن ولی پلاگین را **فعال نکن**
2. در `run-once.php` مقدار `GYMAI_POP20_RUN_ONCE_SECRET` را عوض کن
3. لاگین پیشخوان → باز کن:
   `https://gymaipro.ir/wp-content/plugins/gymai-popular-20-seed/run-once.php?key=SECRET`
4. بعد از batch موفق: `run-once.php` و `verify-install.php` را حذف کن

### اشتباه رایج آپلود

| اشتباه | نتیجه |
|--------|--------|
| فقط `add_exercises_popular_20.php` داخل پوشه | پلاگین در لیست نیست یا crash |
| محتوای ۱۰۰۰خطی داخل `gymai-popular-20-seed.php` | سایت با فعال‌سازی down |
| ZIP با پوشه تو در تو (`gymai-popular-20-seed/gymai-popular-20-seed/`) | فایل داده پیدا نمی‌شود |
| پلاگین + snippet همزمان | تداخل |

---

## Code Snippets (اختیاری)

**توصیه: استفاده نکن** اگر پلاگین را فعال کردی.

اگر فقط snippet می‌خواهی: `CODE_SNIPPET_3_POPULAR_20.php` + فایل در `wp-content/gymai-seed/` — **نه** پلاگین همزمان.

---

## خط `CODE_SNIPPETS_SAFE_MODE`

بعد از اینکه سایت stable شد و snippet را off کردی، می‌توانی آن خط را از `wp-config.php` حذف کنی.
