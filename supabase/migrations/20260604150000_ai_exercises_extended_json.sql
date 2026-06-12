-- متادیتای توسعه‌یافته v3.6 (programming, instructions, classification کامل)
ALTER TABLE public.ai_exercises
  ADD COLUMN IF NOT EXISTS exercise_extended_json jsonb NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.ai_exercises.exercise_extended_json IS
  'شاخه‌های v3.6: programming, instructions, safety, classification اضافی';

CREATE INDEX IF NOT EXISTS idx_ai_exercises_extended_json
  ON public.ai_exercises USING gin (exercise_extended_json);
