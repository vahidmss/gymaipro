-- Make secret_user_image bucket public to avoid RLS issues
-- Run this in Supabase SQL Editor

-- Update bucket to be public
UPDATE storage.buckets 
SET public = true 
WHERE id = 'secret_user_image';

-- If bucket doesn't exist, create it as public
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'secret_user_image',
  'secret_user_image', 
  true, -- PUBLIC bucket
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO UPDATE SET public = true;
