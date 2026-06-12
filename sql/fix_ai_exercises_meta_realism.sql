-- =============================================================================
-- اصلاح متای غیرواقعی / باگ heuristic در ai_exercises (۲۱۸ رکورد)
-- مشکلات اصلی:
--   1) «لت» داخل «هالتر» → الگوی اشتباه «کشش عمودی»
--   2) main_muscle خالی (هوازی) یا «پا» / «کل بدن» → هیت‌مپ فقط {abs:50}
-- اجرا در Supabase SQL Editor بعد از populate
-- =============================================================================

BEGIN;

-- ─── ۱) الگوی حرکت (قوانین اصلاح‌شده؛ بدون تطبیق «لت» داخل «هالتر») ───
UPDATE public.ai_exercises
SET
  movement_pattern = CASE
    WHEN name ~* '(اسکوات|Squat|گابلت|هک اسکوات|فرانت اسکوات|اسپلیت|لانج)' THEN 'اسکوات'
    WHEN name ~* '(ددلیفت|Deadlift|RDL|گودمورنینگ|رک پول)' THEN 'لگد'
    WHEN name ~* '(بنچ|Bench|پرس سینه|پرس تخت|پرس دست جمع)' THEN 'فشار افقی'
    WHEN name ~* '(پرس سرشانه|Overhead|OHP|آرنولد|پوش پرس|پرس پشت|Military)' THEN 'فشار عمودی'
    WHEN name ~* '(لت پول|لت پولدان|لت قفل|پول.?دان|Pulldown|بارفیکس|چین.?آپ|Pull.?Up)' THEN 'کشش عمودی'
    WHEN name ~* '(روو|زیربغل|پارویی|T.?Bar|تی.?بار)'
      AND name !~* '(روئینگ|Rowing|بایک|Bike|اسالت)' THEN 'کشش افقی'
    WHEN name ~* 'Row' AND name !~* '(روئینگ|Rowing|بایک|Bike|اسالت)' THEN 'کشش افقی'
    WHEN name ~* '(کرل|Curl|جلوبازو|همر|چکشی)' AND name !~* 'پشت' THEN 'کشش عمودی'
    WHEN name ~* '(پوش.?دان|پشت.?بازو|Triceps|اسکال|کرشر|دیپ)' THEN 'فشار عمودی'
    WHEN name ~* '(پرس|فشار)' AND main_muscle ~* 'سینه' THEN 'فشار افقی'
    WHEN name ~* '(پرس|فشار)' THEN 'فشار عمودی'
    WHEN name ~* '(نشر|Raise|فلای|Fly|کراس|قفسه|پک)' THEN 'فشار عمودی'
    WHEN name ~* '(کرانچ|پلانک|شکم|Crunch|Leg Raise|رول.?اوت|وی.?آپ)' THEN 'چرخشی'
    WHEN name ~* '(تردمیل|دویدن|پیاده|دوچرخه|الپتیکال|هوازی|طناب|برپی|بایک|Bike|اسپین|استپر|روئینگ|Rowing|اسکی|Erg|جامپینگ|های.?نیز|بات.?کیک|مانتین|کلایمر|اسکیتر|شاتل|فارتلک|بوکس|شنای|شنا|کرال)' THEN 'هوازی'
    WHEN name ~* '(کلین|اسنچ|جرک|سوئینگ|فارمر|سورتمه|اسلد)' THEN 'فانکشنال'
    WHEN main_muscle ~* 'سینه' THEN 'فشار افقی'
    WHEN main_muscle ~* 'سرشانه|شانه' THEN 'فشار عمودی'
    WHEN main_muscle ~* '(پا|ران|باسن|همسترینگ|چهار|کواد)' THEN 'اسکوات'
    WHEN main_muscle ~* 'پشت.?بازو|سه.?سر' THEN 'فشار عمودی'
    WHEN main_muscle ~* 'زیربغل|لات' OR TRIM(main_muscle) = 'پشت' THEN 'کشش عمودی'
    WHEN main_muscle ~* '(شکم|میان)' THEN 'چرخشی'
    WHEN main_muscle ~* 'کل بدن' THEN 'فانکشنال'
    ELSE movement_pattern
  END,
  synced_at = now()
WHERE (
    (name ~* 'هالتر' AND movement_pattern = 'کشش عمودی')
    OR main_muscle ~* '^پا$|^کل بدن$'
    OR (
      TRIM(COALESCE(main_muscle, '')) = ''
      AND name ~* '(تردمیل|دویدن|پیاده|دوچرخه|هوازی|طناب|برپی|الپتیکال)'
    )
  );

-- ─── ۲) MET / مسافت / کالری — هم‌راستا با الگوی اصلاح‌شده ───
UPDATE public.ai_exercises e
SET
  met = CASE
    WHEN e.exercise_type ~* 'هوازی' OR COALESCE(e.estimated_duration::int, 90) <= 45 THEN 8.0
    WHEN e.movement_pattern = 'هوازی' THEN 8.0
    WHEN e.movement_pattern IN ('اسکوات', 'لگد') OR e.name ~* '(اسکوات|ددلیفت)' THEN 6.0
    WHEN e.body_engagement = 'تک مفصلی' THEN 3.5
    WHEN e.name ~* '(پلانک|کرانچ|شکم)' THEN 4.0
    WHEN e.movement_pattern IN ('فشار افقی', 'فشار عمودی', 'کشش افقی', 'کشش عمودی') THEN 5.0
    ELSE 5.0
  END,
  movement_distance_cm = CASE e.movement_pattern
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
  calories_per_1000kg = CASE e.movement_pattern
    WHEN 'اسکوات' THEN 55
    WHEN 'لگد' THEN 55
    WHEN 'کشش عمودی' THEN 45
    WHEN 'کشش افقی' THEN 50
    WHEN 'فشار افقی' THEN 52
    WHEN 'فشار عمودی' THEN 48
    WHEN 'چرخشی' THEN 35
    WHEN 'هوازی' THEN 38
    ELSE 45
  END,
  synced_at = now()
WHERE
  e.name ~* 'هالتر'
  AND e.movement_pattern IN ('فشار افقی', 'فشار عمودی', 'کشش افقی');

-- بنچ/پرس سینهٔ هالتر — MET کمی بالاتر (قدرت مرکب)؛ همان مقادیر نمونه ۳۴۶۵
UPDATE public.ai_exercises
SET
  met = 5.5,
  movement_distance_cm = 45,
  calories_per_1000kg = 52,
  synced_at = now()
WHERE main_muscle ~* 'سینه'
  AND name ~* '(بنچ|پرس سینه|Bench)'
  AND name ~* 'هالتر';

-- ─── ۳) هیت‌مپ — جایگزینی {abs:50} و گروه‌های بدون قانون ───
UPDATE public.ai_exercises
SET
  muscle_targets_json = CASE
    WHEN main_muscle ~* 'سینه' THEN jsonb_build_object(
      'chest_middle', 90,
      'chest_upper', CASE WHEN name ~* 'بالا|شیب|Incline' THEN 95 ELSE 60 END,
      'chest_lower', CASE WHEN name ~* 'پایین|Decline' THEN 95 ELSE 50 END,
      'shoulder_anterior', CASE WHEN secondary_muscles ~* 'سرشانه|شانه' THEN 40 ELSE 35 END,
      'triceps', CASE WHEN secondary_muscles ~* 'پشت.?بازو|بازو' THEN 35 ELSE 30 END,
      'abs', 15
    )
    WHEN main_muscle ~* 'سرشانه|شانه' THEN jsonb_build_object(
      'shoulder_anterior', CASE WHEN name ~* 'جلو|فرانت|نشر جلو' THEN 90 ELSE 70 END,
      'shoulder_lateral', CASE WHEN name ~* 'جانب|لترال' THEN 95 ELSE 75 END,
      'shoulder_posterior', CASE WHEN name ~* 'پشت|عقب|Reverse' THEN 90 ELSE 35 END,
      'triceps', CASE WHEN secondary_muscles ~* 'پشت.?بازو' THEN 40 ELSE 25 END,
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
    WHEN main_muscle ~* '^پا$' OR main_muscle = 'پا' THEN jsonb_build_object(
      'quads', CASE WHEN name ~* 'پشت.?پا|همسترینگ|Leg Curl|Curl' THEN 40 ELSE 90 END,
      'hamstrings', CASE WHEN name ~* 'پشت.?پا|همسترینگ|RDL|ددلیفت' THEN 90 ELSE 50 END,
      'glutes', CASE WHEN name ~* 'اسکوات|لانج|هیپ|باسن' THEN 85 ELSE 50 END,
      'calf', CASE WHEN name ~* 'ساق|Calf|جلوپا' THEN 90 ELSE 35 END,
      'abs', 20
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
    WHEN main_muscle ~* 'کمر' THEN jsonb_build_object(
      'lower_back', 90,
      'back_trap', 55,
      'glutes', 35,
      'hamstrings', 40
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
    WHEN (main_muscle IS NULL OR TRIM(main_muscle) = '')
      AND name ~* '(تردمیل|دویدن|پیاده|دوچرخه|هوازی|طناب|برپی|الپتیکال|اسپرینت|بایک|Bike|اسپین|استپر|روئینگ|Rowing|اسکی|Erg|جامپینگ|های.?نیز|بات.?کیک|مانتین|کلایمر|اسکیتر|شاتل|فارتلک|بوکس|شنای|شنا|کرال)' THEN jsonb_build_object(
      'quads', 45,
      'hamstrings', 40,
      'glutes', 35,
      'calf', 40,
      'abs', 30
    )
    ELSE muscle_targets_json
  END,
  synced_at = now()
WHERE
  muscle_targets_json = '{"abs": 50}'::jsonb
  OR muscle_targets_json = '{}'::jsonb
  OR main_muscle ~* '^پا$|^کل بدن$|^کمر$'
  OR (
    (main_muscle IS NULL OR TRIM(main_muscle) = '')
    AND name ~* '(تردمیل|دویدن|پیاده|دوچرخه|هوازی|طناب|برپی|الپتیکال|اسپرینت)'
  );

COMMIT;

-- ─── بررسی ───
SELECT
  COUNT(*) FILTER (WHERE muscle_targets_json = '{"abs": 50}'::jsonb) AS generic_abs_only,
  COUNT(*) FILTER (
    WHERE name ~* 'هالتر' AND movement_pattern = 'کشش عمودی'
  ) AS barbell_wrong_lat_pattern
FROM public.ai_exercises;

SELECT id, name, movement_pattern, met, muscle_targets_json
FROM public.ai_exercises
WHERE id::text IN ('3465', '3467', '3498', '3515')
ORDER BY id::bigint;
