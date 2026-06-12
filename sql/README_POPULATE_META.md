# پر کردن متا `ai_exercises` در Supabase

## ترتیب اجرا

### ۱) مایگریشن ستون‌ها (یک‌بار)

در Supabase → **SQL Editor**، محتوای این فایل را اجرا کنید:

`supabase/migrations/20260522120000_ai_exercises_meta_fields.sql`

### ۲) اگر ردیف‌های تمرین را قبلاً INSERT کرده‌اید

**نیازی به اجرای دوبارهٔ همان INSERT بزرگ نیست.**

فقط این فایل را اجرا کنید:

`sql/populate_ai_exercises_meta_bulk.sql`

این اسکریپت برای **همهٔ ردیف‌های موجود** در `public.ai_exercises`:

| کار | منبع |
|-----|------|
| `short_description` | ستون `content` |
| `detailed_description` | فیلد `detailedDescription` داخل JSON ستون `source` |
| `movement_pattern`, `body_engagement`, `met`, `typical_rpe`, … | قوانین تقریبی از نام/نوع تمرین |
| `muscle_targets_json` | `{}` برای اکثر تمرین‌ها |
| هیت‌مپ کامل | فقط ~۱۰ تمرین برنامه مبتدی (تطبیق با **نام فارسی**) |

### ۳) هیت‌مپ کامل برای همهٔ تمرین‌ها

از داخل اپ: **پنل ادمین → همگام‌سازی تمرین‌ها با وردپرس**

سرویس `ExerciseSyncService` اکنون فیلدهای متا (از جمله `muscle_targets_json`) را از API وردپرس می‌فرستد.

### بازتولید SQL

```bash
python sql/generate_populate_ai_exercises_meta.py
```

خروجی: `sql/populate_ai_exercises_meta_bulk.sql`

## نکته دربارهٔ IDها

IDهای دیتابیس شما (مثلاً 3465+) ممکن است با ID وردپرس (مثلاً 3831 برای برنامه مبتدی) متفاوت باشد.  
اسکریپت bulk برای هیت‌مپ از **نام تمرین** هم تطبیق می‌دهد (مثلاً «پرس سینه دستگاه»).
