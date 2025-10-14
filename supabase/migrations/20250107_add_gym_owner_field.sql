-- اضافه کردن فیلد is_gym_owner به جدول profiles
-- این migration فیلد جدید is_gym_owner را به جدول profiles اضافه می‌کند

-- اضافه کردن ستون is_gym_owner به جدول profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS is_gym_owner BOOLEAN DEFAULT false;

-- اضافه کردن comment برای توضیح فیلد
COMMENT ON COLUMN public.profiles.is_gym_owner IS 'نشان می‌دهد که آیا مربی مالک باشگاه است یا خیر';

-- ایجاد ایندکس برای بهبود عملکرد جستجو
CREATE INDEX IF NOT EXISTS idx_profiles_is_gym_owner ON public.profiles(is_gym_owner) WHERE is_gym_owner = true;
