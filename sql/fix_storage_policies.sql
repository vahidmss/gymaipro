-- اصلاح RLS Policies برای storage.objects
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. حذف policies قدیمی (اگر وجود دارند)
DROP POLICY IF EXISTS "Trainers can upload certificates" ON storage.objects;
DROP POLICY IF EXISTS "Public can view certificates" ON storage.objects;
DROP POLICY IF EXISTS "Trainers can delete their certificates" ON storage.objects;
DROP POLICY IF EXISTS "Trainers can update their certificates" ON storage.objects;

-- 2. ایجاد policy ساده برای آپلود
CREATE POLICY "Allow certificate uploads" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'coach_certificates' AND
  auth.uid() IS NOT NULL
);

-- 3. ایجاد policy برای مشاهده
CREATE POLICY "Allow certificate viewing" ON storage.objects
FOR SELECT USING (bucket_id = 'coach_certificates');

-- 4. ایجاد policy برای حذف
CREATE POLICY "Allow certificate deletion" ON storage.objects
FOR DELETE USING (
  bucket_id = 'coach_certificates' AND
  auth.uid() IS NOT NULL
);

-- 5. بررسی policies ایجاد شده
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' AND policyname LIKE '%certificate%';
