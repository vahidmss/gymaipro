-- اجرای این فایل در Supabase: SQL Editor → New query → Paste → Run
-- رفع خطا: column profiles.referrer_username does not exist

-- ۱. اضافه کردن ستون‌های referral به جدول profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS referrer_username VARCHAR(50),
  ADD COLUMN IF NOT EXISTS referred_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS total_referrals INTEGER DEFAULT 0;

COMMENT ON COLUMN public.profiles.referrer_username IS 'نام کاربری شخصی که این کاربر را دعوت کرده است';
COMMENT ON COLUMN public.profiles.referred_at IS 'تاریخ ثبت کد معرف';
COMMENT ON COLUMN public.profiles.total_referrals IS 'تعداد کل افرادی که این کاربر دعوت کرده است';

CREATE INDEX IF NOT EXISTS idx_profiles_referrer_username ON public.profiles(referrer_username);
CREATE INDEX IF NOT EXISTS idx_profiles_referred_at ON public.profiles(referred_at DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_total_referrals ON public.profiles(total_referrals DESC);

-- ۲. تابع افزایش تعداد referrals (برای امتیاز معرف)
CREATE OR REPLACE FUNCTION increment_referral_count(user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.profiles
  SET total_referrals = COALESCE(total_referrals, 0) + 1
  WHERE id = user_id;
END;
$$;

COMMENT ON FUNCTION increment_referral_count IS 'افزایش تعداد referrals کاربر';
