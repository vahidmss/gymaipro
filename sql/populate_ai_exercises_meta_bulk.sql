-- =============================================================================
-- پر کردن فیلدهای متا در public.ai_exercises (فقط دادهٔ Supabase)
-- اجرا در Supabase → SQL Editor (بعد از migration 20260522120000)
-- وردپرس لازم نیست؛ از name / main_muscle / content / source پر می‌شود.
-- =============================================================================
BEGIN;

-- ─── ۱) توضیحات از ستون‌های موجود (content + source JSON) ───
UPDATE public.ai_exercises
SET
  short_description = NULLIF(TRIM(content), ''),
  detailed_description = COALESCE(
    NULLIF(TRIM(detailed_description), ''),
    CASE
      WHEN source IS NULL OR TRIM(source::text) IN ('', 'null') THEN NULL
      WHEN source::text ~ '^\s*\{' THEN NULLIF(TRIM(source::jsonb->>'detailedDescription'), '')
      ELSE NULL
    END
  ),
  synced_at = now()
WHERE content IS NOT NULL OR source IS NOT NULL;

-- ─── ۲) الگوی حرکت (heuristic از نام / تجهیزات) ───
UPDATE public.ai_exercises SET movement_pattern = CASE
  WHEN movement_pattern IS NOT NULL AND TRIM(movement_pattern) <> '' THEN movement_pattern
  WHEN name ~* '(اسکوات|Squat|گابلت|هک اسکوات|فرانت اسکوات|اسپلیت)' THEN 'اسکوات'
  WHEN name ~* '(ددلیفت|Deadlift|RDL|گودمورنینگ|رک پول)' THEN 'لگد'
  WHEN name ~* '(لت|پول.?دان|Pulldown|بارفیکس|چین.?آپ|Pull.?Up)' THEN 'کشش عمودی'
  WHEN name ~* '(روو|زیربغل|پارویی|Row|T.?Bar|تی.?بار)' THEN 'کشش افقی'
  WHEN name ~* '(کرل|Curl|جلوبازو|همر|چکشی)' AND name !~* 'پشت' THEN 'کشش عمودی'
  WHEN name ~* '(پوش.?دان|پشت.?بازو|Triceps|اسکال|کرشر|دیپ پشت)' THEN 'فشار عمودی'
  WHEN name ~* '(پرس سرشانه|Overhead|OHP|آرنولد|پوش پرس|پرس پشت|Military)' THEN 'فشار عمودی'
  WHEN name ~* '(بنچ|Bench|پرس سینه|پرس تخت|پرس دست جمع)' THEN 'فشار افقی'
  WHEN name ~* '(پرس|فشار)' THEN 'فشار افقی'
  WHEN name ~* '(نشر|Raise|فلای|Fly|کراس|قفسه|پک)' THEN 'فشار عمودی'
  WHEN name ~* '(کرانچ|پلانک|شکم|Crunch|Leg Raise|رول.?اوت|وی.?آپ)' THEN 'چرخشی'
  WHEN name ~* '(تردمیل|دویدن|پیاده|دوچرخه|الپتیکال|هوازی|طناب|برپی)' THEN 'هوازی'
  WHEN name ~* '(کلین|اسنچ|جرک|سوئینگ|فارمر|سورتمه|اسلد)' THEN 'فانکشنال'
  ELSE movement_pattern
END,
  synced_at = now()
WHERE movement_pattern IS NULL OR TRIM(movement_pattern) = '';

-- ─── ۳) درگیری بدن ───
UPDATE public.ai_exercises SET body_engagement = CASE
  WHEN body_engagement IS NOT NULL AND TRIM(body_engagement) <> '' THEN body_engagement
  WHEN name ~* '(کرل|فلای|قفسه|نشر جانب|نشر جلو|اکستنشن|کرل|کیک|مچ|ساق|جلوپا دستگاه|پشت.?پا|Leg Curl|Extension|Raise|Fly|کرانچ|پلانک|واکیووم)'
    AND name !~* '(اسکوات|ددلیفت|پرس|روو|لت|بارفیکس|دیپ|شنا)' THEN 'تک مفصلی'
  WHEN name ~* '(اسکوات|ددلیفت|پرس|روو|لت|بارفیکس|دیپ|شنا|کلین|تراستر|لانج)' THEN 'چند مفصلی'
  ELSE 'چند مفصلی'
END,
  synced_at = now()
WHERE body_engagement IS NULL OR TRIM(body_engagement) = '';

-- ─── ۴) MET تقریبی ───
UPDATE public.ai_exercises SET met = CASE
  WHEN met IS NOT NULL THEN met
  WHEN exercise_type ~* 'هوازی' OR estimated_duration::int <= 45 THEN 8.0
  WHEN name ~* '(کرل|فلای|نشر|اکستنشن|مچ|ساق|Leg Curl|Extension)' THEN 3.5
  WHEN name ~* '(اسکوات|ددلیفت|پرس|روو|لت)' THEN 6.0
  WHEN name ~* '(پلانک|کرانچ|شکم)' THEN 4.0
  ELSE 5.0
END,
  synced_at = now()
WHERE met IS NULL;

-- ─── ۵) RPE و امتیاز سختی از difficulty فارسی ───
UPDATE public.ai_exercises SET
  typical_rpe = COALESCE(typical_rpe, CASE difficulty
    WHEN 'مبتدی' THEN 7.0
    WHEN 'متوسط' THEN 7.5
    WHEN 'پیشرفته' THEN 8.5
    ELSE 7.5
  END),
  exercise_difficulty_score = COALESCE(exercise_difficulty_score, CASE difficulty
    WHEN 'مبتدی' THEN 4
    WHEN 'متوسط' THEN 6
    WHEN 'پیشرفته' THEN 8
    ELSE 5
  END),
  estimated_1rm_formula = COALESCE(NULLIF(TRIM(estimated_1rm_formula), ''), 'برزیکی'),
  synced_at = now();

-- ─── ۶) شمارنده‌ها (اگر خالی است) ───
UPDATE public.ai_exercises SET
  views_count = COALESCE(views_count, 0),
  likes_count = COALESCE(likes_count, 0)
WHERE views_count IS NULL OR likes_count IS NULL;

-- ─── ۷) هیت‌مپ و متا کامل — ۱۰ تمرین برنامه مبتدی (تطبیق نام + ID وردپرس) ───
-- پرس سرشانه دستگاه (WP meta id 3831)
UPDATE public.ai_exercises SET
  short_description = 'روی دستگاه بنشینید، کمر و پشت سر را به تکیه‌گاه بچسبانید. دستگیره‌ها را در ارتفاع شانه بگیرید. با بازدم دست‌ها را به بالا فشار دهید تا آرنج‌ها تقریباً صاف شوند (کامل قفل نکنید). با دم و کنترل ۲–۳ ثانیه برگردید. شانه را به گوش نکشید.',
  movement_pattern = 'فشار عمودی',
  body_engagement = 'چند مفصلی',
  estimated_1rm_formula = 'برزیکی',
  muscle_targets_json = '{"shoulder_anterior": 85, "shoulder_lateral": 90, "shoulder_posterior": 30, "triceps": 40, "back_trap": 35, "abs": 20}'::jsonb,
  met = 5,
  movement_distance_cm = 50,
  calories_per_1000kg = 48,
  exercise_difficulty_score = 5,
  typical_rpe = 7,
  tips = ARRAY['کمر را کاملاً به پشتی دستگاه بچسبانید و در کل حرکت جدا نکنید', 'دست‌ها را به بالا فشار دهید؛ آرنج را کامل قفل نکنید', 'در نقطه بالا شانه را به سمت گوش بالا نبرید (شراگ نکنید)'],
  synced_at = now()
WHERE id::text = '3831' OR name IN ('پرس سرشانه دستگاه');

-- پرس سینه دستگاه (WP meta id 3832)
UPDATE public.ai_exercises SET
  short_description = 'روی دستگاه بنشینید، کمر و تیغه‌های شانه را به پشتی بچسبانید. شانه‌ها را پایین و عقب ببرید. با بازدم دستگیره‌ها را به جلو فشار دهید؛ آرنج را کامل قفل نکنید. یک ثانیه مکث و انقباض سینه. با دم آهسته برگردید.',
  movement_pattern = 'فشار افقی',
  body_engagement = 'چند مفصلی',
  estimated_1rm_formula = 'برزیکی',
  muscle_targets_json = '{"chest_upper": 60, "chest_middle": 90, "chest_lower": 50, "shoulder_anterior": 40, "triceps": 35, "abs": 15}'::jsonb,
  met = 5.5,
  movement_distance_cm = 45,
  calories_per_1000kg = 52,
  exercise_difficulty_score = 5,
  typical_rpe = 7.5,
  tips = ARRAY['شانه‌ها را به سمت پایین و عقب ببرید (قفسه سینه باز شود)', 'در نقطه بالا آرنج را کامل قفل نکنید', 'تیغه‌های شانه را در تمام حرکت به پشتی بچسبانید'],
  synced_at = now()
WHERE id::text = '3832' OR name IN ('پرس سینه دستگاه');

-- پشت پا دستگاه (WP meta id 3842)
UPDATE public.ai_exercises SET
  short_description = 'روی دستگاه دمر دراز بکشید، زانو روی لبه پد، پاشنه به غلتک. کمر را به پشتی بچسبانید. با بازدم پد را به باسن بکشید، ۱ ثانیه مکث. با دم ۲–۳ ثانیه برگردید. لگن را ثابت نگه دارید.',
  movement_pattern = 'لگد',
  body_engagement = 'تک مفصلی',
  estimated_1rm_formula = 'برزیکی',
  muscle_targets_json = '{"hamstrings": 95, "glutes": 15, "calf": 25, "abs": 10}'::jsonb,
  met = 4.5,
  movement_distance_cm = 35,
  calories_per_1000kg = 42,
  exercise_difficulty_score = 4,
  typical_rpe = 7,
  tips = ARRAY['کمر را کاملاً به پشتی دستگاه بچسبانید و لگن را تثبیت کنید', 'در نقطه بالا مکث کنید و انقباض همسترینگ را حس کنید', 'وزنه را پرتاب نکنید – فاز منفی آهسته (۲–۳ ثانیه)'],
  synced_at = now()
WHERE id::text = '3842' OR name IN ('پشت پا دستگاه', 'پشت‌پا خوابیده دستگاه', 'پشت پا خوابیده دستگاه', 'پشت‌پا نشسته دستگاه');

-- زیربغل سیم‌کش (WP meta id 3844)
UPDATE public.ai_exercises SET
  short_description = 'روی دستگاه بنشینید، میله را با دست باز (عرضه) بگیرید، سینه را جلو بدهید. با بازدم آرنج‌ها را پایین بکشید تا میله بالای سینه برسد. ۱ ثانیه مکث. با دم ۲–۳ ثانیه برگردید. از تاب دادن کمر خودداری کنید.',
  movement_pattern = 'کشش عمودی',
  body_engagement = 'چند مفصلی',
  estimated_1rm_formula = 'برزیکی',
  muscle_targets_json = '{"back_lat": 95, "back_trap": 70, "shoulder_posterior": 35, "biceps": 25, "triceps": 15}'::jsonb,
  met = 5,
  movement_distance_cm = 50,
  calories_per_1000kg = 45,
  exercise_difficulty_score = 3,
  typical_rpe = 7.5,
  tips = ARRAY['میله را با دست باز (عرضه) بگیرید', 'با آرنج بکشید، نه با بازو', 'در نقطه پایین سینه را به جلو بدهید و منقبض کنید'],
  synced_at = now()
WHERE id::text = '3844' OR name IN ('زیربغل سیم‌کش', 'پارویی سیمکش نشسته', 'لت پول‌دان دست باز', 'لت پولدان دست باز');

-- اسکات هالتر (WP meta id 3847)
UPDATE public.ai_exercises SET
  short_description = 'هالتر روی شانه، پاها به عرض شانه، کمر صاف و سینه باز. با کنترل باسن را عقب بدهید تا ران‌ها با زمین موازی شوند. با بازدم قدرتی به بالا برگردید. زانوها هم‌جهت با انگشتان پا.',
  movement_pattern = 'اسکوات',
  body_engagement = 'چند مفصلی',
  estimated_1rm_formula = 'برزیکی',
  muscle_targets_json = '{"quads": 95, "hamstrings": 70, "glutes": 80, "abs": 40, "lower_back": 35}'::jsonb,
  met = 6,
  movement_distance_cm = 60,
  calories_per_1000kg = 55,
  exercise_difficulty_score = 7,
  typical_rpe = 8,
  tips = ARRAY['کمر را صاف نگه دارید و سینه را باز کنید', 'زانوها را همجهت با انگشتان پا حرکت دهید', 'در پایین‌ترین نقطه ران‌ها با زمین موازی شوند'],
  synced_at = now()
WHERE id::text = '3847' OR name IN ('اسکات هالتر', 'اسکوات هالتر');

-- جلوبازو دمبل نشسته (WP meta id 3849)
UPDATE public.ai_exercises SET
  short_description = 'روی نیمکت بنشینید، پشت به پشتی. دمبل‌ها را با کف دست رو به جلو بگیرید. با بازدم به شانه بکشید؛ در اوج مچ را به بیرون بچرخانید. با دم ۳ ثانیه پایین بیاورید. بازوها را کامل صاف کنید.',
  movement_pattern = 'کشش عمودی',
  body_engagement = 'تک مفصلی',
  estimated_1rm_formula = 'برزیکی',
  muscle_targets_json = '{"biceps": 95, "forearms": 40}'::jsonb,
  met = 3.5,
  movement_distance_cm = 45,
  calories_per_1000kg = 37,
  exercise_difficulty_score = 3,
  typical_rpe = 7,
  tips = ARRAY['پشت را کاملاً به نیمکت بچسبانید و لگن را ثابت کنید', 'در نقطه اوج مچ را به سمت بیرون بچرخانید (سوپینیشن)', 'فاز منفی را به آرامی (۳ ثانیه) انجام دهید'],
  synced_at = now()
WHERE id::text = '3849' OR name IN ('جلوبازو دمبل نشسته', 'جلوبازو دمبل تناوبی', 'جلوبازو دمبل');

-- نشر جانب دمبل (WP meta id 3851)
UPDATE public.ai_exercises SET
  short_description = 'صاف بایستید، دمبل با کف دست رو به بدن. آرنج کمی خم. با بازدم دمبل‌ها را تا همسطح شانه بالا ببرید؛ ۱ ثانیه مکث. با دم ۲–۳ ثانیه پایین. از تاب دادن بدن خودداری کنید.',
  movement_pattern = 'فشار عمودی',
  body_engagement = 'تک مفصلی',
  estimated_1rm_formula = 'برزیکی',
  muscle_targets_json = '{"shoulder_lateral": 90, "shoulder_anterior": 30, "back_trap": 20, "forearms": 15}'::jsonb,
  met = 4,
  movement_distance_cm = 50,
  calories_per_1000kg = 40,
  exercise_difficulty_score = 3,
  typical_rpe = 7,
  tips = ARRAY['دمبل را با کف دست رو به پایین بگیرید و مچ را صاف نگه دارید', 'آرنج را کمی خمیده نگه دارید (حدود ۱۵ درجه)', 'وزنه را تا همسطح شانه بالا ببرید، نه بالاتر'],
  synced_at = now()
WHERE id::text = '3851' OR name IN ('نشر جانب دمبل');

-- پشت بازو سیم‌کش (WP meta id 3853)
UPDATE public.ai_exercises SET
  short_description = 'روبروی سیم‌کش، میله با دست جمع، آرنج به بدن. با بازدم میله را پایین فشار دهید؛ ۱ ثانیه مکث. با دم ۲–۳ ثانیه برگردید. فقط ساعد حرکت کند.',
  movement_pattern = 'فشار عمودی',
  body_engagement = 'تک مفصلی',
  estimated_1rm_formula = 'برزیکی',
  muscle_targets_json = '{"triceps": 95, "forearms": 25}'::jsonb,
  met = 4,
  movement_distance_cm = 40,
  calories_per_1000kg = 38,
  exercise_difficulty_score = 2,
  typical_rpe = 7,
  tips = ARRAY['آرنج را در تمام حرکت ثابت و چسبیده به بدن نگه دارید', 'در نقطه پایین مکث کنید و انقباض پشت بازو را حس کنید', 'فاز منفی را به آرامی (۲–۳ ثانیه) انجام دهید'],
  synced_at = now()
WHERE id::text = '3853' OR name IN ('پشت بازو سیم‌کش', 'پشت‌بازو سیمکش طناب', 'پشت‌بازو سیمکش میله صاف');

-- زیربغل هالتر خمیده (WP meta id 3855)
UPDATE public.ai_exercises SET
  short_description = 'هالتر با دست باز، زانو کمی خم، بالاتنه ۴۵ درجه، کمر صاف. با بازدم هالتر را به پایین شکم بکشید. در اوج تیغه‌های شانه را به هم فشار دهید. با دم آهسته برگردید.',
  movement_pattern = 'کشش افقی',
  body_engagement = 'چند مفصلی',
  estimated_1rm_formula = 'برزیکی',
  muscle_targets_json = '{"back_lat": 95, "back_trap": 75, "shoulder_posterior": 65, "biceps": 50, "forearms": 40, "lower_back": 40}'::jsonb,
  met = 5.5,
  movement_distance_cm = 55,
  calories_per_1000kg = 50,
  exercise_difficulty_score = 5,
  typical_rpe = 8,
  tips = ARRAY['کمر را کاملاً صاف نگه دارید (هرگز قوز نکنید)', 'هالتر را به سمت پایین شکم بکشید، نه سینه', 'در نقطه اوج تیغه‌های شانه را به هم فشار دهید'],
  synced_at = now()
WHERE id::text = '3855' OR name IN ('زیربغل هالتر خمیده', 'زیربغل هالتر خم', 'روو هالتر خم');

-- ددلیفت رومانیایی (WP meta id 3857)
UPDATE public.ai_exercises SET
  short_description = 'صاف بایستید، هالتر جلوی ران، زانو کمی خم، کمر صاف. با دم باسن عقب و هالتر پایین تا کشش همسترینگ. با بازدم باسن جلو و همسترینگ منقبض. هرگز کمر قوز نکنید.',
  movement_pattern = 'لگد',
  body_engagement = 'چند مفصلی',
  estimated_1rm_formula = 'برزیکی',
  muscle_targets_json = '{"hamstrings": 95, "glutes": 85, "quads": 30, "lower_back": 40, "forearms": 35}'::jsonb,
  met = 6,
  movement_distance_cm = 60,
  calories_per_1000kg = 55,
  exercise_difficulty_score = 7,
  typical_rpe = 8,
  tips = ARRAY['کمر را کاملاً صاف نگه دارید (هرگز قوز نکنید)', 'فاز منفی را آرام انجام دهید و کشش همسترینگ را حس کنید', 'زانوها را کمی خمیده نگه دارید (نه قفل شده)'],
  synced_at = now()
WHERE id::text = '3857' OR name IN ('ددلیفت رومانیایی');

COMMIT;

-- بررسی نمونه:
-- SELECT id, name, short_description IS NOT NULL AS has_short,
--        detailed_description IS NOT NULL AS has_detail,
--        movement_pattern, muscle_targets_json
-- FROM public.ai_exercises ORDER BY id::int LIMIT 20;