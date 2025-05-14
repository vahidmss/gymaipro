-- Enable RLS on tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weight_records ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
CREATE POLICY "Enable read access for authenticated users" ON public.profiles
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Enable insert for authenticated users" ON public.profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Enable update for own profile" ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Create policies for otp_codes
CREATE POLICY "Enable all access for authenticated users" ON public.otp_codes
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Create policies for weight_records
CREATE POLICY "Enable read access for own records" ON public.weight_records
    FOR SELECT
    TO authenticated
    USING (profile_id = auth.uid());

CREATE POLICY "Enable insert for own records" ON public.weight_records
    FOR INSERT
    TO authenticated
    WITH CHECK (profile_id = auth.uid());

-- Grant necessary privileges
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres; 