-- HOTFIX: Prevent infinite recursion in RLS policies for public.profiles
-- Run this in Supabase SQL editor as 'postgres' (default in dashboard)

-- 1) Ensure helper functions exist and run with SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_trainer()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'trainer'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_trainer() TO anon, authenticated;

-- 2) Recreate minimal, non-recursive RLS policies on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies to avoid conflicts/recursion
DO $$
BEGIN
  PERFORM 1 FROM pg_policies WHERE schemaname='public' AND tablename='profiles';
  IF FOUND THEN
    EXECUTE 'DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Admins can delete any profile" ON public.profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Trainers can view athlete profiles" ON public.profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Allow registration validation" ON public.profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Allow validation checks" ON public.profiles';
  END IF;
END $$;

-- Consolidated non-recursive policies
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT
  USING (
    -- user can read own row
    auth.uid() = id
    -- admins can read all
    OR public.is_admin()
    -- trainers can read athletes only (without self-referencing policy recursion)
    OR (public.is_trainer() AND role = 'athlete')
  );

CREATE POLICY "profiles_insert" ON public.profiles
  FOR INSERT
  WITH CHECK (
    auth.uid() = id OR public.is_admin()
  );

CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE
  USING (
    auth.uid() = id OR public.is_admin()
  );

CREATE POLICY "profiles_delete" ON public.profiles
  FOR DELETE
  USING (
    auth.uid() = id OR public.is_admin()
  );

-- Optional: If you need public checks for username/phone during registration,
-- create a SAFE RPC that returns boolean instead of opening SELECTs on profiles.
-- Example (not enabled by default):
-- CREATE OR REPLACE FUNCTION public.is_username_available(username_text text)
-- RETURNS boolean
-- LANGUAGE plpgsql
-- SECURITY DEFINER
-- AS $$
-- DECLARE exists_user boolean;
-- BEGIN
--   SELECT EXISTS(SELECT 1 FROM public.profiles WHERE username = username_text) INTO exists_user;
--   RETURN NOT COALESCE(exists_user, false);
-- END;
-- $$;
-- GRANT EXECUTE ON FUNCTION public.is_username_available(text) TO anon, authenticated;

-- Grants (minimal sane defaults)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT ON public.profiles TO anon;

-- Done
SELECT 'profiles RLS hotfix applied' AS status;


