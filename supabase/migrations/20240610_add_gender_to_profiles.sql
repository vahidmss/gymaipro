-- Add gender column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT 'male';

-- Ensure proper comments are added for documentation
COMMENT ON COLUMN public.profiles.gender IS 'User gender (male/female)';

-- Update any functions that return profile data to include the new column
CREATE OR REPLACE FUNCTION public.get_all_profiles()
RETURNS SETOF public.profiles AS $$
BEGIN
    RETURN QUERY SELECT * FROM public.profiles;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 