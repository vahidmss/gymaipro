-- =============================================================================
-- بسته خروجی برای اعتبارسنجی متا + هیت‌مپ (برای بررسی AI / متخصص)
-- در SQL Editor هر بخش را جدا اجرا کن و خروجی JSON را paste کن
-- =============================================================================

-- ─── A) سلامت کلی (یک ردیف — حتماً بفرست) ───
SELECT json_build_object(
  'total', COUNT(*),
  'empty_heatmap', COUNT(*) FILTER (
    WHERE muscle_targets_json IS NULL OR muscle_targets_json = '{}'::jsonb
  ),
  'generic_abs_only', COUNT(*) FILTER (
    WHERE muscle_targets_json = '{"abs": 50}'::jsonb
  ),
  'empty_main_muscle', COUNT(*) FILTER (WHERE TRIM(COALESCE(main_muscle, '')) = ''),
  'missing_met', COUNT(*) FILTER (WHERE met IS NULL),
  'missing_pattern', COUNT(*) FILTER (
    WHERE movement_pattern IS NULL OR TRIM(movement_pattern) = ''
  ),
  'met_distribution', (
    SELECT json_object_agg(met::text, cnt)
    FROM (
      SELECT met, COUNT(*) AS cnt
      FROM public.ai_exercises
      GROUP BY met
      ORDER BY met
    ) t
  ),
  'pattern_distribution', (
    SELECT json_object_agg(movement_pattern, cnt)
    FROM (
      SELECT movement_pattern, COUNT(*) AS cnt
      FROM public.ai_exercises
      GROUP BY movement_pattern
      ORDER BY cnt DESC
    ) t
  )
) AS health_check
FROM public.ai_exercises;

-- ─── B) نمونه طلایی — ۲۵ حرکت مرجع (حتماً بفرست) ───
-- پوش/پول/پا/هوازی/ایزوله + چند ID که قبلاً مشکل داشت
SELECT COALESCE(json_agg(row_data ORDER BY (row_data->>'id')::bigint), '[]'::json)
  AS golden_sample
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
    'heatmap_max', (
      SELECT MAX((kv.value)::int)
      FROM jsonb_each_text(e.muscle_targets_json) AS kv(key, value)
    ),
    'heatmap_keys', (
      SELECT json_agg(k ORDER BY k)
      FROM jsonb_object_keys(e.muscle_targets_json) AS k
    )
  ) AS row_data
  FROM public.ai_exercises e
  WHERE e.id::text IN (
    -- سینه / پشت / پا
    '3465', '3467', '3479', '3484', '3485', '3558',
    -- سرشانه / بازو
    '3498', '3515', '3530',
    -- هوازی / فانکشنال (قبلاً generic)
    '3620', '3621', '3624', '3632', '3647', '3649', '3651',
    -- مبتدی دستگاه
    '3831', '3832', '3842', '3844', '3847'
  )
  OR e.name IN (
    'بنچ پرس هالتر تخت',
    'اسکوات هالتر',
    'ددلیفت هالتر',
    'لت پولدان',
    'پشت پا دستگاه',
    'تردمیل دویدن',
    'پلانک'
  )
) sub;

-- ─── C) پرچم‌های منطقی — فقط موارد مشکوک (اگر خالی بود عالی است) ───
SELECT COALESCE(json_agg(row_data ORDER BY (row_data->>'id')::bigint), '[]'::json)
  AS sanity_flags
FROM (
  SELECT json_build_object(
    'id', e.id,
    'name', e.name,
    'main_muscle', e.main_muscle,
    'movement_pattern', e.movement_pattern,
    'met', e.met,
    'typical_rpe', e.typical_rpe,
    'muscle_targets_json', e.muscle_targets_json,
    'flags', flags.arr
  ) AS row_data
  FROM public.ai_exercises e
  CROSS JOIN LATERAL (
    SELECT array_remove(ARRAY[
      CASE WHEN e.muscle_targets_json = '{"abs": 50}'::jsonb THEN 'generic_abs' END,
      CASE WHEN e.name ~* 'هالتر' AND e.movement_pattern = 'کشش عمودی'
        AND e.name !~* '(جلوبازو|کرل|Curl|بایسپ)' THEN 'barbell_lat_suspicious' END,
      CASE WHEN e.name ~* '(اسالت|بایک|Bike)' AND e.movement_pattern = 'کشش عمودی'
        THEN 'salt_bike_lat_bug' END,
      CASE WHEN e.movement_pattern = 'هوازی' AND e.met IS NOT NULL AND e.met < 6
        THEN 'cardio_met_low' END,
      CASE WHEN e.movement_pattern <> 'هوازی' AND e.met IS NOT NULL AND e.met >= 8
        THEN 'strength_met_high' END,
      CASE WHEN e.main_muscle ~* 'سینه'
        AND COALESCE((e.muscle_targets_json->>'chest_middle')::int, 0) < 70
        THEN 'chest_primary_low' END,
      CASE WHEN (
        SELECT MAX((v)::int) FROM jsonb_each_text(e.muscle_targets_json) t(k, v)
      ) < 70 THEN 'heatmap_max_under_70' END,
      CASE WHEN e.difficulty = 'مبتدی' AND e.typical_rpe > 7.5 THEN 'rpe_high_for_beginner' END,
      CASE WHEN e.difficulty = 'پیشرفته' AND e.typical_rpe < 8 THEN 'rpe_low_for_advanced' END
    ], NULL) AS arr
  ) flags
  WHERE cardinality(flags.arr) > 0
) sub;

-- ─── D) هیت‌مپ بر اساس main_muscle — میانگین کلیدها (کم‌حجم، مفید) ───
SELECT COALESCE(
  json_agg(row_data ORDER BY row_data->>'main_muscle'),
  '[]'::json
) AS main_muscle_heatmap_averages
FROM (
  SELECT json_build_object(
    'main_muscle', g.main_muscle_group,
    'count', g.cnt,
    'avg_chest_middle', g.avg_chest_middle,
    'avg_back_lat', g.avg_back_lat,
    'avg_quads', g.avg_quads,
    'avg_hamstrings', g.avg_hamstrings,
    'avg_abs', g.avg_abs,
    'avg_primary_max', g.avg_primary_max
  ) AS row_data
  FROM (
    SELECT
      COALESCE(NULLIF(TRIM(e.main_muscle), ''), '(خالی)') AS main_muscle_group,
      COUNT(*) AS cnt,
      ROUND(AVG((e.muscle_targets_json->>'chest_middle')::numeric), 1) AS avg_chest_middle,
      ROUND(AVG((e.muscle_targets_json->>'back_lat')::numeric), 1) AS avg_back_lat,
      ROUND(AVG((e.muscle_targets_json->>'quads')::numeric), 1) AS avg_quads,
      ROUND(AVG((e.muscle_targets_json->>'hamstrings')::numeric), 1) AS avg_hamstrings,
      ROUND(AVG((e.muscle_targets_json->>'abs')::numeric), 1) AS avg_abs,
      ROUND(AVG(sub.max_v), 1) AS avg_primary_max
    FROM public.ai_exercises e
    CROSS JOIN LATERAL (
      SELECT MAX((v)::int) AS max_v
      FROM jsonb_each_text(e.muscle_targets_json) t(k, v)
    ) sub
    GROUP BY COALESCE(NULLIF(TRIM(e.main_muscle), ''), '(خالی)')
  ) g
) t;
