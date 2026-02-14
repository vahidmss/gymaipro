-- اضافه کردن فیلد trainer_score به جدول profiles برای ذخیره امتیاز رنکینگ مربیان
-- این فیلد امتیاز محاسبه شده از _calculateTrainerScore را ذخیره می‌کند

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS trainer_score DECIMAL(10,4) DEFAULT 0.0;

-- ایندکس برای بهبود عملکرد جستجو و مرتب‌سازی مربیان بر اساس امتیاز
CREATE INDEX IF NOT EXISTS idx_profiles_trainer_score 
  ON public.profiles(trainer_score DESC) 
  WHERE role = 'trainer';

-- کامنت برای مستندسازی
COMMENT ON COLUMN public.profiles.trainer_score IS 
  'امتیاز رنکینگ مربی که از عوامل مختلف محاسبه می‌شود: امتیاز و نظرات، شاگردان فعال، تجربه، تمرینات، موزیک‌ها، رضایت و فعالیت';
