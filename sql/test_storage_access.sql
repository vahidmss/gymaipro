-- تست دسترسی به storage
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. بررسی bucket
SELECT name, public, created_at FROM storage.buckets WHERE name = 'coach_certificates';

-- 2. بررسی کاربر فعلی
SELECT 
  auth.uid() as user_id,
  p.username,
  p.role
FROM public.profiles p 
WHERE p.id = auth.uid();

-- 3. بررسی RLS
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- 4. بررسی policies
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- 5. تست آپلود (اختیاری)
-- INSERT INTO storage.objects (bucket_id, name, owner, metadata)
-- VALUES ('coach_certificates', 'test.txt', auth.uid(), '{"size": 0}');
