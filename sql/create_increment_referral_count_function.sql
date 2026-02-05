-- ایجاد تابع برای افزایش تعداد referrals
-- این تابع برای به‌روزرسانی خودکار تعداد دعوت‌ها استفاده می‌شود

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

-- کامنت برای مستندسازی
COMMENT ON FUNCTION increment_referral_count IS 'افزایش تعداد referrals کاربر';

