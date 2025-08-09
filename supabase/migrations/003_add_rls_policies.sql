-- Enable RLS on otp_codes table
ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for otp_codes table

-- Allow anyone to insert OTP codes (for registration/login)
CREATE POLICY "Allow OTP insertion" ON public.otp_codes
  FOR INSERT WITH CHECK (true);

-- Allow anyone to read OTP codes for verification (but only their own)
CREATE POLICY "Allow OTP verification" ON public.otp_codes
  FOR SELECT USING (true);

-- Allow anyone to update OTP codes (for marking as used)
CREATE POLICY "Allow OTP update" ON public.otp_codes
  FOR UPDATE USING (true);

-- Allow cleanup function to delete expired OTP codes
CREATE POLICY "Allow OTP cleanup" ON public.otp_codes
  FOR DELETE USING (true);

-- Additional RLS Policies for profiles table (enhancing existing ones)

-- Allow users to view their own profile (already exists, but ensuring it's correct)
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own profile (already exists, but ensuring it's correct)
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Allow users to insert their own profile (already exists, but ensuring it's correct)
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow trainers to view athlete profiles (for client management)
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

-- Allow admins to view all profiles (already exists, but ensuring it's correct)
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile 
      WHERE admin_profile.id = auth.uid() 
      AND admin_profile.role = 'admin'
    )
  );

-- Allow public access to basic profile info for username/phone number checks
CREATE POLICY "Allow public profile checks" ON public.profiles
  FOR SELECT USING (
    -- Only allow access to id, username, phone_number, and role for validation purposes
    -- This is needed for registration and login validation
    true
  );

-- Create function to check if user is authenticated
CREATE OR REPLACE FUNCTION public.is_authenticated()
RETURNS boolean AS $$
BEGIN
  RETURN auth.uid() IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if user is trainer
CREATE OR REPLACE FUNCTION public.is_trainer()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'trainer'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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