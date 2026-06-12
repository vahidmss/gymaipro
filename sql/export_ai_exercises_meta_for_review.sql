-- =============================================================================
-- خروجی فشرده برای بررسی/اصلاح متا — Supabase SQL Editor
-- فقط فیلدهای ضروری + پرچم مشکل؛ بدون content / source / image
-- =============================================================================

-- ─── ۱) خلاصه وضعیت (همین یک ردیف را کافی است ببینی) ───
SELECT json_build_object(
  'total', COUNT(*),
  'generic_abs_only', COUNT(*) FILTER (WHERE muscle_targets_json = '{"abs": 50}'::jsonb),
  'barbell_wrong_lat', COUNT(*) FILTER (
    WHERE name ~* 'هالتر' AND movement_pattern = 'کشش عمودی'
  ),
  'empty_main_muscle', COUNT(*) FILTER (WHERE TRIM(COALESCE(main_muscle, '')) = ''),
  'missing_movement_pattern', COUNT(*) FILTER (
    WHERE movement_pattern IS NULL OR TRIM(movement_pattern) = ''
  ),
  'missing_met', COUNT(*) FILTER (WHERE met IS NULL)
) AS summary
FROM public.ai_exercises;

-- ─── ۲) فقط حرکت‌های مشکوک — برای paste در چت (کم‌حجم) ───
-- نتیجه: یک آرایه JSON — کل خروجی را کپی کن
SELECT COALESCE(
  json_agg(row_data ORDER BY (row_data->>'id')::bigint),
  '[]'::json
) AS exercises_need_review
FROM (
  SELECT json_build_object(
    'id', e.id,
    'name', e.name,
    'main_muscle', NULLIF(TRIM(e.main_muscle), ''),
    'secondary_muscles', NULLIF(TRIM(e.secondary_muscles), ''),
    'difficulty', e.difficulty,
    'equipment', e.equipment,
    'exercise_type', e.exercise_type,
    'movement_pattern', e.movement_pattern,
    'body_engagement', e.body_engagement,
    'muscle_targets_json', e.muscle_targets_json,
    'met', e.met,
    'movement_distance_cm', e.movement_distance_cm,
    'calories_per_1000kg', e.calories_per_1000kg,
    'typical_rpe', e.typical_rpe,
    'exercise_difficulty_score', e.exercise_difficulty_score,
    'flags', json_build_object(
      'generic_abs_only', (e.muscle_targets_json = '{"abs": 50}'::jsonb),
      'barbell_wrong_lat', (e.name ~* 'هالتر' AND e.movement_pattern = 'کشش عمودی'),
      'empty_main_muscle', (TRIM(COALESCE(e.main_muscle, '')) = ''),
      'empty_heatmap', (
        e.muscle_targets_json IS NULL
        OR e.muscle_targets_json = '{}'::jsonb
      )
    )
  ) AS row_data
  FROM public.ai_exercises e
  WHERE
    e.muscle_targets_json = '{"abs": 50}'::jsonb
    OR (e.name ~* 'هالتر' AND e.movement_pattern = 'کشش عمودی')
    OR TRIM(COALESCE(e.main_muscle, '')) = ''
    OR e.muscle_targets_json IS NULL
    OR e.muscle_targets_json = '{}'::jsonb
    OR e.movement_pattern IS NULL
    OR TRIM(e.movement_pattern) = ''
    OR e.met IS NULL
) sub;

-- ─── ۳) همه حرکت‌ها — فقط متا ضروری (اگر خواستی کل ۲۱۸ را بدهی؛ ~۵۰KB) ───
-- اگر خروجی خیلی بزرگ شد، فقط بخش ۲ را بفرست
SELECT COALESCE(
  json_agg(row_data ORDER BY (row_data->>'id')::bigint),
  '[]'::json
) AS exercises_all_meta_compact
FROM (
  SELECT json_build_object(
    'id', e.id,
    'name', e.name,
    'main_muscle', NULLIF(TRIM(e.main_muscle), ''),
    'secondary_muscles', NULLIF(TRIM(e.secondary_muscles), ''),
    'difficulty', e.difficulty,
    'equipment', e.equipment,
    'exercise_type', e.exercise_type,
    'movement_pattern', e.movement_pattern,
    'body_engagement', e.body_engagement,
    'muscle_targets_json', e.muscle_targets_json,
    'met', e.met,
    'movement_distance_cm', e.movement_distance_cm,
    'calories_per_1000kg', e.calories_per_1000kg,
    'typical_rpe', e.typical_rpe,
    'exercise_difficulty_score', e.exercise_difficulty_score
  ) AS row_data
  FROM public.ai_exercises e
) sub;

-- ─── ۴) گروه‌بندی ۵۷ generic — خیلی کوتاه (برای تشخیص سریع) ───
SELECT
  COALESCE(NULLIF(TRIM(main_muscle), ''), '(خالی)') AS main_muscle,
  COUNT(*) AS cnt,
  json_agg(
    json_build_object('id', id, 'name', name, 'movement_pattern', movement_pattern)
    ORDER BY id::bigint
  ) AS samples
FROM public.ai_exercises
WHERE muscle_targets_json = '{"abs": 50}'::jsonb
GROUP BY 1
ORDER BY cnt DESC;

-- ─── ۵) هالتر + کشش عمودی — جدا کردن «احتمالاً درست» (جلوبازو) از «مشکوک» ───
SELECT
  id,
  name,
  main_muscle,
  movement_pattern,
  (name ~* '(جلوبازو|کرل|Curl|بایسپ)') AS probably_ok_curl
FROM public.ai_exercises
WHERE name ~* 'هالتر' AND movement_pattern = 'کشش عمودی'
ORDER BY probably_ok_curl, id::bigint;

-- ─── ۶) جدولی برای چشم — نمونه generic ───
SELECT id, name, main_muscle, movement_pattern, muscle_targets_json
FROM public.ai_exercises
WHERE name ~* 'هالتر' AND movement_pattern = 'کشش عمودی'
ORDER BY id::bigint;

SELECT id, name, main_muscle, movement_pattern, muscle_targets_json
FROM public.ai_exercises
WHERE muscle_targets_json = '{"abs": 50}'::jsonb
ORDER BY id::bigint
LIMIT 15;
