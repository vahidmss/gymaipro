-- راه‌حل موقت: غیرفعال کردن RLS برای تست
-- ⚠️ فقط برای تست استفاده کنید، در production فعال نکنید

-- 1. بررسی وضعیت RLS
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- 2. غیرفعال کردن RLS (فقط برای تست)
-- ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- 3. یا ایجاد Policy ساده‌تر
DROP POLICY IF EXISTS "Trainers can upload certificates" ON storage.objects;

CREATE POLICY "Simple upload policy" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'coach_certificates' AND
  auth.uid() IS NOT NULL
);

-- 4. Policy برای مشاهده
DROP POLICY IF EXISTS "Public can view certificates" ON storage.objects;

CREATE POLICY "Simple view policy" ON storage.objects
FOR SELECT USING (bucket_id = 'coach_certificates');
