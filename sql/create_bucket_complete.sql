-- ایجاد کامل bucket coach_certificates و تنظیمات آن
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. ایجاد bucket (اگر وجود ندارد)
INSERT INTO storage.buckets (id, name, public, created_at, updated_at)
VALUES (
  'coach_certificates',
  'coach_certificates', 
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO NOTHING;

-- 2. بررسی bucket ایجاد شده
SELECT name, public, created_at, updated_at 
FROM storage.buckets 
WHERE name = 'coach_certificates';

-- 3. حذف policies قدیمی (اگر وجود دارند)
DROP POLICY IF EXISTS "Allow certificate uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow certificate viewing" ON storage.objects;
DROP POLICY IF EXISTS "Allow certificate deletion" ON storage.objects;
DROP POLICY IF EXISTS "Trainers can upload certificates" ON storage.objects;
DROP POLICY IF EXISTS "Public can view certificates" ON storage.objects;
DROP POLICY IF EXISTS "Trainers can delete their certificates" ON storage.objects;

-- 4. ایجاد policies جدید
CREATE POLICY "Allow certificate uploads" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'coach_certificates' AND
  auth.uid() IS NOT NULL
);

CREATE POLICY "Allow certificate viewing" ON storage.objects
FOR SELECT USING (bucket_id = 'coach_certificates');

CREATE POLICY "Allow certificate deletion" ON storage.objects
FOR DELETE USING (
  bucket_id = 'coach_certificates' AND
  auth.uid() IS NOT NULL
);

-- 5. بررسی policies ایجاد شده
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage' 
AND policyname LIKE '%certificate%';

-- 6. تست دسترسی
SELECT 
  auth.uid() as current_user_id,
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'trainer'
  ) as is_trainer;
