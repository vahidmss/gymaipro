# GymAI Foods — CORE + Batch (Code Snippets)

الگوی مشابه `gymai-pop20-snippets` برای تمرین‌ها.

## Deploy در وردپرس

### 1) اسنیپت CORE (همیشه فعال)
- `CODE_SNIPPET_FOOD_CORE.php` — Run everywhere
- منو: **ابزارها → GymAI Seed Foods**

### 2) اسنیپت‌های BATCH (۱۵۰ خوراکی = ۱۵ batch)
| Batch | فایل | محدوده |
|-------|------|--------|
| 1 | `CODE_SNIPPET_FOOD_BATCH1.php` | ۱–۱۰ پایه (نان، برنج، مرغ، تخم‌مرغ، …) |
| 2–10 | `BATCH2` … `BATCH10` | ۱۱–۱۰۰ کاتالوگ اصلی |
| 11–15 | `BATCH11` … `BATCH15` | ۱۰۱–۱۵۰ بدنسازی (وی، شیر، برنجکیک، …) |

**یا** فایل batch در سرور:
```
wp-content/gymai-seed/food-batch1.php … food-batch10.php
```

### 3) اجرا
1. CORE را فعال کن
2. BATCH1 تا BATCH15 را فعال کن (یا فایل‌ها را در `gymai-seed` بگذار)
3. **ابزارها → GymAI Seed Foods** → Seed هر batch (یا همه با force update)

---

## بازتولید ۱۵۰ خوراکی

```bash
cd lib/services/gymai-food-snippets
python generate_foods_to_100.py   # batch1 + catalog90 + catalog50
python generate_food_batches.py   # BATCH1…15
python build_food_core.py
```

**واحد سرو:** فقط گام‌های `1`، `0.5`، `0.1`، `10` — از `0.25` استفاده نکن (متاباکس خطا می‌دهد).

## افزودن خوراکی جدید (batch بعدی)

1. آیتم‌ها را به `foods_catalog_90.json` یا مستقیم `foods_bulk_meta.json` اضافه کن
2. اسکریپت‌های بالا را اجرا کن
3. اسنیپت batch جدید را در Code Snippets فعال کن
4. از پنل ادمین seed کن

---

## فایل‌های منبع
| فایل | نقش |
|------|-----|
| `../gymai_food_meta_seed.php` | موتور PHP (منبع CORE) |
| `../foods_bulk_meta.json` | دیتای همه خوراکی‌ها |
| `foods_catalog_90.json` | ۹۰ خوراکی پرکاربرد (۱۱–۱۰۰) |
| `foods_catalog_50.json` | ۵۰ خوراکی بدنسازی (۱۰۱–۱۵۰) |
| `generate_foods_to_100.py` | ادغام ۱۰+۹۰ → `foods_bulk_meta.json` |
| `generate_food_batches.py` | ساخت batch از JSON |
| `build_food_core.py` | ساخت CORE از موتور |

## یادداشت
- `CODE_SNIPPET_FOOD_SEED.php` قدیمی — دیگر استفاده نکن
- بندانگشتی (Featured Image) ست نمی‌شود
- اسلاگ URL از `rank_math_focus_keyword` ساخته می‌شود (نیم‌فاصله حفظ می‌شود)
