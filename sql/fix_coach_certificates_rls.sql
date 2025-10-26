-- اصلاح RLS Policy برای bucket coach_certificates
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. حذف Policy قدیمی
DROP POLICY IF EXISTS "Trainers can upload certificates" ON storage.objects;

-- 2. ایجاد Policy جدید با بررسی مسیر فایل
CREATE POLICY "Trainers can upload certificates" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'coach_certificates' AND
  auth.uid() IS NOT NULL AND
  (storage.foldername(name))[1] = auth.uid()::text AND
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'trainer'
  )
);

-- 3. بررسی Policy های موجود
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' AND policyname LIKE '%certificates%';

-- 4. تست Policy (اختیاری)
-- این query را اجرا کنید تا ببینید آیا Policy درست کار می‌کند
SELECT 
  auth.uid() as current_user_id,
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'trainer'
  ) as is_trainer;
