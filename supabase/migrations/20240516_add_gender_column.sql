-- اضافه کردن ستون gender به جدول profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT 'male';
 
-- بروزرسانی permissions
GRANT SELECT, UPDATE(gender) ON public.profiles TO authenticated;
GRANT SELECT, UPDATE(gender) ON public.profiles TO service_role; 