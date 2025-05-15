-- Enable RLS for all relevant tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weight_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sets ENABLE ROW LEVEL SECURITY;

-- Force RLS for table owners (important for security)
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE public.otp_codes FORCE ROW LEVEL SECURITY;
ALTER TABLE public.weight_records FORCE ROW LEVEL SECURITY;
ALTER TABLE public.exercises FORCE ROW LEVEL SECURITY;
ALTER TABLE public.workouts FORCE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises FORCE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs FORCE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sets FORCE ROW LEVEL SECURITY;

-- Policies for profiles table
DROP POLICY IF EXISTS "Allow individual read access to own profile" ON public.profiles;
CREATE POLICY "Allow individual read access to own profile" ON public.profiles
FOR SELECT
USING (auth.uid() = id); -- Profiles.id is now auth.user.id

DROP POLICY IF EXISTS "Allow individual update access to own profile" ON public.profiles;
CREATE POLICY "Allow individual update access to own profile" ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Allow individual insert for own profile" ON public.profiles;
CREATE POLICY "Allow individual insert for own profile" ON public.profiles
FOR INSERT
WITH CHECK (auth.uid() = id); -- Profile is created with user's own id

DROP POLICY IF EXISTS "Allow anon select for username check" ON public.profiles;
CREATE POLICY "Allow anon select for username/phone check" ON public.profiles
FOR SELECT TO anon
USING (true); -- Allows checking username/phone_number for uniqueness during registration

-- Policies for otp_codes table
DROP POLICY IF EXISTS "Allow insert access for OTP codes" ON public.otp_codes;
CREATE POLICY "Allow anon/auth insert access for OTP codes" ON public.otp_codes
FOR INSERT TO anon, authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow read access for OTP verification" ON public.otp_codes;
CREATE POLICY "Allow anon/auth read access for OTP verification" ON public.otp_codes
FOR SELECT TO anon, authenticated
USING (true); -- Verification happens with phone_number and code, RLS checks if row exists

DROP POLICY IF EXISTS "Allow update access for OTP codes" ON public.otp_codes;
CREATE POLICY "Allow anon/auth update access for OTP codes" ON public.otp_codes -- e.g., to mark as used
FOR UPDATE TO anon, authenticated
USING (true);

-- Policies for weight_records table
DROP POLICY IF EXISTS "Allow individual read access to own weight_records" ON public.weight_records;
CREATE POLICY "Allow individual read access to own weight_records" ON public.weight_records
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow individual insert access to weight_records" ON public.weight_records;
CREATE POLICY "Allow individual insert access to weight_records" ON public.weight_records
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow individual update access to own weight_records" ON public.weight_records;
CREATE POLICY "Allow individual update access to own weight_records" ON public.weight_records
FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow individual delete access to own weight_records" ON public.weight_records;
CREATE POLICY "Allow individual delete access to own weight_records" ON public.weight_records
FOR DELETE USING (auth.uid() = user_id);

-- Policies for exercises table
CREATE POLICY "Allow read access for all users to exercises" ON public.exercises
FOR SELECT TO anon, authenticated
USING (true);
-- CUD operations on exercises typically done by admin/service_role, not directly by users via RLS.

-- Policies for workouts table
CREATE POLICY "Allow users to manage their own workouts" ON public.workouts
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Policies for workout_exercises (Join Table)
CREATE POLICY "Allow users to manage exercises within their own workouts" ON public.workout_exercises
FOR ALL -- SELECT, INSERT, DELETE (UPDATE might not be common for join table entries)
USING (EXISTS (SELECT 1 FROM public.workouts WHERE public.workouts.id = workout_id AND public.workouts.user_id = auth.uid()))
WITH CHECK (EXISTS (SELECT 1 FROM public.workouts WHERE public.workouts.id = workout_id AND public.workouts.user_id = auth.uid()));

-- Policies for workout_logs table
CREATE POLICY "Allow users to manage their own workout logs" ON public.workout_logs
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Policies for workout_sets table
CREATE POLICY "Allow users to manage sets within their own workout logs" ON public.workout_sets
FOR ALL
USING (EXISTS (SELECT 1 FROM public.workout_logs WHERE public.workout_logs.id = log_id AND public.workout_logs.user_id = auth.uid()))
WITH CHECK (EXISTS (SELECT 1 FROM public.workout_logs WHERE public.workout_logs.id = log_id AND public.workout_logs.user_id = auth.uid()));

-- Note: The initial GRANTS in 00000000000000_setup_local_db.sql provide broad table-level permissions.
-- RLS policies then refine these permissions on a row-by-row basis for roles like 'authenticated' and 'anon'.
-- The 'postgres' user (superuser) bypasses RLS by default. 