-- Create RPC function for inserting OTP codes (bypassing RLS)
CREATE OR REPLACE FUNCTION public.insert_otp_code(
  p_phone_number TEXT,
  p_code TEXT,
  p_expires_at TIMESTAMPTZ
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.otp_codes (phone_number, code, expires_at, is_used)
  VALUES (p_phone_number, p_code, p_expires_at, false);
  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error inserting OTP code: %', SQLERRM;
    RETURN false;
END;
$$;

-- Grant execute permissions to anonymous and authenticated users
GRANT EXECUTE ON FUNCTION public.insert_otp_code TO anon;
GRANT EXECUTE ON FUNCTION public.insert_otp_code TO authenticated;

-- Ensure the otp_codes table exists
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

-- Disable RLS for otp_codes to ensure the function works
ALTER TABLE public.otp_codes DISABLE ROW LEVEL SECURITY; 