-- Fix registration policy while maintaining security

-- Drop the problematic policy that requires auth.uid() = id for INSERT
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

-- Create a policy that allows profile creation during registration
CREATE POLICY "Allow profile creation during registration" ON public.profiles
  FOR INSERT WITH CHECK (
    -- Allow insertion if the user is authenticated and the id matches
    (auth.uid() = id)
    OR
    -- Allow insertion for registration (when user is not yet authenticated)
    (auth.uid() IS NULL AND id IS NOT NULL)
  );

-- Keep all other policies as they are
-- The existing policies for SELECT, UPDATE, and role-based access remain unchanged 