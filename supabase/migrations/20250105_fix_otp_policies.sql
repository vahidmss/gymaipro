-- Fix OTP codes policies

-- Drop existing policies for otp_codes
DROP POLICY IF EXISTS "Enable all operations" ON public.otp_codes;
DROP POLICY IF EXISTS "Allow anon/auth insert access for OTP codes" ON public.otp_codes;
DROP POLICY IF EXISTS "Allow anon/auth read access for OTP verification" ON public.otp_codes;
DROP POLICY IF EXISTS "Allow anon/auth update access for OTP codes" ON public.otp_codes;

-- Create new permissive policies for otp_codes
CREATE POLICY "Allow anonymous OTP insert" ON public.otp_codes
    FOR INSERT
    TO anon
    WITH CHECK (true);

CREATE POLICY "Allow authenticated OTP operations" ON public.otp_codes
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Make sure table exists and RLS is temporarily disabled for testing
CREATE TABLE IF NOT EXISTS public.otp_codes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  phone_number text NOT NULL,
  code text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  expires_at timestamp with time zone NOT NULL,
  is_used boolean NULL DEFAULT false,
  used_at timestamp with time zone NULL,
  CONSTRAINT otp_codes_pkey PRIMARY KEY (id)
);

-- Disable RLS for otp_codes temporarily
ALTER TABLE public.otp_codes DISABLE ROW LEVEL SECURITY; 