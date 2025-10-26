-- تست کامل سیستم مدارک
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. بررسی ساختار جدول certificates
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'certificates' 
ORDER BY ordinal_position;

-- 2. بررسی RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- 3. بررسی bucket
SELECT name, public, created_at FROM storage.buckets WHERE name = 'coach_certificates';

-- 4. تست insert مدرک (اختیاری)
-- INSERT INTO certificates (trainer_id, title, type, status, description, created_at, updated_at)
-- VALUES (
--   '8f99d6ce-e2cb-4c9d-948d-787d340fb95c',
--   'گواهینامه مربیگری بدنسازی',
--   'coaching',
--   'pending',
--   'گواهینامه مربیگری بدنسازی از فدراسیون',
--   NOW(),
--   NOW()
-- );

-- 5. بررسی مدارک موجود
SELECT id, title, type, status, created_at 
FROM certificates 
ORDER BY created_at DESC 
LIMIT 5;
