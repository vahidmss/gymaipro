-- فیلدهای متا حرکت (وردپرس → Supabase) + هیت‌مپ
-- جدول: public.ai_exercises
-- بعد از اجرا: از پنل ادمین «Sync تمرین‌ها» را بزنید تا داده پر شود.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'ai_exercises'
  ) THEN
    RAISE EXCEPTION 'جدول public.ai_exercises وجود ندارد. ابتدا جدول را ایجاد کنید.';
  END IF;
END $$;

-- توضیحات و محتوای اپ
ALTER TABLE public.ai_exercises
  ADD COLUMN IF NOT EXISTS short_description text,
  ADD COLUMN IF NOT EXISTS detailed_description text,
  ADD COLUMN IF NOT EXISTS learn text,
  ADD COLUMN IF NOT EXISTS seo_content text;

-- متادیتای تمرینی (از وردپرس)
ALTER TABLE public.ai_exercises
  ADD COLUMN IF NOT EXISTS movement_pattern text,
  ADD COLUMN IF NOT EXISTS body_engagement text,
  ADD COLUMN IF NOT EXISTS estimated_1rm_formula text;

-- هیت‌مپ: {"hamstrings":95,"glutes":85,...}
ALTER TABLE public.ai_exercises
  ADD COLUMN IF NOT EXISTS muscle_targets_json jsonb NOT NULL DEFAULT '{}'::jsonb;

-- متریک‌ها
ALTER TABLE public.ai_exercises
  ADD COLUMN IF NOT EXISTS met numeric(4, 1),
  ADD COLUMN IF NOT EXISTS movement_distance_cm integer,
  ADD COLUMN IF NOT EXISTS calories_per_1000kg integer,
  ADD COLUMN IF NOT EXISTS exercise_difficulty_score smallint,
  ADD COLUMN IF NOT EXISTS typical_rpe numeric(3, 1);

-- آمار (اختیاری — از وردپرس)
ALTER TABLE public.ai_exercises
  ADD COLUMN IF NOT EXISTS views_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS likes_count integer NOT NULL DEFAULT 0;

-- زمان آخرین تغییر در وردپرس (برای sync و bust کش تصویر)
ALTER TABLE public.ai_exercises
  ADD COLUMN IF NOT EXISTS wordpress_modified timestamptz;

-- زمان آخرین sync به Supabase
ALTER TABLE public.ai_exercises
  ADD COLUMN IF NOT EXISTS synced_at timestamptz NOT NULL DEFAULT now();

COMMENT ON COLUMN public.ai_exercises.short_description IS 'توضیح کوتاه برای اپ (از meta.short_description وردپرس)';
COMMENT ON COLUMN public.ai_exercises.muscle_targets_json IS 'هیت‌مپ عضلات 0-100؛ کلیدها مثل hamstrings, chest_middle';
COMMENT ON COLUMN public.ai_exercises.met IS 'MET — متابولیک معادل تمرین';
COMMENT ON COLUMN public.ai_exercises.wordpress_modified IS 'فیلد modified از REST وردپرس';

-- ایندکس برای فیلتر آینده بر اساس الگوی حرکت / ناحیه
CREATE INDEX IF NOT EXISTS idx_ai_exercises_movement_pattern
  ON public.ai_exercises (movement_pattern)
  WHERE movement_pattern IS NOT NULL AND movement_pattern <> '';

CREATE INDEX IF NOT EXISTS idx_ai_exercises_muscle_targets_json
  ON public.ai_exercises USING gin (muscle_targets_json);

-- RPC خواندن برای AI — همه ستون‌های جدید را برمی‌گرداند
DROP FUNCTION IF EXISTS public.ai_exercises_list(integer);

CREATE OR REPLACE FUNCTION public.ai_exercises_list(limit_count integer DEFAULT 500)
RETURNS SETOF public.ai_exercises
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT *
  FROM public.ai_exercises
  ORDER BY name
  LIMIT GREATEST(1, LEAST(limit_count, 2000));
$$;

GRANT EXECUTE ON FUNCTION public.ai_exercises_list(integer) TO anon, authenticated, service_role;
