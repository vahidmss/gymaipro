-- اضافه کردن ستون description به جدول certificates
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. بررسی ساختار فعلی جدول
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'certificates' 
ORDER BY ordinal_position;

-- 2. اضافه کردن ستون description
ALTER TABLE public.certificates 
ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';

-- 3. بررسی ساختار جدید
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'certificates' 
ORDER BY ordinal_position;
