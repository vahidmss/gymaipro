-- Create an enum type for user roles
CREATE TYPE user_role AS ENUM ('athlete', 'trainer', 'admin');

-- Add role column to profiles table with default value 'athlete'
ALTER TABLE public.profiles 
ADD COLUMN role user_role NOT NULL DEFAULT 'athlete';

-- Add an index on the role column for faster queries
CREATE INDEX idx_profiles_role ON public.profiles(role);

-- Update RLS policies to include role-based access
-- Trainers can view profiles of their clients (to be implemented)
-- Admins can view all profiles

-- Basic policy to allow users to see other users who are trainers
DROP POLICY IF EXISTS "Users can view trainers" ON public.profiles;
CREATE POLICY "Users can view trainers" 
ON public.profiles 
FOR SELECT 
USING (auth.uid() = id OR role = 'trainer');

-- Create a table for trainer-client relationships
CREATE TABLE IF NOT EXISTS public.trainer_clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trainer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, active, rejected, ended
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(trainer_id, client_id)
);

-- Create a trigger for updated_at
DROP TRIGGER IF EXISTS handle_updated_at_trainer_clients ON public.trainer_clients;
CREATE TRIGGER handle_updated_at_trainer_clients
BEFORE UPDATE ON public.trainer_clients
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- RLS for trainer_clients
ALTER TABLE public.trainer_clients ENABLE ROW LEVEL SECURITY;

-- Policy for inserting: clients can request trainers, trainers can add clients
CREATE POLICY "Users can request trainers or add clients"
ON public.trainer_clients FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = trainer_id OR auth.uid() = client_id);

-- Policy for viewing: users can see relationships they are part of
CREATE POLICY "Users can view their own relationships"
ON public.trainer_clients FOR SELECT
TO authenticated
USING (auth.uid() = trainer_id OR auth.uid() = client_id);

-- Policy for updating: only the trainer can update the relationship status
CREATE POLICY "Trainers can update relationship status"
ON public.trainer_clients FOR UPDATE
TO authenticated
USING (auth.uid() = trainer_id)
WITH CHECK (auth.uid() = trainer_id);

-- Policy for deletion: both parties can end the relationship
CREATE POLICY "Both parties can end the relationship"
ON public.trainer_clients FOR DELETE
TO authenticated
USING (auth.uid() = trainer_id OR auth.uid() = client_id);

-- Create a table for trainer details
CREATE TABLE IF NOT EXISTS public.trainer_details (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    specialties TEXT[],
    experience_years INT,
    certifications TEXT[],
    education TEXT,
    hourly_rate NUMERIC,
    availability JSON, -- Store availability as JSON
    bio_extended TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create a trigger for updated_at
DROP TRIGGER IF EXISTS handle_updated_at_trainer_details ON public.trainer_details;
CREATE TRIGGER handle_updated_at_trainer_details
BEFORE UPDATE ON public.trainer_details
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- RLS for trainer_details
ALTER TABLE public.trainer_details ENABLE ROW LEVEL SECURITY;

-- Policy for inserting: only the trainer can create their details
CREATE POLICY "Trainers can create their own details"
ON public.trainer_details FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Policy for viewing: anyone can view trainer details
CREATE POLICY "Anyone can view trainer details"
ON public.trainer_details FOR SELECT
TO authenticated
USING (true);

-- Policy for updating: only the trainer can update their details
CREATE POLICY "Trainers can update their own details"
ON public.trainer_details FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy for deletion: only the trainer can delete their details
CREATE POLICY "Trainers can delete their own details"
ON public.trainer_details FOR DELETE
TO authenticated
USING (auth.uid() = id);

-- Create a table for trainer ratings and reviews
CREATE TABLE IF NOT EXISTS public.trainer_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trainer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(trainer_id, client_id)
);

-- Create a trigger for updated_at
DROP TRIGGER IF EXISTS handle_updated_at_trainer_reviews ON public.trainer_reviews;
CREATE TRIGGER handle_updated_at_trainer_reviews
BEFORE UPDATE ON public.trainer_reviews
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- RLS for trainer_reviews
ALTER TABLE public.trainer_reviews ENABLE ROW LEVEL SECURITY;

-- Policy for inserting: only clients can review their trainers
CREATE POLICY "Clients can review their trainers"
ON public.trainer_reviews FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = client_id AND 
       EXISTS (SELECT 1 FROM public.trainer_clients 
               WHERE trainer_id = trainer_reviews.trainer_id 
               AND client_id = trainer_reviews.client_id
               AND status = 'active'));

-- Policy for viewing: anyone can view trainer reviews
CREATE POLICY "Anyone can view trainer reviews"
ON public.trainer_reviews FOR SELECT
TO authenticated
USING (true);

-- Policy for updating: clients can update their own reviews
CREATE POLICY "Clients can update their own reviews"
ON public.trainer_reviews FOR UPDATE
TO authenticated
USING (auth.uid() = client_id)
WITH CHECK (auth.uid() = client_id);

-- Policy for deletion: clients can delete their own reviews
CREATE POLICY "Clients can delete their own reviews"
ON public.trainer_reviews FOR DELETE
TO authenticated
USING (auth.uid() = client_id); 