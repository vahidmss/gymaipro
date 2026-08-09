# GymAI v3.6 — Classification Fix (Sync-Safe)

## ترس sync و واقعیت

مسیر اپ: **WordPress (API v3) → Supabase**.  
اگر API v3 `main_muscle` / heatmap غلط بدهد، به‌روزرسانی اپ **دادهٔ درست سوپابیس را دوباره خراب می‌کند**.

ریشهٔ تاریخی باگ:
- needle lone `'لت'` داخل `'هالتر'` (و `'اسالت'`) match می‌شد → `back_lat` اشتباه
- بعضی پرس‌ها به‌عنوان `triceps`، جلوبازوها به‌عنوان `back_lat` ذخیره/infer شده بودند

فیکس‌های SQL روی سوپابیس کافی نیستند مگر اینکه **خروجی v3 هم درست باشد**.

---

## فایل‌ها

| فایل | کار |
|------|-----|
| `CODE_SNIPPET_V36_OUTPUT_PATCH.php` | **الزامی** — اصلاح JSON خروجی `/gymai/v3/exercises` (عنوان‌محور + ID override + پاکسازی heatmap) |
| `CODE_SNIPPET_V36_META_BACKFILL.php` | اصلاح چند پست خاص در DB |
| `V36_NORMALIZER_HOTFIX.php` | اختیاری — اصلاح دائمی inference داخل normalizer |
| POP20 CORE → «بازنویسی meta از اسنیپت‌ها» | نوشتن meta درست از batchها روی CPT |

---

## Deploy (۵ دقیقه)

### 1) Output Patch را **حتماً** آپدیت/فعال کن
1. Code Snippets → اسنیپت v3.6 Classification Fix
2. محتوای جدید `CODE_SNIPPET_V36_OUTPUT_PATCH.php` را جایگزین کن
3. Run everywhere → Save & Activate

### 2) تست
```
GET /wp-json/gymai/v3.6/ping
→ {"ok":true,"version":"gymai/v3.6-patched"}

GET /wp-json/gymai/v3/exercises?per_page=5&debug=1
→ version = gymai/v3.6-patched

نمونه:
/wp-json/gymai/v3/exercises?search=پرس%20سینه → main_muscle=chest (نه triceps)
/wp-json/gymai/v3/exercises?search=جلو%20بازو%20هالتر → biceps (نه back_lat)
/wp-json/gymai/v3/exercises?search=هیپ%20تراست → glutes
```

### 3) قبل از sync اپ
1. ابزارها → GymAI Exercises → **بازنویسی meta از اسنیپت‌ها**
2. (اختیاری) بروزرسانی نام‌های جایگزین
3. بعد در اپ: به‌روزرسانی تمرین‌ها

---

## قوانین پچ v3.6 (خلاصه)

1. هرگز lone `لت` برای لات — فقط `لت پول` / `زیربغل` / `pulldown` / …
2. پرس سینه / بنچ / فلای / قفسه → `chest` (دست‌جمع می‌تواند `triceps` بماند)
3. پرس سرشانه / آرنولد / OHP → `shoulder_anterior`
4. جلوبازو / کرل → `biceps` (نه `back_lat`)
5. پشت‌بازو / اسکال / فرنچ → `triceps`
6. هیپ‌تراست / پل باسن → `glutes`
7. ساق → `calves`
8. شراگ / کول → `traps`
9. heatmap آلوده به `back_lat` برای پا/تریسپس پاک می‌شود
10. `chest_upper` به‌عنوان main به `chest` نرمال می‌شود

---

## IDهای override قطعی

| ID | حرکت | بعد |
|----|------|-----|
| 4011 | فشار پشت بازو هالتر | triceps |
| 4016 | اسکات با مکث | quads |
| 4019 | پالوف پرس | abs |
| 4022 | لانج با هالتر | quads |
| 4023 | لانج عقب | lunge pattern |
| 4013 | زیربغل تک بازو | back_lat + secondary غنی |

بقیهٔ حرکات با **طبقه‌بندی عنوان‌محور** پوشش داده می‌شوند (دیگر فقط این ۶ تا نیستند).
