-- تست کامل آپلود مدرک
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. بررسی وجود bucket
SELECT name, public, created_at, updated_at 
FROM storage.buckets 
WHERE name = 'coach_certificates';

-- 2. اگر bucket وجود ندارد، آن را ایجاد کنید
INSERT INTO storage.buckets (id, name, public, created_at, updated_at)
VALUES (
  'coach_certificates',
  'coach_certificates', 
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO NOTHING;

-- 3. بررسی ساختار جدول certificates
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'certificates' 
ORDER BY ordinal_position;

-- 4. بررسی RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage' 
AND policyname LIKE '%certificate%';

-- 5. بررسی کاربر فعلی
SELECT 
  auth.uid() as current_user_id,
  p.username,
  p.role
FROM public.profiles p 
WHERE p.id = auth.uid();

-- 6. تست insert مدرک (اختیاری)
-- INSERT INTO certificates (trainer_id, title, type, status, description, created_at, updated_at)
-- VALUES (
--   '8f99d6ce-e2cb-4c9d-948d-787d340fb95c',
--   'تست مدرک',
--   'coaching',
--   'pending',
--   'تست آپلود مدرک',
--   NOW(),
--   NOW()
-- );

-- 7. بررسی مدارک موجود
SELECT id, title, type, status, created_at 
FROM certificates 
ORDER BY created_at DESC 
LIMIT 5;
