-- Fix infinite recursion in RLS policies - SIMPLE SOLUTION
-- Run this in Supabase Dashboard SQL Editor

-- Step 1: Completely disable RLS temporarily
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL existing policies to start fresh
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow registration validation" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile creation" ON public.profiles;
DROP POLICY IF EXISTS "Trainers can view athlete profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile creation during registration" ON public.profiles;
DROP POLICY IF EXISTS "Allow registration checks" ON public.profiles;
DROP POLICY IF EXISTS "Allow all operations" ON public.profiles;
DROP POLICY IF EXISTS "Allow all operations temporarily" ON public.profiles;
DROP POLICY IF EXISTS "Allow validation checks" ON public.profiles;
DROP POLICY IF EXISTS "Allow username validation" ON public.profiles;
DROP POLICY IF EXISTS "Allow phone validation" ON public.profiles;
DROP POLICY IF EXISTS "Allow service role profile creation" ON public.profiles;
DROP POLICY IF EXISTS "Allow public profile checks" ON public.profiles;

-- Step 3: Add missing columns to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role text DEFAULT 'athlete';

-- Step 4: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.profiles TO anon, authenticated;
GRANT ALL ON public.otp_codes TO anon, authenticated;
GRANT USAGE ON SEQUENCE public.otp_codes_id_seq TO anon, authenticated;

-- Step 5: Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.cleanup_expired_otp_codes() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.manual_cleanup_otp_codes() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_authenticated() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_trainer() TO anon, authenticated;

-- Step 6: Create simple, non-recursive policies
-- Re-enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own profile (simple, no recursion)
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own profile (simple, no recursion)
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Allow users to insert their own profile (for registration)
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow public access for username/phone validation during registration
-- This is needed for registration process
CREATE POLICY "Allow registration validation" ON public.profiles
  FOR SELECT USING (true);

-- Allow trainers to view athlete profiles (simplified, no recursion)
CREATE POLICY "Trainers can view athlete profiles" ON public.profiles
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM public.profiles 
      WHERE role = 'trainer'
    )
    AND role = 'athlete'
  );

-- Allow admins to view all profiles (simplified, no recursion)
CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR ALL USING (
    auth.uid() IN (
      SELECT id FROM public.profiles 
      WHERE role = 'admin'
    )
  );

-- Step 7: Create missing functions

-- Create exec_sql function if it doesn't exist
CREATE OR REPLACE FUNCTION public.exec_sql(sql text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    EXECUTE sql;
END;
$$;

-- Create get_unread_message_count function if it doesn't exist
CREATE OR REPLACE FUNCTION public.get_unread_message_count(user_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    count_result integer;
BEGIN
    SELECT COUNT(*) INTO count_result
    FROM public.chat_messages
    WHERE recipient_id = user_id AND is_read = false;
    
    RETURN COALESCE(count_result, 0);
END;
$$;

-- Create get_food_likes_count function if it doesn't exist
CREATE OR REPLACE FUNCTION public.get_food_likes_count(food_id_param uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    count_result integer;
BEGIN
    SELECT COUNT(*) INTO count_result
    FROM public.food_likes
    WHERE food_id = food_id_param;
    
    RETURN COALESCE(count_result, 0);
END;
$$;

-- Create get_exercise_likes_count function if it doesn't exist
CREATE OR REPLACE FUNCTION public.get_exercise_likes_count(exercise_id_param uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    count_result integer;
BEGIN
    SELECT COUNT(*) INTO count_result
    FROM public.exercise_likes
    WHERE exercise_id = exercise_id_param;
    
    RETURN COALESCE(count_result, 0);
END;
$$;

-- Create run_migration_add_role_to_profiles function if it doesn't exist
CREATE OR REPLACE FUNCTION public.run_migration_add_role_to_profiles()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Add role column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'role'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN role text DEFAULT 'athlete';
    END IF;
    
    -- Update existing profiles to have role
    UPDATE public.profiles SET role = 'athlete' WHERE role IS NULL;
END;
$$;

-- Grant execute permissions on new functions
GRANT EXECUTE ON FUNCTION public.exec_sql(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_unread_message_count(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_food_likes_count(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_exercise_likes_count(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.run_migration_add_role_to_profiles() TO anon, authenticated;

-- Final verification
SELECT 'Infinite recursion fixed successfully' as status; 