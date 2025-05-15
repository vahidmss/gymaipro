-- Ensure the profiles table exists (basic structure)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number TEXT UNIQUE,
    username TEXT UNIQUE, -- If you still plan to use username
    email TEXT UNIQUE,    -- For linking with auth.users.email and for getProfileByEmail
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add columns based on UserProfile model if they don't exist
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS birth_date DATE; -- Using DATE type, adjust if you need TIMESTAMP
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS height NUMERIC;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS weight NUMERIC;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS arm_circumference NUMERIC;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS chest_circumference NUMERIC;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS waist_circumference NUMERIC;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS hip_circumference NUMERIC;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS experience_level TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS preferred_training_days TEXT[]; -- Array of text
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS preferred_training_time TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fitness_goals TEXT[]; -- Array of text
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS medical_conditions TEXT[]; -- Array of text
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS dietary_preferences TEXT[]; -- Array of text

-- Trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_profiles_updated ON public.profiles;
CREATE TRIGGER on_profiles_updated
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- RLS policies (examples - adjust as needed)
-- Ensure RLS is enabled on the table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own profile
DROP POLICY IF EXISTS "Allow individual read access" ON profiles;
CREATE POLICY "Allow individual read access"
ON profiles
FOR SELECT
USING (auth.uid() = id);

-- Policy: Users can update their own profile
DROP POLICY IF EXISTS "Allow individual update access" ON profiles;
CREATE POLICY "Allow individual update access"
ON profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy: Allow new users to insert their own profile (linked to their auth.uid)
-- This assumes 'id' is being set to auth.uid() by the application during insert
DROP POLICY IF EXISTS "Allow individual insert access" ON profiles;
CREATE POLICY "Allow individual insert access"
ON profiles
FOR INSERT
WITH CHECK (auth.uid() = id);

-- Grant usage on schema and all privileges on table to supabase_admin and authenticated roles
-- This might be too permissive for 'authenticated', tailor as needed.
-- Usually, specific operations are granted via policies.
GRANT USAGE ON SCHEMA public TO supabase_admin, authenticated, service_role;
GRANT ALL ON TABLE public.profiles TO supabase_admin, service_role;
-- For authenticated users, rely on RLS policies for SELECT, INSERT, UPDATE, DELETE.
-- If you need specific grants beyond what RLS allows (e.g. for functions), add them here.
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.profiles TO authenticated;


-- For weight_records table
CREATE TABLE IF NOT EXISTS weight_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    weight NUMERIC NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Trigger for updated_at on weight_records
DROP TRIGGER IF EXISTS on_weight_records_updated ON public.weight_records;
CREATE TRIGGER on_weight_records_updated
BEFORE UPDATE ON public.weight_records
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- RLS for weight_records
ALTER TABLE weight_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow individual access to own weight records" ON weight_records;
CREATE POLICY "Allow individual access to own weight records"
ON weight_records
FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = weight_records.profile_id AND profiles.id = auth.uid()))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = weight_records.profile_id AND profiles.id = auth.uid()));

GRANT ALL ON TABLE public.weight_records TO supabase_admin, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.weight_records TO authenticated; 