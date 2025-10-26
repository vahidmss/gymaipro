-- بررسی وجود bucket coach_certificates
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. بررسی buckets موجود
SELECT name, public, created_at, updated_at 
FROM storage.buckets 
ORDER BY created_at DESC;

-- 2. بررسی bucket coach_certificates
SELECT name, public, created_at, updated_at 
FROM storage.buckets 
WHERE name = 'coach_certificates';

-- 3. اگر bucket وجود ندارد، آن را ایجاد کنید
-- INSERT INTO storage.buckets (id, name, public, created_at, updated_at)
-- VALUES (
--   'coach_certificates',
--   'coach_certificates', 
--   true,
--   NOW(),
--   NOW()
-- );

-- 4. بررسی RLS policies برای storage.objects
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage' 
AND policyname LIKE '%certificate%';
