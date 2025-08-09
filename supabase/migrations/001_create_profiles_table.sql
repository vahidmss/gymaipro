-- Create user_role enum
CREATE TYPE public.user_role AS ENUM ('athlete', 'trainer', 'admin');

-- Create profiles table
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  username text NOT NULL,
  phone_number text NOT NULL,
  email text NULL,
  first_name text NULL,
  last_name text NULL,
  avatar_url text NULL,
  bio text NULL,
  birth_date date NULL,
  height numeric NULL,
  weight numeric NULL,
  arm_circumference numeric NULL,
  chest_circumference numeric NULL,
  waist_circumference numeric NULL,
  hip_circumference numeric NULL,
  experience_level text NULL,
  preferred_training_days text[] NULL,
  preferred_training_time text NULL,
  fitness_goals text[] NULL,
  medical_conditions text[] NULL,
  dietary_preferences text[] NULL,
  weight_history jsonb NULL DEFAULT '[]'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  gender text NULL DEFAULT 'male'::text,
  role public.user_role NOT NULL DEFAULT 'athlete'::user_role,
  
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_username_key UNIQUE (username),
  CONSTRAINT profiles_phone_number_key UNIQUE (phone_number),
  CONSTRAINT profiles_email_key UNIQUE (email),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users (id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles USING btree (role);
CREATE INDEX IF NOT EXISTS idx_profiles_phone_number ON public.profiles USING btree (phone_number);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles USING btree (email);

-- Create RLS policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Trainers can view athlete profiles (for client management)
CREATE POLICY "Trainers can view athlete profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles trainer_profile 
      WHERE trainer_profile.id = auth.uid() 
      AND trainer_profile.role = 'trainer'
    )
    AND role = 'athlete'
  );

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles admin_profile 
      WHERE admin_profile.id = auth.uid() 
      AND admin_profile.role = 'admin'
    )
  );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER handle_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at(); 