-- اضافه کردن فیلدهای referral به جدول profiles
-- برای مدیریت سیستم دعوت و کد معرف

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS referrer_username VARCHAR(50),
ADD COLUMN IF NOT EXISTS referred_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS total_referrals INTEGER DEFAULT 0;

-- کامنت برای مستندسازی
COMMENT ON COLUMN public.profiles.referrer_username IS 'نام کاربری شخصی که این کاربر را دعوت کرده است';
COMMENT ON COLUMN public.profiles.referred_at IS 'تاریخ ثبت کد معرف';
COMMENT ON COLUMN public.profiles.total_referrals IS 'تعداد کل افرادی که این کاربر دعوت کرده است';

-- ایندکس برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_profiles_referrer_username ON public.profiles(referrer_username);
CREATE INDEX IF NOT EXISTS idx_profiles_referred_at ON public.profiles(referred_at DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_total_referrals ON public.profiles(total_referrals DESC);

-- Foreign key constraint (اختیاری - برای اطمینان از وجود referrer)
-- این constraint را می‌توانید فعال کنید اگر می‌خواهید referrer حتماً وجود داشته باشد
-- ALTER TABLE public.profiles
-- ADD CONSTRAINT fk_referrer_username 
-- FOREIGN KEY (referrer_username) REFERENCES public.profiles(username);

