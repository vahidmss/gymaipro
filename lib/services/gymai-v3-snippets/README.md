# GymAI v3.6 — Classification Fix

## ریشه باگ
needle `'لت'` در inference داخل `'هالتر'` match می‌شد:
- **فشار پشت بازو هالتر** → اشتباهی `back_lat`
- **لانج با هالتر** → اشتباهی `back_lat` + `vertical_pull`
- **اسکات با مکث** → اگر در meta/description کلمه هالتر بود → `back_lat`

## فایل‌ها

| فایل | کار |
|------|-----|
| `CODE_SNIPPET_V36_OUTPUT_PATCH.php` | **الان deploy کن** — اصلاح JSON خروجی v3 |
| `CODE_SNIPPET_V36_META_BACKFILL.php` | اصلاح ۶ پست در دیتابیس (برای اپ Flutter) |
| `V36_NORMALIZER_HOTFIX.php` | اختیاری — اصلاح دائمی در اسنیپت v3 normalizer |

## Deploy (۵ دقیقه)

### 1) اسنیپت Output Patch
1. Code Snippets → Add New
2. عنوان: `GymAI v3.6 Classification Fix`
3. محتوای `CODE_SNIPPET_V36_OUTPUT_PATCH.php` را paste کن
4. **Run everywhere** → Save & Activate

### 2) تست
```
GET /wp-json/gymai/v3.6/ping
→ {"ok":true,"version":"gymai/v3.6-patched"}

GET /wp-json/gymai/v3/exercises/4011
→ classification.main_muscle = "triceps"

GET /wp-json/gymai/v3/exercises/4016
→ classification.main_muscle = "quads"

GET /wp-json/gymai/v3/exercises/4019
→ classification.main_muscle = "abs", movement_pattern = "anti_rotation"

GET /wp-json/gymai/v3/exercises/4022
→ classification.main_muscle = "quads", movement_pattern = "lunge"
```

با `?debug=1` نوت‌های patch را می‌بینی.

### 3) Meta Backfill (برای اپ Flutter)
1. Code Snippets → Add New → `GymAI v3.6 Meta Backfill`
2. محتوای `CODE_SNIPPET_V36_META_BACKFILL.php`
3. ابزارها → **GymAI v3.6 Backfill** → اجرا

### 4) اسنیپت‌های قبلی

| اسنیپت | وضعیت |
|--------|--------|
| v2 metabox + POP20 | ✅ نگه دار |
| v3 normalizer | ✅ نگه دار (اختیاری: hotfix از `V36_NORMALIZER_HOTFIX.php`) |
| v3.1 patch | ✅ نگه دار |
| v3.2 patch | ✅ نگه دار |
| v3.3 backfill | ❌ **فعلاً نزن** |
| v3.5 backfill | ⚠️ v3.6 جایگزینش برای batch6 |

## IDهای اصلاح‌شده

| ID | حرکت | قبل | بعد |
|----|------|-----|-----|
| 4011 | فشار پشت بازو هالتر | back_lat | triceps |
| 4013 | زیربغل تک بازو | OK | + secondary غنی‌تر |
| 4016 | اسکات با مکث | back_lat | quads |
| 4019 | پالوف پرس | quads | abs |
| 4022 | لانج با هالتر | back_lat | quads |
| 4023 | لانج عقب | pattern خالی | lunge |
