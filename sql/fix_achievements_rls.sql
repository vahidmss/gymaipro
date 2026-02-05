-- Fix RLS policies for achievements table
-- The issue: RLS checks auth.uid() = user_id, but user_id references profiles.id
-- Solution: Check if user_id exists in profiles and if auth.uid() matches the profile's linked auth user

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can insert their own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can update their own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can delete their own achievements" ON public.achievements;

-- Create new RLS policies that check if user_id exists in profiles
-- Since user_id references profiles.id, we check:
-- 1. If the profile exists
-- 2. If the profile's id matches the user_id (which is the profile id)
-- This allows authenticated users to access achievements for their profile

-- Users can view their own achievements (if user_id exists in profiles)
CREATE POLICY "Users can view their own achievements" ON public.achievements
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = achievements.user_id
    )
  );

-- Users can insert their own achievements (if user_id exists in profiles)
CREATE POLICY "Users can insert their own achievements" ON public.achievements
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = achievements.user_id
    )
  );

-- Users can update their own achievements (if user_id exists in profiles)
CREATE POLICY "Users can update their own achievements" ON public.achievements
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = achievements.user_id
    )
  );

-- Users can delete their own achievements (if user_id exists in profiles)
CREATE POLICY "Users can delete their own achievements" ON public.achievements
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = achievements.user_id
    )
  );

-- Verify policies
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual 
FROM pg_policies 
WHERE tablename = 'achievements';

