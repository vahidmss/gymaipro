-- Create clean bucket for confidential user photos
-- Run this in Supabase SQL Editor

-- 1. Delete existing bucket if exists (be careful!)
DELETE FROM storage.buckets WHERE id = 'secret_user_image';
DELETE FROM storage.buckets WHERE id = 'confidential_photos';

-- 2. Create new bucket for confidential photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'confidential_photos',
  'confidential_photos', 
  true, -- PUBLIC bucket for easier access
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
);

-- 3. Create simple RLS policies for authenticated users
CREATE POLICY "Allow authenticated users to upload confidential photos" 
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'confidential_photos');

CREATE POLICY "Allow authenticated users to view confidential photos" 
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'confidential_photos');

CREATE POLICY "Allow authenticated users to update confidential photos" 
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'confidential_photos')
WITH CHECK (bucket_id = 'confidential_photos');

CREATE POLICY "Allow authenticated users to delete confidential photos" 
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'confidential_photos');
