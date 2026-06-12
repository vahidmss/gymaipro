-- همان migration: supabase/migrations/20260604150000_ai_exercises_extended_json.sql
ALTER TABLE public.ai_exercises
  ADD COLUMN IF NOT EXISTS exercise_extended_json jsonb NOT NULL DEFAULT '{}'::jsonb;
