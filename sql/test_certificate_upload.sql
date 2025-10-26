-- تست آپلود مدرک
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. بررسی جدول certificates
SELECT * FROM certificates ORDER BY created_at DESC LIMIT 5;

-- 2. بررسی storage objects
SELECT bucket_id, name, created_at, metadata->>'size' as file_size
FROM storage.objects 
WHERE bucket_id = 'coach_certificates' 
ORDER BY created_at DESC 
LIMIT 5;

-- 3. بررسی RLS policies
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- 4. تست insert مدرک (اختیاری)
-- INSERT INTO certificates (trainer_id, title, type, status, description, created_at, updated_at)
-- VALUES (
--   '8f99d6ce-e2cb-4c9d-948d-787d340fb95c',
--   'تست مدرک',
--   'coaching',
--   'pending',
--   'تست',
--   NOW(),
--   NOW()
-- );
