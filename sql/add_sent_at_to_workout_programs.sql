-- افزودن ستون sent_at به جدول workout_programs
-- این فایل باید در Supabase SQL Editor اجرا شود

-- افزودن ستون sent_at (تاریخ ارسال برنامه به شاگرد)
ALTER TABLE public.workout_programs
ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ;

-- ایجاد ایندکس برای بهبود عملکرد جستجو
CREATE INDEX IF NOT EXISTS idx_workout_programs_sent_at ON public.workout_programs(sent_at);

-- توضیح: 
-- - اگر sent_at NULL باشد، برنامه هنوز برای شاگرد ارسال نشده و قابل نمایش نیست
-- - اگر sent_at مقدار داشته باشد، برنامه برای شاگرد قابل نمایش است
-- - editable_until از تاریخ sent_at محاسبه می‌شود (3 روز از sent_at)

