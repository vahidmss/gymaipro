-- Simple Storage setup for confidential user images
-- Run this in Supabase SQL Editor

-- 1. Create a PUBLIC bucket for easier access
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'secret_user_image',
  'secret_user_image', 
  true, -- PUBLIC bucket for easier access
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;
