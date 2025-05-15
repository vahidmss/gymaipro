-- =====================
-- FULL DATABASE RESET
-- =====================

-- 1. DROP POLICIES (if exist)
DROP POLICY IF EXISTS "Allow individual read access to own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow individual update access to own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow individual insert for own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow anon select for username/phone check" ON public.profiles;

DROP POLICY IF EXISTS "Allow anon/auth insert access for OTP codes" ON public.otp_codes;
DROP POLICY IF EXISTS "Allow anon/auth read access for OTP verification" ON public.otp_codes;
DROP POLICY IF EXISTS "Allow anon/auth update access for OTP codes" ON public.otp_codes;

DROP POLICY IF EXISTS "Allow individual read access to own weight_records" ON public.weight_records;
DROP POLICY IF EXISTS "Allow individual insert access to weight_records" ON public.weight_records;
DROP POLICY IF EXISTS "Allow individual update access to own weight_records" ON public.weight_records;
DROP POLICY IF EXISTS "Allow individual delete access to own weight_records" ON public.weight_records;

DROP POLICY IF EXISTS "Allow read access for all users to exercises" ON public.exercises;
DROP POLICY IF EXISTS "Allow users to manage their own workouts" ON public.workouts;
DROP POLICY IF EXISTS "Allow users to manage exercises within their own workouts" ON public.workout_exercises;
DROP POLICY IF EXISTS "Allow users to manage their own workout logs" ON public.workout_logs;
DROP POLICY IF EXISTS "Allow users to manage sets within their own workout logs" ON public.workout_sets;

-- 2. DROP TRIGGERS
DROP TRIGGER IF EXISTS handle_updated_at_profiles ON public.profiles;
DROP TRIGGER IF EXISTS handle_updated_at_weight_records ON public.weight_records;
DROP TRIGGER IF EXISTS handle_updated_at_exercises ON public.exercises;
DROP TRIGGER IF EXISTS handle_updated_at_workouts ON public.workouts;
DROP TRIGGER IF EXISTS handle_updated_at_workout_logs ON public.workout_logs;
DROP TRIGGER IF EXISTS handle_updated_at_workout_sets ON public.workout_sets;

-- 3. DROP TABLES (CASCADE for dependencies)
DROP TABLE IF EXISTS public.workout_sets CASCADE;
DROP TABLE IF EXISTS public.workout_logs CASCADE;
DROP TABLE IF EXISTS public.workout_exercises CASCADE;
DROP TABLE IF EXISTS public.workouts CASCADE;
DROP TABLE IF EXISTS public.exercises CASCADE;
DROP TABLE IF EXISTS public.weight_records CASCADE;
DROP TABLE IF EXISTS public.otp_codes CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 4. DROP FUNCTIONS
DROP FUNCTION IF EXISTS public.update_updated_at_column CASCADE;
DROP FUNCTION IF EXISTS public.get_all_profiles CASCADE;
DROP FUNCTION IF EXISTS public.check_user_exists(TEXT) CASCADE;

-- 5. RECREATE EVERYTHING (copy from latest setup_local_db.sql and setup_rls.sql)

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Function to update the updated_at column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    phone_number TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE,
    first_name TEXT,
    last_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    birth_date DATE,
    height NUMERIC,
    weight NUMERIC,
    arm_circumference NUMERIC,
    chest_circumference NUMERIC,
    waist_circumference NUMERIC,
    hip_circumference NUMERIC,
    experience_level TEXT,
    preferred_training_days TEXT[],
    preferred_training_time TEXT,
    fitness_goals TEXT[],
    medical_conditions TEXT[],
    dietary_preferences TEXT[],
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TRIGGER handle_updated_at_profiles
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- OTP Codes Table
CREATE TABLE IF NOT EXISTS public.otp_codes (
    id BIGSERIAL PRIMARY KEY,
    phone_number TEXT NOT NULL,
    code TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_used BOOLEAN DEFAULT false NOT NULL,
    used_at TIMESTAMPTZ
);

-- Weight Records Table
CREATE TABLE IF NOT EXISTS public.weight_records (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    weight NUMERIC NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TRIGGER handle_updated_at_weight_records
BEFORE UPDATE ON public.weight_records
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Exercises Table
CREATE TABLE IF NOT EXISTS public.exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    muscle_group TEXT,
    equipment TEXT,
    difficulty TEXT,
    instructions TEXT[],
    tips TEXT[],
    image_urls TEXT[],
    video_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TRIGGER handle_updated_at_exercises
BEFORE UPDATE ON public.exercises
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Workouts Table
CREATE TABLE IF NOT EXISTS public.workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TRIGGER handle_updated_at_workouts
BEFORE UPDATE ON public.workouts
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Workout Exercises (Join Table)
CREATE TABLE IF NOT EXISTS public.workout_exercises (
    id BIGSERIAL PRIMARY KEY,
    workout_id UUID NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE (workout_id, exercise_id)
);

-- Workout Logs Table
CREATE TABLE IF NOT EXISTS public.workout_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_id UUID NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TRIGGER handle_updated_at_workout_logs
BEFORE UPDATE ON public.workout_logs
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Workout Sets Table
CREATE TABLE IF NOT EXISTS public.workout_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    log_id UUID NOT NULL REFERENCES public.workout_logs(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
    reps INTEGER NOT NULL,
    weight NUMERIC NOT NULL,
    rest_seconds INTEGER,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TRIGGER handle_updated_at_workout_sets
BEFORE UPDATE ON public.workout_sets
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Grant usage on schema public to postgres and anon, authenticated
GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant all privileges on all tables in schema public to postgres
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO postgres;

-- Grant necessary permissions for anon and authenticated roles
GRANT SELECT ON TABLE public.profiles TO anon;
GRANT INSERT ON TABLE public.profiles TO authenticated;
GRANT SELECT, UPDATE ON TABLE public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.otp_codes TO anon;
GRANT SELECT, INSERT, UPDATE ON TABLE public.otp_codes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.weight_records TO authenticated;
GRANT SELECT ON TABLE public.exercises TO anon;
GRANT SELECT ON TABLE public.exercises TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.workouts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.workout_exercises TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.workout_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.workout_sets TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Create a function to get all profiles
CREATE OR REPLACE FUNCTION public.get_all_profiles()
RETURNS SETOF public.profiles AS $$
BEGIN
    RETURN QUERY SELECT * FROM public.profiles;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check user existence
CREATE OR REPLACE FUNCTION public.check_user_exists(phone TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.profiles WHERE phone_number = phone
    ) INTO exists;
    RETURN exists;
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION public.check_user_exists(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.check_user_exists(TEXT) TO authenticated;

-- =====================
-- RLS POLICIES
-- =====================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weight_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sets ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE public.otp_codes FORCE ROW LEVEL SECURITY;
ALTER TABLE public.weight_records FORCE ROW LEVEL SECURITY;
ALTER TABLE public.exercises FORCE ROW LEVEL SECURITY;
ALTER TABLE public.workouts FORCE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises FORCE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs FORCE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sets FORCE ROW LEVEL SECURITY;

CREATE POLICY "Allow individual read access to own profile" ON public.profiles
FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Allow individual update access to own profile" ON public.profiles
FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "Allow individual insert for own profile" ON public.profiles
FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Allow anon select for username/phone check" ON public.profiles
FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anon/auth insert access for OTP codes" ON public.otp_codes
FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow anon/auth read access for OTP verification" ON public.otp_codes
FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow anon/auth update access for OTP codes" ON public.otp_codes
FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Allow individual read access to own weight_records" ON public.weight_records
FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow individual insert access to weight_records" ON public.weight_records
FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Allow individual update access to own weight_records" ON public.weight_records
FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Allow individual delete access to own weight_records" ON public.weight_records
FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Allow read access for all users to exercises" ON public.exercises
FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow users to manage their own workouts" ON public.workouts
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Allow users to manage exercises within their own workouts" ON public.workout_exercises
FOR ALL USING (EXISTS (SELECT 1 FROM public.workouts WHERE public.workouts.id = workout_id AND public.workouts.user_id = auth.uid()))
WITH CHECK (EXISTS (SELECT 1 FROM public.workouts WHERE public.workouts.id = workout_id AND public.workouts.user_id = auth.uid()));
CREATE POLICY "Allow users to manage their own workout logs" ON public.workout_logs
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Allow users to manage sets within their own workout logs" ON public.workout_sets
FOR ALL USING (EXISTS (SELECT 1 FROM public.workout_logs WHERE public.workout_logs.id = log_id AND public.workout_logs.user_id = auth.uid()))
WITH CHECK (EXISTS (SELECT 1 FROM public.workout_logs WHERE public.workout_logs.id = log_id AND public.workout_logs.user_id = auth.uid())); 