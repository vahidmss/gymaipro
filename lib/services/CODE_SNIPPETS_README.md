# Code Snippets — نسخه امن (بعد از خطای بحرانی)

## اگر سایت down است

`WORDPRESS_RECOVERY.md` را بخوان — اول snippet را غیرفعال کن.

---

## دو snippet (توصیه می‌شود)

| # | فایل | محل اجرا |
|---|------|----------|
| A | `CODE_SNIPPET_0_REST_META.php` | **همه جا** |
| B | `CODE_SNIPPET_1_SEED.php` | **همه جا** (الزامی برای API) |

بدون Snippet A، فیلدهای جدید در API دیده نمی‌شوند.

### بعد از فعال‌سازی

1. ابزارها → **GymAI Seed**
2. **Run Seed Now**
3. باید: `Updated: 10`

---

## تغییرات نسخه امن

- Seed خودکار در `admin_init` **حذف شد** (علت خطا)
- `wp_update_post` **حذف شد** (جلوگیری از حلقه hook)
- `register_post_meta` فقط اگر قبلاً ثبت نشده
- `function_exists` برای جلوگیری از تعریف دوباره
- سازگار با PHP 7.0+

---

## Snippet 2 (متاباکس)

فقط بعد از Seed موفق — `CODE_SNIPPET_2_METABOX.php` — فقط مدیریت.
