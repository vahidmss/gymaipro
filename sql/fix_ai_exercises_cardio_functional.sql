-- =============================================================================
-- اصلاح هوازی / فانکشنال با main_muscle خالی و هیت‌مپ {abs:50}
-- باگ: «لت» داخل «اسالت» (ایر بایک اسالت بایک) → کشش عمودی اشتباه
-- اجرا در Supabase SQL Editor
-- =============================================================================

BEGIN;

-- الگوی نام مشترک تجهیزات و حرکات هوازی/فانکشنال
-- (در UPDATEها تکرار شده تا وابسته به متغیر نباشد)

UPDATE public.ai_exercises
SET
  main_muscle = 'کل بدن',
  target_area = COALESCE(NULLIF(TRIM(target_area), ''), 'کل بدن'),
  movement_pattern = 'هوازی',
  body_engagement = 'چند مفصلی',
  met = 8.0,
  movement_distance_cm = 0,
  calories_per_1000kg = 38,
  typical_rpe = COALESCE(typical_rpe, 7.0),
  exercise_difficulty_score = COALESCE(exercise_difficulty_score, 4),
  muscle_targets_json = CASE
    WHEN name ~* '(روئینگ|Rowing|روینگ)' THEN jsonb_build_object(
      'back_lat', 55,
      'back_trap', 45,
      'biceps', 40,
      'shoulder_posterior', 40,
      'quads', 45,
      'hamstrings', 40,
      'glutes', 35,
      'abs', 30,
      'calf', 25
    )
    WHEN name ~* '(بوکس|Boxing|سایه.?بوکس|کیسه)' THEN jsonb_build_object(
      'shoulder_anterior', 55,
      'shoulder_lateral', 40,
      'triceps', 45,
      'abs', 50,
      'quads', 40,
      'calf', 35,
      'forearms', 30
    )
    WHEN name ~* '(شنای|شنا|کرال|Swim)' THEN jsonb_build_object(
      'back_lat', 55,
      'chest_middle', 45,
      'shoulder_anterior', 50,
      'triceps', 35,
      'quads', 30,
      'hamstrings', 25,
      'abs', 35,
      'calf', 25
    )
    WHEN name ~* '(جامپینگ|Jumping|های.?نیز|بات.?کیک|مانتین|کلایمر|اسکیتر|برپی|Burpee)' THEN jsonb_build_object(
      'quads', 55,
      'glutes', 50,
      'hamstrings', 45,
      'calf', 45,
      'abs', 55,
      'shoulder_anterior', 35
    )
    ELSE jsonb_build_object(
      'quads', 50,
      'hamstrings', 45,
      'glutes', 40,
      'calf', 45,
      'abs', 35,
      'shoulder_anterior', 25
    )
  END,
  synced_at = now()
WHERE
  TRIM(COALESCE(main_muscle, '')) = ''
  AND (
    muscle_targets_json = '{"abs": 50}'::jsonb
    OR muscle_targets_json IS NULL
    OR muscle_targets_json = '{}'::jsonb
  )
  AND name ~* (
    'تردمیل|دویدن|پیاده|دوچرخه|الپتیکال|هوازی|طناب|برپی|Burpee|اسپرینت|'
    || 'بایک|Bike|اسپین|Spin|ایر|Air|استپر|Stepper|پله|'
    || 'روئینگ|Rowing|روینگ|اسکی|Erg|Ski|'
    || 'جامپینگ|Jumping|های.?نیز|High.?Knee|بات.?کیک|Butt|'
    || 'مانتین|Mountain|کلایمر|Climber|اسکیتر|Skater|'
    || 'شاتل|Shuttle|فارتلک|Fartlek|'
    || 'بوکس|Boxing|سایه|کیسه|'
    || 'شنای|شنا|کرال|Swim'
  );

-- هر رکورد با main_muscle خالی که هنوز generic مانده → همان هیت‌مپ پایه هوازی
UPDATE public.ai_exercises
SET
  main_muscle = COALESCE(NULLIF(TRIM(main_muscle), ''), 'کل بدن'),
  movement_pattern = 'هوازی',
  body_engagement = 'چند مفصلی',
  met = 8.0,
  movement_distance_cm = 0,
  calories_per_1000kg = 38,
  muscle_targets_json = jsonb_build_object(
    'quads', 50,
    'hamstrings', 45,
    'glutes', 40,
    'calf', 45,
    'abs', 35,
    'shoulder_anterior', 25
  ),
  synced_at = now()
WHERE
  TRIM(COALESCE(main_muscle, '')) = ''
  AND muscle_targets_json = '{"abs": 50}'::jsonb;

-- اصلاح «لت» داخل «اسالت» و مشابه (بدون وابستگی به هالتر)
UPDATE public.ai_exercises
SET
  movement_pattern = CASE
    WHEN name ~* '(بایک|Bike|اسپین|استپر|روئینگ|Rowing|تردمیل|دویدن|پیاده)' THEN 'هوازی'
    WHEN name ~* '(بوکس|Boxing|جامپینگ|برپی|شاتل|فارتلک)' THEN 'هوازی'
    ELSE movement_pattern
  END,
  synced_at = now()
WHERE
  movement_pattern = 'کشش عمودی'
  AND name ~* '(اسالت|بایک|Bike|استپر|روئینگ|Rowing)';

COMMIT;

-- بررسی نمونه‌های شما
SELECT id, name, main_muscle, movement_pattern, met, muscle_targets_json
FROM public.ai_exercises
WHERE id::bigint BETWEEN 3620 AND 3651
ORDER BY id::bigint;

SELECT COUNT(*) FILTER (WHERE muscle_targets_json = '{"abs": 50}'::jsonb) AS generic_abs_left
FROM public.ai_exercises;
