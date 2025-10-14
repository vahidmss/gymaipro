-- رفع مشکل ستون specializations در جدول profiles
-- این فایل باید در Supabase اجرا شود

-- اضافه کردن ستون specializations اگر وجود ندارد
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS specializations TEXT;

-- اگر ستون specialization وجود دارد، آن را به specializations تغییر نام دهید
DO $$
BEGIN
    -- بررسی وجود ستون specialization
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'specialization'
        AND table_schema = 'public'
    ) THEN
        -- تغییر نام ستون از specialization به specializations
        ALTER TABLE public.profiles 
        RENAME COLUMN specialization TO specializations;
        
        RAISE NOTICE 'ستون specialization به specializations تغییر نام یافت';
    ELSE
        RAISE NOTICE 'ستون specialization وجود ندارد، specializations اضافه شد';
    END IF;
END $$;

-- ایجاد ایندکس برای specializations
CREATE INDEX IF NOT EXISTS idx_profiles_specializations 
ON public.profiles(specializations) 
WHERE role = 'trainer';

-- اضافه کردن کامنت برای مستندسازی
COMMENT ON COLUMN public.profiles.specializations IS 'تخصص‌های مربی (متن آزاد)';
