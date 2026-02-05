-- افزودن تمام ستون‌های مورد نیاز به جدول meal_plans
-- این فایل باید در Supabase SQL Editor اجرا شود

-- 1. افزودن ستون expiry_date (33 روز از تاریخ ساخت)
ALTER TABLE public.meal_plans
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMPTZ;

-- 2. افزودن ستون editable_until (3 روز از تاریخ ارسال - تا این تاریخ مربی می‌تواند ادیت کند)
ALTER TABLE public.meal_plans
ADD COLUMN IF NOT EXISTS editable_until TIMESTAMPTZ;

-- 3. افزودن ستون sent_at (تاریخ ارسال برنامه به شاگرد)
ALTER TABLE public.meal_plans
ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ;

-- ایجاد ایندکس‌ها برای بهبود عملکرد جستجو
CREATE INDEX IF NOT EXISTS idx_meal_plans_expiry_date ON public.meal_plans(expiry_date);
CREATE INDEX IF NOT EXISTS idx_meal_plans_editable_until ON public.meal_plans(editable_until);
CREATE INDEX IF NOT EXISTS idx_meal_plans_sent_at ON public.meal_plans(sent_at);

-- توضیح: 
-- - expiry_date: تاریخ انقضای برنامه (33 روز از تاریخ ساخت)
-- - editable_until: تا این تاریخ مربی می‌تواند برنامه را ویرایش کند (3 روز از sent_at)
-- - sent_at: تاریخ ارسال برنامه به شاگرد (NULL = هنوز ارسال نشده)

