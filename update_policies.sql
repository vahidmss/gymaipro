-- Drop existing policies
DROP POLICY IF EXISTS "Enable read access for all" ON public.profiles;
DROP POLICY IF EXISTS "Enable insert for all" ON public.profiles;
DROP POLICY IF EXISTS "Enable update for own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable all for otp_codes" ON public.otp_codes;
DROP POLICY IF EXISTS "Enable all for weight_records" ON public.weight_records;

-- Create new policies with more permissive settings
CREATE POLICY "Enable all operations" ON public.profiles
    FOR ALL
    TO PUBLIC
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Enable all operations" ON public.otp_codes
    FOR ALL
    TO PUBLIC
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Enable all operations" ON public.weight_records
    FOR ALL
    TO PUBLIC
    USING (true)
    WITH CHECK (true);

-- Disable RLS temporarily for testing
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.weight_records DISABLE ROW LEVEL SECURITY; 