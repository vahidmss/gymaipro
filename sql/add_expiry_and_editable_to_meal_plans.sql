-- افزودن ستون‌های expiry_date و editable_until به جدول meal_plans
-- این فایل باید در Supabase SQL Editor اجرا شود

-- افزودن ستون expiry_date (33 روز از تاریخ ساخت)
ALTER TABLE public.meal_plans
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMPTZ;

-- افزودن ستون editable_until (3 روز از تاریخ ساخت - تا این تاریخ مربی می‌تواند ادیت کند)
ALTER TABLE public.meal_plans
ADD COLUMN IF NOT EXISTS editable_until TIMESTAMPTZ;

-- ایجاد ایندکس برای بهبود عملکرد جستجو
CREATE INDEX IF NOT EXISTS idx_meal_plans_expiry_date ON public.meal_plans(expiry_date);
CREATE INDEX IF NOT EXISTS idx_meal_plans_editable_until ON public.meal_plans(editable_until);

