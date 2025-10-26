-- تنظیمات ساده برای bucket coach_certificates
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. بررسی وجود bucket
SELECT name, public FROM storage.buckets WHERE name = 'coach_certificates';

-- 2. بررسی RLS policies موجود
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' AND policyname LIKE '%certificates%';

-- 3. بررسی نقش کاربر فعلی
SELECT 
  auth.uid() as current_user_id,
  p.role,
  p.username
FROM public.profiles p 
WHERE p.id = auth.uid();

-- 4. تست دسترسی storage
SELECT 
  bucket_id,
  name,
  created_at
FROM storage.objects 
WHERE bucket_id = 'coach_certificates' 
LIMIT 5;
