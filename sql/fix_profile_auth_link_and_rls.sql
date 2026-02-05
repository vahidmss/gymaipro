-- Fix session persistence + RLS issues when `profiles.id` (legacy) != `auth.users.id`
-- Goal:
-- 1) Add a stable link from a legacy profile to the real auth user (`profiles.auth_user_id`)
-- 2) Backfill that link for existing users (best-effort)
-- 3) Secure RLS policies for tables that reference `profiles.id` (e.g., achievements, point_history)
--
-- IMPORTANT:
-- - Run this in Supabase Dashboard -> SQL Editor
-- - It is safe to run multiple times (uses IF NOT EXISTS / idempotent statements)

-- 1) Add auth_user_id to profiles (nullable for legacy rows that can't be linked yet)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS auth_user_id UUID;

-- Optional but recommended: ensure a profile maps to at most one auth user
CREATE UNIQUE INDEX IF NOT EXISTS profiles_auth_user_id_unique
ON public.profiles(auth_user_id)
WHERE auth_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS profiles_auth_user_id_idx
ON public.profiles(auth_user_id);

-- 2) Backfill auth_user_id
-- 2a) If a profile id already matches an auth user id, link it directly
UPDATE public.profiles p
SET auth_user_id = p.id
WHERE p.auth_user_id IS NULL
  AND EXISTS (SELECT 1 FROM auth.users u WHERE u.id = p.id);

-- 2b) If profile email matches auth.users.email, link it (common in this project)
UPDATE public.profiles p
SET auth_user_id = u.id
FROM auth.users u
WHERE p.auth_user_id IS NULL
  AND p.email IS NOT NULL
  AND u.email = p.email;

-- 2c) Fix legacy mismatch: if a profile is already linked but the auth user for the same email is different,
-- overwrite auth_user_id to the auth.users.id matching that email.
-- This happens when the app created a new auth user (new UUID) for an existing profile email.
UPDATE public.profiles p
SET auth_user_id = u.id
FROM auth.users u
WHERE p.email IS NOT NULL
  AND u.email = p.email
  AND p.auth_user_id IS DISTINCT FROM u.id;

-- 3) RLS: achievements (user_id references profiles.id)
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can insert their own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can update their own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can delete their own achievements" ON public.achievements;

CREATE POLICY "Users can view their own achievements" ON public.achievements
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = achievements.user_id
        AND p.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own achievements" ON public.achievements
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = achievements.user_id
        AND p.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own achievements" ON public.achievements
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = achievements.user_id
        AND p.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own achievements" ON public.achievements
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = achievements.user_id
        AND p.auth_user_id = auth.uid()
    )
  );

-- 4) RLS: point_history (user_id references profiles.id)
ALTER TABLE public.point_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own point history" ON public.point_history;
DROP POLICY IF EXISTS "Users can insert their own point history" ON public.point_history;
DROP POLICY IF EXISTS "Users can update their own point history" ON public.point_history;
DROP POLICY IF EXISTS "Users can delete their own point history" ON public.point_history;

CREATE POLICY "Users can view their own point history" ON public.point_history
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = point_history.user_id
        AND p.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own point history" ON public.point_history
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = point_history.user_id
        AND p.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own point history" ON public.point_history
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = point_history.user_id
        AND p.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own point history" ON public.point_history
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = point_history.user_id
        AND p.auth_user_id = auth.uid()
    )
  );

-- 5) Quick verification (optional)
-- SELECT id, phone_number, email, auth_user_id FROM public.profiles ORDER BY updated_at DESC NULLS LAST LIMIT 20;
-- SELECT schemaname, tablename, policyname, cmd FROM pg_policies WHERE tablename IN ('achievements','point_history');


