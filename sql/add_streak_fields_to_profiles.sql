-- اضافه کردن فیلدهای streak به جدول profiles
-- برای مدیریت روزهای پشت سر هم استفاده از اپ

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS login_streak INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_login_date DATE,
ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0;

-- کامنت برای مستندسازی
COMMENT ON COLUMN public.profiles.login_streak IS 'تعداد روزهای متوالی استفاده از اپ';
COMMENT ON COLUMN public.profiles.last_login_date IS 'آخرین تاریخ ورود کاربر';
COMMENT ON COLUMN public.profiles.longest_streak IS 'بیشترین تعداد روزهای متوالی که کاربر داشته است';

-- ایندکس برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_profiles_login_streak ON public.profiles(login_streak DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_last_login_date ON public.profiles(last_login_date DESC);

