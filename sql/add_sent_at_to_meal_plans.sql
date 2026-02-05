-- افزودن ستون sent_at به جدول meal_plans
-- این فایل باید در Supabase SQL Editor اجرا شود

-- افزودن ستون sent_at (تاریخ ارسال برنامه به شاگرد)
ALTER TABLE public.meal_plans
ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ;

-- ایجاد ایندکس برای بهبود عملکرد جستجو
CREATE INDEX IF NOT EXISTS idx_meal_plans_sent_at ON public.meal_plans(sent_at);

-- توضیح: 
-- - اگر sent_at NULL باشد، برنامه هنوز برای شاگرد ارسال نشده و قابل نمایش نیست
-- - اگر sent_at مقدار داشته باشد، برنامه برای شاگرد قابل نمایش است
-- - editable_until از تاریخ sent_at محاسبه می‌شود (3 روز از sent_at)

