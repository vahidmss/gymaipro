# پر کردن خودکار متا + هیت‌مپ — ۱۰ حرکت

## فایل‌ها

| فایل | نقش |
|------|-----|
| `exercises_bulk_meta.json` | منبع داده (متا + هیت‌مپ علمی) |
| `gymai_exercise_meta_seed.php` | اسکریپت Seed وردپرس |
| `updated_exercise_meta_box.php` | متاباکس اصلاح‌شده (ذخیره + REST) |

## روش A — Code Snippets (اگر پلاگین قطعه‌کد دارید)

راهنمای کامل: **`CODE_SNIPPETS_README.md`**

1. Snippet 1: کپی `CODE_SNIPPET_1_SEED.php` — **بدون** `<?php` — اجرا: فقط مدیریت
2. Snippet 2: کپی `CODE_SNIPPET_2_METABOX.php` — **بدون** `<?php` — اجرا: فقط مدیریت
3. ابزارها → **GymAI Seed** → Run Seed

> خطای 500 قبلی به‌خاطر `require_once` و تگ `<?php` اضافی بود.

---

## روش B — پلاگین (پایدارتر)

## نصب روی gymaipro.ir (۳ دقیقه)

1. در cPanel/File Manager یا FTP، پوشه بسازید:
   `wp-content/plugins/gymai-exercise-seed/`

2. این **۳ فایل** را داخلش کپی کنید:
   - `exercises_bulk_meta.json`
   - `gymai_exercise_meta_seed.php`
   - `updated_exercise_meta_box.php`

3. فایل اصلی پلاگین بسازید `gymai-exercise-seed.php`:

```php
<?php
/**
 * Plugin Name: GymAI Exercise Meta Seed
 * Description: Seed متا و هیت‌مپ ۱۰ حرکت برنامه مبتدی
 * Version: 1.0
 */
require_once __DIR__ . '/updated_exercise_meta_box.php';
require_once __DIR__ . '/gymai_exercise_meta_seed.php';
```

4. پیشخوان وردپرس → **افزونه‌ها** → فعال‌سازی «GymAI Exercise Meta Seed»

5. **ابزارها → GymAI Seed Exercises** → دکمه **اجرای Seed**

6. چک API:
   `GET https://gymaipro.ir/wp-json/wp/v2/exercises/3857`
   باید `short_description`, `movement_pattern`, `muscle_targets_json`, `met` پر باشند.

## REST (اختیاری — با لاگین ادمین)

```http
POST https://gymaipro.ir/wp-json/gymai/v1/seed-exercises-meta
```

## هیت‌مپ — خلاصه علمی

| ID | حرکت | عضلات اصلی (امتیاز) |
|----|------|---------------------|
| 3831 | پرس سرشانه | lateral 90, anterior 85 |
| 3832 | پرس سینه | middle 90, upper 60 |
| 3842 | پشت پا | hamstrings 95 |
| 3844 | لت پولداون | back_lat 95, trap 70 |
| 3847 | اسکات | quads 95, glutes 80 |
| 3849 | جلوبازو | biceps 95 |
| 3851 | نشر جانب | shoulder_lateral 90 |
| 3853 | پشت بازو | triceps 95 |
| 3855 | زیربغل هالتر | back_lat 95 |
| 3857 | RDL | hamstrings 95, glutes 85 |

## بعد از Seed

در اپ: **پنل ادمین → Sync تمرین‌ها** (اگر دارید) تا Supabase هم به‌روز شود.
