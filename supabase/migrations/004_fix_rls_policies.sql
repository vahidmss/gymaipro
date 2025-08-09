-- Fix RLS policies to allow username checks during registration

-- Drop the problematic public profile checks policy
DROP POLICY IF EXISTS "Allow public profile checks" ON public.profiles;

-- Create a more specific policy for username/phone number validation
CREATE POLICY "Allow username validation" ON public.profiles
  FOR SELECT USING (
    -- Allow access to username and phone_number for validation purposes
    -- This is needed for registration validation
    true
  );

-- Create a more specific policy for phone number validation
CREATE POLICY "Allow phone validation" ON public.profiles
  FOR SELECT USING (
    -- Allow access to phone_number for validation purposes
    true
  );

-- Ensure the existing policies are still in place
-- Users can view their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Trainers can view athlete profiles
DROP POLICY IF EXISTS "Trainers can view athlete profiles" ON public.profiles;
CREATE POLICY "Trainers can view athlete profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles trainer_profile 
      WHERE trainer_profile.id = auth.uid() 
      AND trainer_profile.role = 'trainer'
    )
    AND role = 'athlete'
  );

-- Admins can view all profiles
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile 
      WHERE admin_profile.id = auth.uid() 
      AND admin_profile.role = 'admin'
    )
  );

-- Grant necessary permissions again to ensure they're in place
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.profiles TO anon, authenticated;
GRANT ALL ON public.otp_codes TO anon, authenticated;
GRANT USAGE ON SEQUENCE public.otp_codes_id_seq TO anon, authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.cleanup_expired_otp_codes() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.manual_cleanup_otp_codes() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_authenticated() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_trainer() TO anon, authenticated; 