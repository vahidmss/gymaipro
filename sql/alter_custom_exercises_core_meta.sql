-- فقط برای دیتابیس‌هایی که جدول custom_exercises از قبل دارند.
ALTER TABLE public.custom_exercises
  ADD COLUMN IF NOT EXISTS met numeric(4, 1),
  ADD COLUMN IF NOT EXISTS typical_rpe numeric(3, 1),
  ADD COLUMN IF NOT EXISTS movement_pattern text,
  ADD COLUMN IF NOT EXISTS body_engagement text,
  ADD COLUMN IF NOT EXISTS mechanics_type text,
  ADD COLUMN IF NOT EXISTS force_type text,
  ADD COLUMN IF NOT EXISTS calories_per_1000kg integer;
