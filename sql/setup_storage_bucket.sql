-- Setup Storage bucket for confidential user images
-- Run this in Supabase SQL Editor

-- 1. Create the storage bucket (if not exists)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'secret_user_image',
  'secret_user_image', 
  false, -- Private bucket for security
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- 2. Create policy for authenticated users to upload their own images
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Users can upload their own confidential images'
  ) THEN
    CREATE POLICY "Users can upload their own confidential images" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
      bucket_id = 'secret_user_image' 
      AND auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;
END $$;

-- 3. Create policy for users to view their own images
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Users can view their own confidential images'
  ) THEN
    CREATE POLICY "Users can view their own confidential images" ON storage.objects
    FOR SELECT TO authenticated
    USING (
      bucket_id = 'secret_user_image' 
      AND auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;
END $$;

-- 4. Create policy for users to update their own images
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Users can update their own confidential images'
  ) THEN
    CREATE POLICY "Users can update their own confidential images" ON storage.objects
    FOR UPDATE TO authenticated
    USING (
      bucket_id = 'secret_user_image' 
      AND auth.uid()::text = (storage.foldername(name))[1]
    )
    WITH CHECK (
      bucket_id = 'secret_user_image' 
      AND auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;
END $$;

-- 5. Create policy for users to delete their own images
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Users can delete their own confidential images'
  ) THEN
    CREATE POLICY "Users can delete their own confidential images" ON storage.objects
    FOR DELETE TO authenticated
    USING (
      bucket_id = 'secret_user_image' 
      AND auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;
END $$;
