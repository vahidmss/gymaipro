-- Create profiles table
CREATE TABLE profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    phone_number TEXT NOT NULL,
    height DECIMAL,
    weight DECIMAL,
    arm_circumference DECIMAL,
    chest_circumference DECIMAL,
    waist_circumference DECIMAL,
    hip_circumference DECIMAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create weight_records table
CREATE TABLE weight_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    weight DECIMAL NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create RLS policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_records ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Weight records policies
CREATE POLICY "Users can view their own weight records"
    ON weight_records FOR SELECT
    USING (auth.uid() = profile_id);

CREATE POLICY "Users can insert their own weight records"
    ON weight_records FOR INSERT
    WITH CHECK (auth.uid() = profile_id);

-- Create function to check weight record frequency
CREATE OR REPLACE FUNCTION check_weight_record_frequency()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM weight_records
        WHERE profile_id = NEW.profile_id
        AND recorded_at > NOW() - INTERVAL '7 days'
    ) THEN
        RAISE EXCEPTION 'Weight can only be recorded once every 7 days';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for weight record frequency
CREATE TRIGGER check_weight_record_frequency_trigger
    BEFORE INSERT ON weight_records
    FOR EACH ROW
    EXECUTE FUNCTION check_weight_record_frequency(); 