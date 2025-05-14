-- Create OTP Codes table
create table public.otp_codes (
  id uuid not null default gen_random_uuid(),
  phone_number text not null,
  code text not null,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  expires_at timestamp with time zone not null,
  is_used boolean null default false,
  used_at timestamp with time zone null
);

-- Create Profiles table
create table public.profiles (
  id uuid not null default gen_random_uuid(),
  username text not null,
  phone_number text not null,
  height numeric null,
  weight numeric null,
  arm_circumference numeric null,
  chest_circumference numeric null,
  waist_circumference numeric null,
  hip_circumference numeric null,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint profiles_pkey primary key (id),
  constraint profiles_username_key unique (username)
);

-- Create Weight Records table
create table public.weight_records (
  id uuid not null default gen_random_uuid(),
  profile_id uuid null,
  weight numeric not null,
  recorded_at timestamp with time zone not null default timezone('utc'::text, now()),
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint weight_records_pkey primary key (id)
);

-- Create function for checking weight record frequency
CREATE OR REPLACE FUNCTION check_weight_record_frequency()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM weight_records
    WHERE profile_id = NEW.profile_id
    AND recorded_at::date = NEW.recorded_at::date
  ) THEN
    RAISE EXCEPTION 'Only one weight record per day is allowed';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for weight record frequency check
CREATE TRIGGER check_weight_record_frequency_trigger
BEFORE INSERT ON weight_records
FOR EACH ROW
EXECUTE FUNCTION check_weight_record_frequency(); 