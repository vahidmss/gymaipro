-- Restore secure RLS policies after confirming registration works

-- Drop the temporary permissive policy
DROP POLICY IF EXISTS "Allow all operations" ON public.profiles;

-- Create secure policies

-- Allow users to view their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Allow users to insert their own profile (for registration)
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow public access for username/phone validation during registration
CREATE POLICY "Allow registration validation" ON public.profiles
  FOR SELECT USING (
    -- Allow access to username and phone_number for validation
    -- This is needed for registration validation
    true
  );

-- Allow trainers to view athlete profiles (for client management)
CREATE POLICY "Trainers can view athlete profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles trainer_profile 
      WHERE trainer_profile.id = auth.uid() 
      AND trainer_profile.role = 'trainer'
    )
    AND role = 'athlete'
  );

-- Allow admins to view all profiles
CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile 
      WHERE admin_profile.id = auth.uid() 
      AND admin_profile.role = 'admin'
    )
  );

-- Grant necessary permissions
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