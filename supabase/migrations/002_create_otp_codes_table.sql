-- Create otp_codes table
CREATE TABLE public.otp_codes (
  id bigserial NOT NULL,
  phone_number text NOT NULL,
  code text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  expires_at timestamp with time zone NOT NULL,
  is_used boolean NOT NULL DEFAULT false,
  used_at timestamp with time zone NULL,
  
  CONSTRAINT otp_codes_pkey PRIMARY KEY (id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_otp_codes_phone_number ON public.otp_codes USING btree (phone_number);
CREATE INDEX IF NOT EXISTS idx_otp_codes_expires_at ON public.otp_codes USING btree (expires_at);
CREATE INDEX IF NOT EXISTS idx_otp_codes_is_used ON public.otp_codes USING btree (is_used);

-- Create function to clean up expired OTP codes
CREATE OR REPLACE FUNCTION public.cleanup_expired_otp_codes()
RETURNS void AS $$
BEGIN
  -- Delete expired OTP codes (older than 24 hours)
  DELETE FROM public.otp_codes 
  WHERE expires_at < now() - interval '24 hours';
  
  -- Log cleanup operation
  RAISE NOTICE 'Cleaned up expired OTP codes at %', now();
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to clean up expired OTP codes daily
-- Note: This requires pg_cron extension to be enabled
-- If pg_cron is not available, you can call this function manually or via application logic

-- Alternative: Create a trigger to clean up when inserting new OTP codes
CREATE OR REPLACE FUNCTION public.cleanup_expired_otp_on_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- Clean up expired codes before inserting new ones
  DELETE FROM public.otp_codes 
  WHERE expires_at < now() - interval '24 hours';
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically clean up expired OTP codes
CREATE TRIGGER trigger_cleanup_expired_otp
  BEFORE INSERT ON public.otp_codes
  FOR EACH ROW
  EXECUTE FUNCTION public.cleanup_expired_otp_on_insert();

-- Optional: Create a function to manually clean up (can be called from application)
CREATE OR REPLACE FUNCTION public.manual_cleanup_otp_codes()
RETURNS integer AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.otp_codes 
  WHERE expires_at < now() - interval '24 hours';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RAISE NOTICE 'Manually cleaned up % expired OTP codes', deleted_count;
  
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql; 