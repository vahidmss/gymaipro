-- Migration: افزودن فیلد activity_level به جدول profiles
-- این migration برای جدول‌های موجود استفاده می‌شود
-- تاریخ: برای جدول‌های موجود

-- بررسی وجود فیلد قبل از اضافه کردن
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'activity_level'
    ) THEN
        -- افزودن فیلد activity_level
        ALTER TABLE public.profiles 
        ADD COLUMN activity_level VARCHAR(20) 
        CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active'));
        
        RAISE NOTICE 'فیلد activity_level با موفقیت اضافه شد';
    ELSE
        RAISE NOTICE 'فیلد activity_level از قبل وجود دارد';
    END IF;
END $$;

-- افزودن ایندکس برای بهبود عملکرد (اختیاری)
CREATE INDEX IF NOT EXISTS idx_profiles_activity_level 
ON public.profiles(activity_level) 
TABLESPACE pg_default;

