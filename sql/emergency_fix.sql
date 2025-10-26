-- راه‌حل اضطراری: غیرفعال کردن RLS
-- ⚠️ فقط برای تست استفاده کنید

-- 1. غیرفعال کردن RLS موقت
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- 2. یا ایجاد policy بسیار ساده
DROP POLICY IF EXISTS "Allow certificate uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow certificate viewing" ON storage.objects;
DROP POLICY IF EXISTS "Allow certificate deletion" ON storage.objects;

CREATE POLICY "Simple upload" ON storage.objects
FOR ALL USING (bucket_id = 'coach_certificates');

-- 3. بررسی
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'objects' AND schemaname = 'storage';
