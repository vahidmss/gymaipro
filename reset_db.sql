-- Drop existing tables and functions
DROP TABLE IF EXISTS public.weight_records;
DROP TABLE IF EXISTS public.otp_codes;
DROP TABLE IF EXISTS public.profiles;
DROP FUNCTION IF EXISTS check_weight_record_frequency();

-- Create tables and functions again
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

create table public.otp_codes (
  id uuid not null default gen_random_uuid(),
  phone_number text not null,
  code text not null,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  expires_at timestamp with time zone not null,
  is_used boolean null default false,
  used_at timestamp with time zone null
);

create table public.weight_records (
  id uuid not null default gen_random_uuid(),
  profile_id uuid null references public.profiles(id),
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

-- Create trigger
CREATE TRIGGER check_weight_record_frequency_trigger
BEFORE INSERT ON weight_records
FOR EACH ROW
EXECUTE FUNCTION check_weight_record_frequency();

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weight_records ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Enable read access for all" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Enable insert for all" ON public.profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for own profile" ON public.profiles FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Enable all for otp_codes" ON public.otp_codes FOR ALL USING (true);

CREATE POLICY "Enable all for weight_records" ON public.weight_records FOR ALL USING (true);

-- Grant privileges
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres; 