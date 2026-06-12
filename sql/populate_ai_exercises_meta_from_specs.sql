-- =============================================================================
-- Supabase SQL Editor — فقط فیلدهای متا جدید (ستون‌های قدیمی دست نخورده)
-- پیش‌نیاز: supabase/migrations/20260522120000_ai_exercises_meta_fields.sql
-- =============================================================================

-- ─── الف) فقط نام + شناسه (برای بررسی / خروجی به AI) ───
SELECT id, name
FROM public.ai_exercises
ORDER BY name;

-- حرکت‌هایی که هنوز متا ندارند:
SELECT id, name, main_muscle, equipment, difficulty
FROM public.ai_exercises
WHERE
  (short_description IS NULL OR TRIM(short_description) = '')
  AND (movement_pattern IS NULL OR TRIM(movement_pattern) = '')
  AND (muscle_targets_json IS NULL OR muscle_targets_json = '{}'::jsonb)
ORDER BY id::bigint;

-- ─── ب) پر کردن متا — فقط جایی که خالی است ───
BEGIN;

-- ۱) توضیحات از content و source (JSON وردپرس)
UPDATE public.ai_exercises
SET
  short_description = COALESCE(
    NULLIF(TRIM(short_description), ''),
    NULLIF(TRIM(content), '')
  ),
  learn = COALESCE(
    NULLIF(TRIM(learn), ''),
    NULLIF(TRIM(content), '')
  ),
  detailed_description = COALESCE(
    NULLIF(TRIM(detailed_description), ''),
    CASE
      WHEN source IS NOT NULL
        AND TRIM(source::text) ~ '^\s*\{'
      THEN NULLIF(TRIM(source::jsonb->>'detailedDescription'), '')
      ELSE NULL
    END
  ),
  seo_content = COALESCE(
    NULLIF(TRIM(seo_content), ''),
    CASE
      WHEN source IS NOT NULL
        AND TRIM(source::text) ~ '^\s*\{'
      THEN NULLIF(TRIM(source::jsonb->>'detailedDescription'), '')
      ELSE NULL
    END
  ),
  synced_at = now()
WHERE
  (short_description IS NULL OR TRIM(short_description) = '')
  OR (learn IS NULL OR TRIM(learn) = '')
  OR (detailed_description IS NULL OR TRIM(detailed_description) = '')
  OR (seo_content IS NULL OR TRIM(seo_content) = '');

-- ۲) الگوی حرکت (از نام)
UPDATE public.ai_exercises
SET
  movement_pattern = CASE
    WHEN name ~* '(اسکوات|Squat|گابلت|هک اسکوات|فرانت اسکوات|اسپلیت|لانج)' THEN 'اسکوات'
    WHEN name ~* '(ددلیفت|Deadlift|RDL|گودمورنینگ|رک پول)' THEN 'لگد'
    WHEN name ~* '(بنچ|Bench|پرس سینه|پرس تخت|پرس دست جمع)' THEN 'فشار افقی'
    WHEN name ~* '(پرس سرشانه|Overhead|OHP|آرنولد|پوش پرس|پرس پشت|Military)' THEN 'فشار عمودی'
    WHEN name ~* '(لت پول|لت پولدان|لت قفل|پول.?دان|Pulldown|بارفیکس|چین.?آپ|Pull.?Up)' THEN 'کشش عمودی'
    WHEN name ~* '(روو|زیربغل|پارویی|T.?Bar|تی.?بار)'
      AND name !~* '(روئینگ|Rowing|روینگ|بایک|Bike|اسالت)' THEN 'کشش افقی'
    WHEN name ~* 'Row' AND name !~* '(روئینگ|Rowing|روینگ|بایک|Bike|اسالت)' THEN 'کشش افقی'
    WHEN name ~* '(کرل|Curl|جلوبازو|همر|چکشی)' AND name !~* 'پشت' THEN 'کشش عمودی'
    WHEN name ~* '(پوش.?دان|پشت.?بازو|Triceps|اسکال|کرشر|دیپ)' THEN 'فشار عمودی'
    WHEN name ~* '(پرس|فشار)' AND main_muscle ~* 'سینه' THEN 'فشار افقی'
    WHEN name ~* '(پرس|فشار)' THEN 'فشار عمودی'
    WHEN name ~* '(نشر|Raise|فلای|Fly|کراس|قفسه|پک)' THEN 'فشار عمودی'
    WHEN name ~* '(کرانچ|پلانک|شکم|Crunch|Leg Raise|رول.?اوت|وی.?آپ)' THEN 'چرخشی'
    WHEN name ~* '(تردمیل|دویدن|پیاده|دوچرخه|الپتیکال|هوازی|طناب|برپی|اسپرینت|بایک|Bike|اسپین|Spin|استپر|Stepper|پله|روئینگ|Rowing|اسکی|Erg|جامپینگ|Jumping|های.?نیز|بات.?کیک|مانتین|کلایمر|اسکیتر|شاتل|فارتلک|بوکس|Boxing|شنای|شنا|کرال|Swim)' THEN 'هوازی'
    WHEN name ~* '(کلین|اسنچ|جرک|سوئینگ|فارمر|سورتمه|اسلد)' THEN 'فانکشنال'
    WHEN main_muscle ~* '(سینه)' THEN 'فشار افقی'
    WHEN main_muscle ~* '(پا|ران|باسن|همسترینگ)' THEN 'اسکوات'
    WHEN main_muscle ~* 'پشت.?بازو|سه.?سر' THEN 'فشار عمودی'
    WHEN main_muscle ~* 'زیربغل|لات' OR TRIM(main_muscle) = 'پشت' THEN 'کشش عمودی'
    WHEN main_muscle ~* '(شکم|میان)' THEN 'چرخشی'
    ELSE 'فانکشنال'
  END,
  synced_at = now()
WHERE movement_pattern IS NULL OR TRIM(movement_pattern) = '';

-- ۳) درگیری بدن
UPDATE public.ai_exercises
SET
  body_engagement = CASE
    WHEN name ~* '(کرل|فلای|قفسه|نشر جانب|نشر جلو|اکستنشن|کیک|مچ|ساق|جلوپا|پشت.?پا|Leg Curl|Extension|Raise|Fly|کرانچ|پلانک|واکیووم)'
      AND name !~* '(اسکوات|ددلیفت|پرس|روو|لت|بارفیکس|دیپ|شنا|بنچ)' THEN 'تک مفصلی'
    WHEN exercise_type ~* 'ایزوله' THEN 'تک مفصلی'
    ELSE 'چند مفصلی'
  END,
  synced_at = now()
WHERE body_engagement IS NULL OR TRIM(body_engagement) = '';

-- ۴) MET، فاصله حرکت، کالری (تقریبی از نوع حرکت)
UPDATE public.ai_exercises
SET
  met = CASE
    WHEN exercise_type ~* 'هوازی' OR COALESCE(estimated_duration::int, 90) <= 45 THEN 8.0
    WHEN movement_pattern = 'هوازی' THEN 8.0
    WHEN movement_pattern IN ('اسکوات', 'لگد') OR name ~* '(اسکوات|ددلیفت)' THEN 6.0
    WHEN body_engagement = 'تک مفصلی' THEN 3.5
    WHEN name ~* '(پلانک|کرانچ|شکم)' THEN 4.0
    ELSE 5.0
  END,
  movement_distance_cm = CASE movement_pattern
    WHEN 'اسکوات' THEN 60
    WHEN 'لگد' THEN 60
    WHEN 'کشش عمودی' THEN 50
    WHEN 'کشش افقی' THEN 55
    WHEN 'فشار افقی' THEN 45
    WHEN 'فشار عمودی' THEN 50
    WHEN 'چرخشی' THEN 30
    WHEN 'هوازی' THEN 0
    ELSE 45
  END,
  calories_per_1000kg = CASE movement_pattern
    WHEN 'اسکوات' THEN 55
    WHEN 'لگد' THEN 55
    WHEN 'کشش عمودی' THEN 45
    WHEN 'کشش افقی' THEN 50
    WHEN 'فشار افقی' THEN 52
    WHEN 'فشار عمودی' THEN 48
    WHEN 'چرخشی' THEN 35
    ELSE 45
  END,
  synced_at = now()
WHERE met IS NULL;

-- ۵) RPE، امتیاز سختی، فرمول ۱RM
UPDATE public.ai_exercises
SET
  typical_rpe = CASE difficulty
    WHEN 'مبتدی' THEN 7.0
    WHEN 'متوسط' THEN 7.5
    WHEN 'پیشرفته' THEN 8.5
    ELSE 7.5
  END,
  exercise_difficulty_score = CASE difficulty
    WHEN 'مبتدی' THEN 4
    WHEN 'متوسط' THEN 6
    WHEN 'پیشرفته' THEN 8
    ELSE 5
  END,
  estimated_1rm_formula = 'برزیکی',
  synced_at = now()
WHERE
  typical_rpe IS NULL
  OR exercise_difficulty_score IS NULL
  OR estimated_1rm_formula IS NULL
  OR TRIM(estimated_1rm_formula) = '';

-- ۶) هیت‌مپ عضلات از main_muscle + secondary_muscles (فقط اگر {} یا null)
UPDATE public.ai_exercises
SET
  muscle_targets_json = CASE
    WHEN main_muscle ~* 'سینه' THEN jsonb_build_object(
      'chest_middle', 90,
      'chest_upper', CASE WHEN name ~* 'بالا|شیب|Incline' THEN 95 ELSE 60 END,
      'chest_lower', CASE WHEN name ~* 'پایین|Decline' THEN 95 ELSE 50 END,
      'shoulder_anterior', CASE WHEN secondary_muscles ~* 'سرشانه|شانه' THEN 45 ELSE 35 END,
      'triceps', CASE WHEN secondary_muscles ~* 'پشت.?بازو|بازو' THEN 40 ELSE 30 END,
      'abs', 15
    )
    WHEN main_muscle ~* 'سرشانه|شانه' THEN jsonb_build_object(
      'shoulder_anterior', CASE WHEN name ~* 'جلو|فرانت' THEN 90 ELSE 70 END,
      'shoulder_lateral', CASE WHEN name ~* 'جانب|لترال' THEN 95 ELSE 75 END,
      'shoulder_posterior', CASE WHEN name ~* 'پشت|عقب|Reverse' THEN 90 ELSE 35 END,
      'triceps', CASE WHEN secondary_muscles ~* 'پشت.?بازو' THEN 45 ELSE 25 END,
      'back_trap', 30,
      'abs', 15
    )
    WHEN main_muscle ~* 'پشت.?بازو|سه.?سر|ترایسپ' THEN jsonb_build_object(
      'triceps', 95,
      'forearms', 25
    )
    WHEN main_muscle ~* 'جلوبازو|بایسپ' THEN jsonb_build_object(
      'biceps', 95,
      'forearms', 40
    )
    WHEN main_muscle ~* 'زیربغل|لات'
      OR TRIM(main_muscle) = 'پشت' THEN jsonb_build_object(
      'back_lat', 95,
      'back_trap', 70,
      'shoulder_posterior', 50,
      'biceps', CASE WHEN secondary_muscles ~* 'جلوبازو|بایسپ' THEN 55 ELSE 40 END,
      'forearms', 30,
      'lower_back', 35
    )
    WHEN main_muscle ~* 'ران|چهار|کواد' THEN jsonb_build_object(
      'quads', 95,
      'hamstrings', 50,
      'glutes', 60,
      'abs', 25,
      'lower_back', 25
    )
    WHEN main_muscle ~* 'همسترینگ|پشت.?پا' THEN jsonb_build_object(
      'hamstrings', 95,
      'glutes', CASE WHEN name ~* 'RDL|رومانی|ددلیفت' THEN 80 ELSE 20 END,
      'calf', 25,
      'abs', 10
    )
    WHEN main_muscle ~* 'باسن|گلوت' THEN jsonb_build_object(
      'glutes', 95,
      'hamstrings', 70,
      'quads', 40,
      'lower_back', 30
    )
    WHEN main_muscle ~* 'ساق|گوساله' THEN jsonb_build_object(
      'calf', 95,
      'quads', 20
    )
    WHEN main_muscle ~* 'شکم|میان' THEN jsonb_build_object(
      'abs', 95,
      'lower_back', 25
    )
    WHEN main_muscle ~* 'ساعد|مچ' THEN jsonb_build_object(
      'forearms', 95
    )
    WHEN main_muscle ~* 'ذوزنقه|تراپ' THEN jsonb_build_object(
      'back_trap', 95,
      'shoulder_lateral', 40
    )
    WHEN main_muscle ~* '^پا$' OR main_muscle = 'پا' THEN jsonb_build_object(
      'quads', CASE WHEN name ~* 'پشت.?پا|همسترینگ|Leg Curl|Curl' THEN 40 ELSE 90 END,
      'hamstrings', CASE WHEN name ~* 'پشت.?پا|همسترینگ|RDL|ددلیفت' THEN 90 ELSE 50 END,
      'glutes', CASE WHEN name ~* 'اسکوات|لانج|هیپ|باسن' THEN 85 ELSE 50 END,
      'calf', CASE WHEN name ~* 'ساق|Calf|جلوپا' THEN 90 ELSE 35 END,
      'abs', 20
    )
    WHEN main_muscle ~* 'کل بدن' THEN jsonb_build_object(
      'quads', 55,
      'hamstrings', 50,
      'glutes', 50,
      'abs', 45,
      'back_lat', 40,
      'chest_middle', 35,
      'shoulder_anterior', 35
    )
    WHEN main_muscle ~* 'کمر' THEN jsonb_build_object(
      'lower_back', 90,
      'back_trap', 55,
      'glutes', 35,
      'hamstrings', 40
    )
    WHEN (main_muscle IS NULL OR TRIM(main_muscle) = '')
      AND name ~* '(تردمیل|دویدن|پیاده|دوچرخه|هوازی|طناب|برپی|الپتیکال|اسپرینت|بایک|Bike|اسپین|استپر|روئینگ|Rowing|اسکی|Erg|جامپینگ|های.?نیز|بات.?کیک|مانتین|کلایمر|اسکیتر|شاتل|فارتلک|بوکس|شنای|شنا|کرال)' THEN jsonb_build_object(
      'quads', 45,
      'hamstrings', 40,
      'glutes', 35,
      'calf', 40,
      'abs', 30
    )
    ELSE jsonb_build_object('abs', 50)
  END,
  synced_at = now()
WHERE muscle_targets_json IS NULL OR muscle_targets_json = '{}'::jsonb;

-- ۷) نمونهٔ شما: بنچ پرس هالتر تخت (id 3465) — متا دقیق‌تر از heuristics
UPDATE public.ai_exercises
SET
  short_description = COALESCE(
    NULLIF(TRIM(short_description), ''),
    'روی نیمکت تخت دراز بکشید. هالتر را با عرض شانه بگیرید، به سینه پایین بیاورید و با کنترل به بالا فشار دهید. کمر به نیمکت، پا روی زمین.'
  ),
  learn = COALESCE(
    NULLIF(TRIM(learn), ''),
    NULLIF(TRIM(content), ''),
    'بنچ پرس هالتر تخت یکی از بهترین حرکات برای تقویت عضلات سینه است. روی نیمکت تخت دراز بکشید، هالتر را با فاصله مناسب دست‌ها بگیرید و به آرامی پایین بیاورید تا به سینه برسد، سپس با قدرت بالا ببرید.'
  ),
  detailed_description = COALESCE(
    NULLIF(TRIM(detailed_description), ''),
    CASE
      WHEN source IS NOT NULL AND TRIM(source::text) ~ '^\s*\{'
      THEN source::jsonb->>'detailedDescription'
      ELSE NULL
    END
  ),
  seo_content = COALESCE(
    NULLIF(TRIM(seo_content), ''),
    CASE
      WHEN source IS NOT NULL AND TRIM(source::text) ~ '^\s*\{'
      THEN source::jsonb->>'detailedDescription'
      ELSE NULL
    END
  ),
  movement_pattern = 'فشار افقی',
  body_engagement = 'چند مفصلی',
  estimated_1rm_formula = 'برزیکی',
  muscle_targets_json = '{"chest_upper":60,"chest_middle":90,"chest_lower":50,"shoulder_anterior":40,"triceps":35,"abs":15}'::jsonb,
  met = 5.5,
  movement_distance_cm = 45,
  calories_per_1000kg = 52,
  exercise_difficulty_score = 6,
  typical_rpe = 7.5,
  synced_at = now()
WHERE id::text = '3465'
   OR name IN ('بنچ پرس هالتر تخت', 'Bench Press', 'Flat Barbell Bench Press');

COMMIT;

-- ─── ج) بررسی بعد از اجرا ───
SELECT
  id,
  name,
  short_description IS NOT NULL AS has_short,
  movement_pattern,
  muscle_targets_json,
  met,
  typical_rpe
FROM public.ai_exercises
WHERE id::text = '3465'
   OR name = 'بنچ پرس هالتر تخت';

-- خلاصهٔ پر شدن متا در کل جدول:
SELECT
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE short_description IS NOT NULL AND TRIM(short_description) <> '') AS with_short,
  COUNT(*) FILTER (WHERE movement_pattern IS NOT NULL AND TRIM(movement_pattern) <> '') AS with_pattern,
  COUNT(*) FILTER (WHERE muscle_targets_json <> '{}'::jsonb) AS with_heatmap
FROM public.ai_exercises;
