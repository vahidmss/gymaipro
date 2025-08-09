-- Fix registration policy for new users

-- Drop the problematic policy that requires auth.uid() = id
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

-- Also create a more permissive policy for registration validation
CREATE POLICY "Allow registration checks" ON public.profiles
  FOR SELECT USING (
    -- Allow checking username and phone number during registration
    true
  ); 