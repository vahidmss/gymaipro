-- اضافه کردن ستون description به جدول certificates
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. بررسی ساختار فعلی جدول
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'certificates' 
ORDER BY ordinal_position;

-- 2. اضافه کردن ستون description (اگر وجود ندارد)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'certificates' 
        AND column_name = 'description'
    ) THEN
        ALTER TABLE public.certificates 
        ADD COLUMN description TEXT DEFAULT '';
    END IF;
END $$;

-- 3. بررسی ساختار جدید
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'certificates' 
ORDER BY ordinal_position;

-- 4. تست insert
-- INSERT INTO certificates (trainer_id, title, type, status, description, created_at, updated_at)
-- VALUES (
--   '8f99d6ce-e2cb-4c9d-948d-787d340fb95c',
--   'تست مدرک',
--   'coaching',
--   'pending',
--   'تست',
--   NOW(),
--   NOW()
-- );
