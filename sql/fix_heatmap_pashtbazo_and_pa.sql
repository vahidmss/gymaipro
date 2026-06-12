-- =============================================================================
-- اصلاح هیت‌مپ: پشت‌بازو (اشتباه back_lat) + پا (primary_max پایین)
-- اجرا یک‌بار در Supabase
-- =============================================================================

BEGIN;

UPDATE public.ai_exercises
SET
  muscle_targets_json = jsonb_build_object(
    'triceps', 95,
    'forearms', 25
  ),
  movement_pattern = COALESCE(
    NULLIF(TRIM(movement_pattern), ''),
    'فشار عمودی'
  ),
  synced_at = now()
WHERE main_muscle ~* 'پشت.?بازو|سه.?سر|ترایسپ';

UPDATE public.ai_exercises
SET
  muscle_targets_json = CASE
    WHEN name ~* 'پشت.?پا|همسترینگ|Leg Curl' THEN jsonb_build_object(
      'hamstrings', 95,
      'glutes', 30,
      'quads', 35,
      'calf', 25,
      'abs', 10
    )
    WHEN name ~* 'ساق|Calf|جلوپا' THEN jsonb_build_object(
      'calf', 95,
      'quads', 25,
      'hamstrings', 20
    )
    WHEN name ~* 'اسکوات|لانج|هیپ|باسن|اسپلیت' THEN jsonb_build_object(
      'quads', 90,
      'glutes', 85,
      'hamstrings', 50,
      'calf', 35,
      'abs', 25
    )
    ELSE jsonb_build_object(
      'quads', 90,
      'hamstrings', 50,
      'glutes', 55,
      'calf', 35,
      'abs', 20
    )
  END,
  synced_at = now()
WHERE main_muscle ~* '^پا$' OR TRIM(main_muscle) = 'پا';

-- ۱۶ رکورد هنوز main_muscle خالی → کل بدن + هیت‌مپ پایه
UPDATE public.ai_exercises
SET
  main_muscle = 'کل بدن',
  movement_pattern = COALESCE(NULLIF(TRIM(movement_pattern), ''), 'فانکشنال'),
  muscle_targets_json = jsonb_build_object(
    'quads', 50,
    'hamstrings', 45,
    'glutes', 40,
    'calf', 45,
    'abs', 35,
    'shoulder_anterior', 25
  ),
  synced_at = now()
WHERE TRIM(COALESCE(main_muscle, '')) = '';

COMMIT;

-- چک سریع
SELECT
  main_muscle,
  ROUND(AVG((muscle_targets_json->>'triceps')::numeric), 1) AS avg_triceps,
  ROUND(AVG((muscle_targets_json->>'back_lat')::numeric), 1) AS avg_back_lat,
  ROUND(AVG((
    SELECT MAX((v)::int) FROM jsonb_each_text(muscle_targets_json) t(k, v)
  )), 1) AS avg_primary_max
FROM public.ai_exercises
WHERE main_muscle ~* 'پشت.?بازو|^پا$'
   OR TRIM(main_muscle) IN ('پا', 'پشت‌بازو')
GROUP BY main_muscle;
