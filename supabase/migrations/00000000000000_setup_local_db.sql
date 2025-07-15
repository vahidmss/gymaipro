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

-- Trigger for profiles updated_at
DROP TRIGGER IF EXISTS handle_updated_at_profiles ON public.profiles;
CREATE TRIGGER handle_updated_at_profiles
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- OTP Codes Table
CREATE TABLE IF NOT EXISTS public.otp_codes (
    id BIGSERIAL PRIMARY KEY,
    phone_number TEXT NOT NULL,
    code TEXT NOT NULL, -- Renamed from otp_code to code to match OTPService
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_used BOOLEAN DEFAULT false NOT NULL, -- Renamed from is_verified and added used_at
    used_at TIMESTAMPTZ
);

-- Weight Records Table
CREATE TABLE IF NOT EXISTS public.weight_records (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE, -- This should reference profiles.id which is auth.users.id
    weight NUMERIC NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Trigger for weight_records updated_at
DROP TRIGGER IF EXISTS handle_updated_at_weight_records ON public.weight_records;
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

-- Trigger for exercises updated_at
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

-- Trigger for workouts updated_at
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

-- Trigger for workout_logs updated_at
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

-- Trigger for workout_sets updated_at
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
-- Profiles
GRANT SELECT ON TABLE public.profiles TO anon; -- For username check, fetching public profiles if any
GRANT INSERT ON TABLE public.profiles TO authenticated; -- Users create their own profiles upon signup (linked to auth.users)
GRANT SELECT, UPDATE ON TABLE public.profiles TO authenticated; -- Users can read and update their own profiles (RLS handles specifics)
-- OTP Codes
GRANT SELECT, INSERT, UPDATE ON TABLE public.otp_codes TO anon; -- OTP operations often happen before full authentication
GRANT SELECT, INSERT, UPDATE ON TABLE public.otp_codes TO authenticated;
-- Weight Records
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.weight_records TO authenticated;
-- Exercises
GRANT SELECT ON TABLE public.exercises TO anon;
GRANT SELECT ON TABLE public.exercises TO authenticated;
-- Workouts
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.workouts TO authenticated;
-- Workout Exercises (Join Table)
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.workout_exercises TO authenticated;
-- Workout Logs
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.workout_logs TO authenticated;
-- Workout Sets
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.workout_sets TO authenticated;

-- Grant usage on sequences for authenticated users to be able to insert (and anon if they insert to OTP)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Create a function to get all profiles (for debugging or admin purposes if needed, secure with RLS on profiles table)
-- This was used in SupabaseService, ensure it's present or handle its absence.
CREATE OR REPLACE FUNCTION public.get_all_profiles()
RETURNS SETOF public.profiles AS $$
BEGIN
    RETURN QUERY SELECT * FROM public.profiles;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; -- SECURITY DEFINER might be needed if RLS on profiles restricts the calling role.
                                      -- Alternatively, ensure the calling role (e.g. service_role) has bypass RLS.
                                      -- For user calls, RLS on public.profiles will apply.

-- Function to check user existence (used in SupabaseService)
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

-- ALTER TABLE chat_rooms ALTER COLUMN created_by DROP NOT NULL; 