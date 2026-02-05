-- افزودن ستون active_meal_plan_id به جدول profiles
-- این فایل باید در Supabase SQL Editor اجرا شود

-- افزودن ستون active_meal_plan_id
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS active_meal_plan_id UUID REFERENCES public.meal_plans(id) ON DELETE SET NULL;

-- ایجاد ایندکس برای بهبود عملکرد جستجو
CREATE INDEX IF NOT EXISTS idx_profiles_active_meal_plan_id ON public.profiles(active_meal_plan_id);

