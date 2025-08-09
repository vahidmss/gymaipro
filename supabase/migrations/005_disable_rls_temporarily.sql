-- Temporarily disable RLS on profiles table to fix infinite recursion
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies to prevent conflicts
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Trainers can view athlete profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow username validation" ON public.profiles;
DROP POLICY IF EXISTS "Allow phone validation" ON public.profiles;

-- Create a simple policy that allows all operations for now
CREATE POLICY "Allow all operations temporarily" ON public.profiles
  FOR ALL USING (true)
  WITH CHECK (true);

-- Re-enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY; 